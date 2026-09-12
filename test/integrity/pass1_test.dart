import 'dart:convert';
import 'dart:io';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:level_up_your_faith/models/journal_entry.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/services/achievement_service.dart';
import 'package:level_up_your_faith/services/verse_service.dart';
import 'package:level_up_your_faith/models/quest_model.dart';
import 'package:level_up_your_faith/services/storage_service.dart';
import 'package:level_up_your_faith/services/user_service.dart';
import 'package:level_up_your_faith/services/user_stats_service.dart';
import 'package:level_up_your_faith/services/journal_service.dart';
import 'package:level_up_your_faith/services/quest_service.dart';
import 'package:level_up_your_faith/services/quest_progress_service.dart';
import 'package:level_up_your_faith/services/reading_plan_service.dart';
import 'package:level_up_your_faith/services/progress/progress_engine.dart';
import 'package:level_up_your_faith/services/progress/progress_event.dart';
import 'package:level_up_your_faith/data/red_letter_spans.dart';
import 'package:level_up_your_faith/utils/bible_red_letter_helper.dart';

class FailingStore extends InMemorySharedPreferencesStore {
  FailingStore() : super.empty();
  String? failKey;
  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    if (key == failKey) return Future.value(false);
    return super.setValue(valueType, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StorageService storage;
  late UserService users;
  final backend = FailingStore();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = backend;
    storage = await StorageService.getInstance();
  });
  setUp(() async {
    backend.failKey = null;
    await storage.clear();
    users = UserService(storage);
    await users.getCurrentUser();
  });

  test(
      'large grant crosses every level; replay and concurrent receipts survive reload',
      () async {
    await Future.wait(
        List.generate(12, (_) => users.addXP(1000, receiptId: 'award')));
    final saved = await UserService(storage).getCurrentUser();
    expect(saved.totalXP, 1000);
    expect(saved.currentLevel, 5);
    expect(saved.currentXP, 0);
    await Future.wait(
        [users.addXP(20, receiptId: 'a'), users.addXP(30, receiptId: 'b')]);
    expect((await users.getCurrentUser()).totalXP, 1050);
    await users.updateUser(saved.copyWith(username: 'Updated'));
    expect((await users.getCurrentUser()).totalXP, 1050);
  });

  test('corrupt profile is preserved, not replaced with a new account',
      () async {
    await storage.save('current_user', '{broken');
    await expectLater(users.getCurrentUser(), throwsFormatException);
    expect(storage.getString('current_user'), '{broken');
  });

  JournalEntry entry(String id) => JournalEntry(
      id: id,
      userId: 'reader',
      reflectionText: 'Keep this reflection',
      createdAt: DateTime(2026, 1, 1));
  test(
      'journal edits preserve valid entries, malformed rows and unknown fields',
      () async {
    final original = jsonEncode([
      entry('a').toJson(),
      17,
      {...entry('b').toJson(), 'future': 'keep'}
    ]);
    await storage.save('journal_entries', original);
    final journal = JournalService(storage);
    expect((await journal.getEntriesForUser('reader')).length, 2);
    await journal.addEntry(entry('c'));
    expect(storage.getString('journal_entries_previous'), original);
    await journal.updateEntry(entry('b').copyWith(reflectionText: 'Edited'));
    await journal.deleteEntry('a');
    final rows = jsonDecode(storage.getString('journal_entries')!) as List;
    expect(rows, contains(17));
    expect(rows.whereType<Map>().firstWhere((e) => e['id'] == 'b')['future'],
        'keep');
    expect((await journal.getEntriesForUser('reader')).map((e) => e.id),
        ['b', 'c']);
  });
  test('unparseable journal blocks all writes and retains exact original bytes',
      () async {
    final journal = JournalService(storage);
    for (final raw in ['{truncated', '{}', 'null']) {
      await storage.save('journal_entries', raw);
      await expectLater(
          journal.getEntriesForUser('reader'), throwsFormatException);
      await expectLater(journal.addEntry(entry('a')), throwsFormatException);
      await expectLater(journal.updateEntry(entry('a')), throwsFormatException);
      await expectLater(journal.deleteEntry('a'), throwsFormatException);
      expect(storage.getString('journal_entries'), raw);
    }
  });
  test('concurrent journal saves and repeated stable IDs do not lose entries',
      () async {
    final journal = JournalService(storage);
    await Future.wait([
      journal.addEntry(entry('a')),
      journal.addEntry(entry('b')),
      journal.addEntry(entry('a'))
    ]);
    expect((await journal.getEntriesForUser('reader')).length, 2);
  });

  test('chapter event replay awards 10 XP and increments once', () async {
    final e = ProgressEvent.chapterCompleted('John', 'John', 3);
    await Future.wait(
        List.generate(10, (_) => ProgressEngine.instance.emit(e)));
    final user = await users.getCurrentUser();
    expect(user.totalXP, 10);
    expect(
        (await UserStatsService(storage)
            .getAll(user.id))['totalChaptersCompleted'],
        1);
  });
  test(
      'five-task counters count distinct tasks, not events; counters are independent',
      () async {
    for (var i = 0; i < 4; i++) {
      await ProgressEngine.instance
          .emit(ProgressEvent.taskCompleted('night-$i', 'nightly'));
    }
    await ProgressEngine.instance
        .emit(ProgressEvent.taskCompleted('night-0', 'nightly'));
    final user = await users.getCurrentUser();
    var stats = await UserStatsService(storage).getAll(user.id);
    expect(stats['nightlyTasksCompleted'], 4);
    expect(stats['tasksCompleted'], 4);
    expect(user.totalXP, 20);
    expect(
        (await AchievementService(storage).getAchievementsForUser(user.id))
            .firstWhere((a) => a.id == 'night_scholar_5')
            .isUnlocked,
        isFalse);
    await ProgressEngine.instance
        .emit(ProgressEvent.taskCompleted('night-4', 'nightly'));
    stats = await UserStatsService(storage).getAll(user.id);
    expect(stats['nightlyTasksCompleted'], 5);
    expect(
        (await AchievementService(storage).getAchievementsForUser(user.id))
            .firstWhere((a) => a.id == 'night_scholar_5')
            .isUnlocked,
        isTrue);
    for (var i = 0; i < 5; i++) {
      await ProgressEngine.instance
          .emit(ProgressEvent.taskCompleted('reflection-$i', 'reflection'));
    }
    await ProgressEngine.instance
        .emit(ProgressEvent.taskCompleted('reflection-0', 'reflection'));
    expect(
        (await UserStatsService(storage)
            .getAll(user.id))['reflectionsCompleted'],
        5);
  });
  test('task chapter receipts survive reload and concurrent replay', () async {
    final now = DateTime.now();
    final task = TaskModel(
        id: 'read',
        title: 'Read',
        description: '',
        targetCount: 2,
        xpReward: 25,
        startDate: now,
        createdAt: now,
        updatedAt: now);
    await storage.save('quests', jsonEncode([task.toJson()]));
    await Future.wait(List.generate(
        8, (_) => TaskService(storage).creditChapter('read', 'john:3')));
    var saved = (await TaskService(storage).getAllQuests())
        .firstWhere((q) => q.id == 'read');
    expect(saved.currentProgress, 1);
    await TaskService(storage).creditChapter('read', 'john:4');
    saved = (await TaskService(storage).getAllQuests())
        .firstWhere((q) => q.id == 'read');
    expect(saved.isCompleted, isTrue);
    await TaskService(storage).startQuest('read');
    expect(
        (await TaskService(storage).getAllQuests())
            .firstWhere((q) => q.id == 'read')
            .isCompleted,
        isTrue);
  });
  test('book target never confuses John with 1 John', () {
    expect(
        QuestProgressService.matchesQuestTarget(
            completedBook: '1 John',
            completedChapter: 3,
            questScriptureReference: 'John 3',
            questTitle: ''),
        isFalse);
    expect(
        QuestProgressService.matchesQuestTarget(
            completedBook: 'John',
            completedChapter: 3,
            questScriptureReference: 'John 3',
            questTitle: ''),
        isTrue);
  });
  test(
      'NT90 covers all 260 chapters in 90 nonempty days; old step indices retain old references',
      () {
    final plan = ReadingPlanService.getById('plan_nt_90_v2')!;
    final old = ReadingPlanService.getById('plan_nt_90')!;
    expect(plan.days.length, 90);
    expect(old.days.length, 87);
    final chapters = plan.days.expand((e) => e.referenceList).toList();
    expect(chapters.length, 260);
    expect(chapters.toSet().length, 260);
    expect(chapters, old.days.expand((e) => e.referenceList).toList());
    expect(plan.days.every((e) => e.referenceList.isNotEmpty), isTrue);
    expect(old.days[86].referenceList, ['Revelation 21', 'Revelation 22']);
  });

  test(
      'qualified chapter credit rejects early and wrong-book reads, then counts once',
      () async {
    final now = DateTime.now();
    final task = TaskModel(
        id: 'target',
        title: 'John reading',
        description: 'Read John',
        targetBook: 'John',
        targetCount: 2,
        xpReward: 25,
        startDate: now,
        createdAt: now,
        updatedAt: now);
    await storage.save('quests', jsonEncode([task.toJson()]));
    final tasks = TaskService(storage);
    final progress = QuestProgressService(
        questService: tasks, verseService: VerseService(storage));
    Future<void> emit(String book, bool qualified) async {
      await progress.handleEvent(
          event: 'onChapterComplete',
          payload: {
            'book': book,
            'chapter': 3,
            'hasMetReadingThreshold': qualified
          },
          onApplyProgress: tasks.updateQuestProgress,
          onMarkComplete: tasks.completeQuest);
    }

    await emit('John', false);
    await emit('1 John', true);
    expect(
        (await tasks.getAllQuests())
            .firstWhere((q) => q.id == 'target')
            .currentProgress,
        0);
    await emit('John', true);
    await emit('John', true);
    expect(
        (await tasks.getAllQuests())
            .firstWhere((q) => q.id == 'target')
            .currentProgress,
        1);
  });

  test(
      'production provider completion then repeated/concurrent claims pays once',
      () async {
    final app = AppProvider();
    await app.initialize();
    final now = DateTime.now();
    final task = TaskModel(
        id: 'claim-test',
        title: 'Test task',
        description: 'Test',
        isAutoTracked: false,
        questType: 'service',
        targetCount: 1,
        xpReward: 25,
        startDate: now,
        createdAt: now,
        updatedAt: now);
    await TaskService(storage).addQuest(task);
    await app.completeQuest(task.id, claimRewards: false);
    final before = await users.getCurrentUser();
    await Future.wait(List.generate(8, (_) => app.claimQuestRewards(task.id)));
    final after = await users.getCurrentUser();
    expect(after.totalXP - before.totalXP, 25);
    await app.completeQuest(task.id);
    expect((await users.getCurrentUser()).totalXP, after.totalXP);
    expect(
        (await TaskService(storage).getAllQuests())
            .firstWhere((q) => q.id == task.id)
            .isClaimed,
        isTrue);
    app.dispose();
  });

  test(
      'production reader early completion can later qualify without paying chapter XP twice',
      () async {
    final app = AppProvider();
    await app.initialize();
    expect(
        await app.completeReaderChapter('John', 3, qualified: false), isTrue);
    expect(app.currentBibleStreak, 0);
    expect(app.activeQuests.firstWhere((q) => q.type == 'weekly').progress, 0);
    expect(
        await app.completeReaderChapter('John', 3, qualified: true), isFalse);
    expect(app.currentBibleStreak, 1);
    expect(app.activeQuests.firstWhere((q) => q.type == 'weekly').progress, 1);
    final total = (await users.getCurrentUser()).totalXP;
    await app.completeReaderChapter('John', 3, qualified: true);
    expect((await users.getCurrentUser()).totalXP, total);
    expect(app.activeQuests.firstWhere((q) => q.type == 'weekly').progress, 1);
    expect(
        (await UserStatsService(storage)
            .getAll(app.currentUser!.id))['totalChaptersCompleted'],
        1);
    app.dispose();
  });

  test('failed profile write cannot cache a paid receipt; retry pays exactly once', () async {
    backend.failKey = 'flutter.current_user';
    await expectLater(users.addXP(25, receiptId:'failed'), throwsStateError);
    expect((await users.getCurrentUser()).totalXP, 0);
    backend.failKey = null;
    await users.addXP(25, receiptId:'failed');
    await users.addXP(25, receiptId:'failed');
    expect((await users.getCurrentUser()).totalXP, 25);
  });
  test('chapter retry after stats write failure repairs count without duplicating XP', () async {
    final uid = (await users.getCurrentUser()).id;
    backend.failKey = 'flutter.user_stats_$uid';
    final event = ProgressEvent.chapterCompleted('John','John',3);
    await expectLater(ProgressEngine.instance.emit(event), throwsStateError);
    expect((await users.getCurrentUser()).totalXP,10);
    backend.failKey = null;
    await ProgressEngine.instance.emit(event);
    expect((await users.getCurrentUser()).totalXP,10);
    expect((await UserStatsService(storage).getAll(uid))['totalChaptersCompleted'],1);
  });
  test('failed journal save keeps original entries and reports failure', () async {
    final journal = JournalService(storage);
    await journal.addEntry(entry('original'));
    final raw = storage.getString('journal_entries');
    backend.failKey = 'flutter.journal_entries';
    await expectLater(journal.addEntry(entry('new')), throwsStateError);
    expect(storage.getString('journal_entries'),raw);
    backend.failKey = null;
    await journal.addEntry(entry('new'));
    expect((await journal.getEntriesForUser('reader')).length,2);
  });

  final bible =
      jsonDecode(File('assets/bible/kjv.json').readAsStringSync()) as Map;
  final verses = <String, String>{
    for (final b in bible['books'])
      for (final c in b['chapters'])
        for (final v in c['verses'])
          '${b['name']}:${c['chapter']}:${v['verse']}':
              (v['text'] as String).trim()
  };
  test(
      'every sourced speech span fits the exact original verse and preserves rendered text',
      () {
    expect(redLetterSpans.length, 2009);
    for (final item in redLetterSpans.entries) {
      final text = verses[item.key]!;
      expect(item.value.first, BibleRedLetterHelper.fingerprint(text),
          reason: item.key);
      final parts = item.key.split(':');
      var end = 0;
      for (var i = 1; i < item.value.length; i += 2) {
        expect(item.value[i], greaterThanOrEqualTo(end), reason: item.key);
        end = item.value[i + 1];
        expect(end, lessThanOrEqualTo(text.length), reason: item.key);
      }
      final span = BibleRedLetterHelper.render(
          bookName: parts[0],
          chapter: int.parse(parts[1]),
          verseNumber: int.parse(parts[2]),
          text: text,
          enabled: true,
          bodyStyle: const TextStyle(),
          speechStyle: const TextStyle(color: Color(0xffff0000)));
      expect(span.toPlainText(), text, reason: item.key);
    }
  });
  test(
      'narration and another speaker are not red; mixed verse styles only speech',
      () {
    List<(int, int)> ranges(String key) {
      final p = key.split(':');
      return BibleRedLetterHelper.ranges(
          bookName: p[0],
          chapter: int.parse(p[1]),
          verseNumber: int.parse(p[2]),
          text: verses[key]!);
    }

    for (final key in [
      'John:3:4',
      'John:11:35',
      'Matthew:7:28',
      'Matthew:7:29'
    ]) {
      expect(ranges(key), isEmpty, reason: key);
    }
    expect(ranges('John:3:3').first.$1, greaterThan(0));
    expect(ranges('John:16:1'), isNotEmpty);
    expect(
        BibleRedLetterHelper.ranges(
            bookName: 'John',
            chapter: 3,
            verseNumber: 3,
            text: 'Different translation'),
        isEmpty);
  });
}
