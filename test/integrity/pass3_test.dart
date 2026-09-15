import 'package:level_up_your_faith/services/progress/progress_engine.dart';
import 'package:level_up_your_faith/services/progress/progress_event.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/services/storage_service.dart';
import 'package:level_up_your_faith/services/exploration/exploration_service.dart';
import 'package:level_up_your_faith/data/exploration/catalog.dart';
import 'package:level_up_your_faith/services/user_service.dart';
import 'package:level_up_your_faith/services/quest_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StorageService storage;
  late AppProvider app;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await StorageService.getInstance();
  });
  setUp(() async {
    await storage.clear();
    app = AppProvider();
    await app.initialize();
  });
  tearDown(() => app.dispose());

  test(
      'authored evidence and memory text exist in bundled KJV; connection endpoints exist',
      () async {
    for (final d in discoveries) {
      final text =
          await app.loadMemoryVerse('${d.book}:${d.chapter}:${d.answerVerse}');
      expect(text.toLowerCase(), contains(d.evidence.toLowerCase()),
          reason: d.id);
      expect(await app.loadMemoryVerse(d.memoryKey), isNotEmpty);
    }
    expect(await app.loadMemoryVerse('John:3:9'),
        startsWith('Nicodemus answered'));
    for (final c in scriptureConnections) {
      for (final ref in [c.from, c.to]) {
        final m = RegExp(r'^(.*) (\d+):(\d+)(?:-(\d+))?$').firstMatch(ref)!;
        for (var v = int.parse(m[3]!); v <= int.parse(m[4] ?? m[3]!); v++) {
          expect(await app.loadMemoryVerse('${m[1]}:${m[2]}:$v'), isNotEmpty,
              reason: ref);
        }
      }
    }
    await expectLater(app.loadMemoryVerse('John:3:999'), throwsStateError);
  });
  test(
      'new discoveries require qualified reading, persist, and do not reward repeat reading',
      () async {
    await app.completeReaderChapter('John', 1, qualified: false);
    expect(app.discoveryRecords.containsKey('word'), isFalse);
    await app.completeReaderChapter('John', 1, qualified: true);
    expect(app.lastReadingCompletion!.discoveryIds, ['word']);
    final history = app.discoveryRecords;
    final xp = app.currentUser!.totalXP;
    await app.completeReaderChapter('John', 1, qualified: true);
    expect(app.lastReadingCompletion!.discoveryIds, isEmpty);
    expect(app.currentUser!.totalXP, xp);
    final fresh = AppProvider();
    await fresh.initialize();
    expect(fresh.discoveryRecords, history);
    fresh.dispose();
  });
  test(
      'finding correct evidence cross-progresses eligible quests once, with one XP grant',
      () async {
    final before = app.currentUser!.totalXP;
    final wrong = await app.recordPassageFinding('questions', 4);
    expect(wrong.correct, isFalse);
    expect(app.currentUser!.totalXP, before);
    expect((app.explorationState['learning'] as Map), isEmpty);
    final result = await app.recordPassageFinding('questions', 9);
    expect(result.correct, isTrue);
    expect(result.xp, greaterThanOrEqualTo(10));
    expect(result.changes.any((c) => c.startsWith('Daily Quest:')), isTrue);
    expect(result.changes.any((c) => c.startsWith('Weekly Quest:')), isTrue);
    final earned = app.currentUser!.totalXP;
    final progress = (await TaskService(storage).getAllQuests())
        .map((q) => q.currentProgress)
        .toList();
    final retries = await Future.wait(
        List.generate(4, (_) => app.recordPassageFinding('questions', 9)));
    expect(retries.every((r) => r.xp == 0 && r.changes.isEmpty), isTrue);
    expect(app.currentUser!.totalXP, earned);
    expect(
        (await TaskService(storage).getAllQuests())
            .map((q) => q.currentProgress)
            .toList(),
        progress);
    expect((app.explorationState['learning'] as Map).length, 1);
  });
  test(
      'practice, help and independent recall remain distinct; same session and same-day rewards are protected',
      () async {
    const key = 'John:3:16';
    await app.recordRecallEvidence(key, RecallOutcome.practiced, 'one');
    final first = app.currentUser!.totalXP;
    await app.recordRecallEvidence(key, RecallOutcome.helped, 'two');
    expect(app.currentUser!.totalXP, first);
    await app.recordRecallEvidence(key, RecallOutcome.independent, 'three');
    expect(app.currentUser!.totalXP, first + 10);
    await app.recordRecallEvidence(key, RecallOutcome.independent, 'four');
    await app.recordRecallEvidence(key, RecallOutcome.independent, 'one');
    expect(app.currentUser!.totalXP, first + 10);
    final sessions = app.explorationState['memory'][key]['sessions'] as Map;
    expect(sessions.length, 4);
    expect(sessions['one']['outcome'], 'practiced');
    expect(sessions['two']['outcome'], 'helped');
    expect(sessions['three']['outcome'], 'independent');
    final fresh = AppProvider();
    await fresh.initialize();
    expect(fresh.explorationState['memory'], app.explorationState['memory']);
    fresh.dispose();
    await expectLater(
        app.recordRecallEvidence(
            'John:3:999', RecallOutcome.independent, 'bad'),
        throwsStateError);
    expect(app.currentUser!.totalXP, first + 10);
  });
  test('corrupt exploration history is retained and blocks writes', () async {
    final key = 'exploration_v1_${app.currentUser!.id}';
    const damaged = '{"discoveries":';
    await storage.save(key, damaged);
    await expectLater(
        app.recordPassageFinding('shepherd', 4), throwsFormatException);
    expect(storage.getString(key), damaged);
    await expectLater(
        app.setIllustratedExploration(false), throwsFormatException);
    expect(storage.getString(key), damaged);
  });
  test('chapter quiz repeats cannot duplicate rewards or completion statistics',
      () async {
    final before = app.currentUser!.totalXP;
    final first =
        await app.completeConnectedQuiz('John', 3, true, 3, 3, 'quick');
    expect(first.xp, greaterThanOrEqualTo(10));
    expect(app.hasCompletedQuiz('John', 3), isTrue);
    final earned = app.currentUser!.totalXP;
    final retries = await Future.wait(List.generate(
        3, (_) => app.completeConnectedQuiz('John', 3, true, 6, 6, 'deep')));
    expect(retries.every((r) => r.xp == 0), isTrue);
    expect(app.currentUser!.totalXP, earned);
    expect(earned, greaterThan(before));
    final raw =
        jsonDecode(storage.getString('user_stats_${app.currentUser!.id}')!)
            as Map;
    expect(raw['totalQuizzesCompleted'], 1);
    expect(raw['totalQuizzesPassed'], 1);
  });
  test('existing completed quiz and legacy discovery are preserved', () async {
    await app.markQuizCompleted('John', 3, awardXp: false);
    final before = (await UserService(storage).getCurrentUser()).totalXP;
    await app.completeConnectedQuiz('John', 3, true, 5, 5, 'deep');
    final stats = storage.getString('user_stats_${app.currentUser!.id}');
    expect(
        stats == null ||
            !(jsonDecode(stats) as Map).containsKey('totalQuizzesCompleted'),
        isTrue);
    // Learning quest rewards may be new; the legacy chapter quiz stipend must not be reissued.
    expect(app.currentUser!.totalXP - before, isNot(20));
  });
  test('interrupted quiz completion resumes its saved result without a second payout', () async {
    final uid = app.currentUser!.id;
    await storage.save('connected_quiz_pending_${uid}_John:3', jsonEncode({'passed':true,'correct':3,'total':3,'difficulty':'quick'}));
    await ProgressEngine.instance.emit(ProgressEvent.chapterQuizCompleted(app.bibleService.displayToRef('John'),3,true,3,3,'quick'));
    final receipt = 'chapterQuiz:${app.bibleService.displayToRef('John')}:3';
    final before = (await UserService(storage).getCurrentUser()).rewardReceipts.where((r) => r == receipt).length;
    expect(before,1);
    await app.completeConnectedQuiz('John',3,true,6,6,'deep');
    expect(storage.getString('connected_quiz_pending_${uid}_John:3'),isNull);
    final user = await UserService(storage).getCurrentUser();
    expect(user.rewardReceipts.where((r)=>r==receipt).length,1);
    final stats = jsonDecode(storage.getString('user_stats_$uid')!) as Map;
    expect(stats['totalQuizzesCompleted'],1);
    expect(app.hasCompletedQuiz('John',3),isTrue);
  });
  test('verse aliases share memory and daily reward identity', () async {
    await app.recordRecallEvidence('Psalm:23:1',RecallOutcome.independent,'a');
    final xp = app.currentUser!.totalXP;
    await app.recordRecallEvidence('Psalms:023:01',RecallOutcome.independent,'b');
    expect(app.currentUser!.totalXP,xp);
    expect((app.explorationState['memory'] as Map).keys,['Psalms:23:1']);
    expect((app.explorationState['memory']['Psalms:23:1']['sessions'] as Map).length,2);
  });
  test('legacy Shepherd proof retains its earning context without announcing rediscovery', () async {
    final source = {'reference':'Psalms 23','source':'Earlier Psalm 23 exploration','discoveredAt':'2026-01-01T00:00:00.000'};
    await storage.save('codex_shepherd_${app.currentUser!.id}',jsonEncode(source));
    await app.completeReaderChapter('Psalms',23,qualified:true);
    expect(app.discoveryRecords['shepherd'],source);
    expect(app.lastReadingCompletion!.discoveryIds, isNot(contains('shepherd')));
    expect(app.lastReadingCompletion!.discovered,isFalse);
  });

}
