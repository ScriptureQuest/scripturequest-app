// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:level_up_your_faith/services/quest_service.dart';
import 'package:level_up_your_faith/services/continuity/continuity_reader.dart';
import 'package:level_up_your_faith/services/continuity/next_action.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:level_up_your_faith/data/activities/activity_catalog.dart';
import 'package:level_up_your_faith/services/activities/puzzle_engine.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/services/storage_service.dart';
import 'package:level_up_your_faith/services/activities/activity_history.dart';
import 'package:level_up_your_faith/models/connected/destination.dart';

class ActivityFailingStore extends InMemorySharedPreferencesStore {
  ActivityFailingStore(Map<String, Object> data) : super.withData(data);
  String? failKey;
  @override
  Future<bool> setValue(String type, String key, Object value) {
    if (key == failKey) return Future.value(false);
    return super.setValue(type, key, value);
  }
}

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
  test('catalog stable, linked, and every clue answer occurs in bundled verse',
      () async {
    expect(ActivityCatalog.validate(), isEmpty);
    expect(ActivityCatalog.puzzles.length, 6);
    for (final a in ActivityCatalog.puzzles) {
      expect(ConnectedDestination(a.route).owner, ProductTab.learn);
      for (final w in a.words) {
        final text =
            await app.loadMemoryVerse('${a.passage!.chapterKey}:${w.verse}');
        expect(RegExp('\\b${w.answer}\\b', caseSensitive: false).hasMatch(text),
            isTrue,
            reason: '${a.id} ${w.answer}');
      }
    }
  });
  test(
      'word search placements, reverse selection and invalid diagonals across seeds',
      () {
    for (final a in ActivityCatalog.puzzles)
      for (var seed = 0; seed < 30; seed++)
        for (final challenge in [false, true]) {
          final p = WordSearchPuzzle(a.words, seed: seed, challenge: challenge);
          for (final path in p.paths.entries) {
            expect(p.match(path.value.first, path.value.last), path.key);
            expect(p.match(path.value.last, path.value.first), path.key);
          }
          expect(p.match(const GridCell(0, 0), const GridCell(2, 1)), isNull);
          expect(p.match(const GridCell(-1, 0), const GridCell(2, 0)), isNull);
        }
  });
  test('crosswords have valid connected crossings and all five words', () {
    for (final words in [
      ActivityCatalog.shepherd,
      ActivityCatalog.word,
      ActivityCatalog.night
    ]) {
      final p = CrosswordPuzzle(words);
      expect(p.entries.length, 5);
      for (final e in p.entries) {
        expect(e.cells.map((c) => p.letters[c]).join(), e.word.answer);
        expect(
            p.entries.where(
                (other) => other != e && other.cells.any(e.cells.contains)),
            isNotEmpty);
      }
    }
  });
  test('incomplete puzzle cannot write history or rewards', () async {
    final before = app.currentUser!.totalXP;
    await expectLater(app.completeActivity(ActivityCatalog.puzzles.first.id),
        throwsArgumentError);
    expect(app.activityRecords, isEmpty);
    expect(app.currentUser!.totalXP, before);
  });
  test(
      'completion/replays/concurrent submits retain XP and best hints across restart',
      () async {
    final a = ActivityCatalog.puzzles.first,
        answers = {
          for (final w in ActivityCatalog.puzzles.first.words)
            w.answer: w.answer
        };
    await app.completeActivity(a.id, answers: answers, hints: 3);
    final earned = app.currentUser!.totalXP;
    final count = app.learningGamesCompleted;
    await Future.wait(List.generate(
        4, (_) => app.completeActivity(a.id, answers: answers, hints: 1)));
    expect(app.currentUser!.totalXP, earned);
    expect(app.learningGamesCompleted, count);
    expect((app.activityRecords[a.id] as Map)['bestHints'], 1);
    final restarted = AppProvider();
    await restarted.initialize();
    final replay =
        await restarted.completeActivity(a.id, answers: answers, hints: 0);
    expect(replay.xp, 0);
    expect((restarted.activityRecords[a.id] as Map)['bestHints'], 0);
    expect(restarted.discoveryRecords, isEmpty);
    restarted.dispose();
  });
  test('legacy activities reward once and preserve old learning count',
      () async {
    await storage.save('learning_games_completed_${app.currentUser!.id}', 7);
    await app.loadData();
    await app.completeActivity('book_order_v1');
    expect(app.learningGamesCompleted, 8);
    final xp = app.currentUser!.totalXP;
    await app.completeActivity('book_order_v1');
    expect(app.currentUser!.totalXP, xp);
    expect(app.learningGamesCompleted, 8);
  });
  test('pending delivery resumes safely and corrupt history is preserved',
      () async {
    final h = ActivityHistory(storage), uid = app.currentUser!.id;
    await h.record(uid, 'matching_v1', 0);
    await app.completeActivity('matching_v1');
    expect((app.activityRecords['matching_v1'] as Map)['pending'], false);
    final xp = app.currentUser!.totalXP;
    await app.completeActivity('matching_v1');
    expect(app.currentUser!.totalXP, xp);
    await storage.save(h.key(uid), 'broken');
    await expectLater(
        app.completeActivity('matching_v1'), throwsFormatException);
    expect(storage.getString(h.key(uid)), 'broken');
  });
  test(
      'puzzle advances learning quests once, never reading; guidance stays read-only',
      () async {
    final a = ActivityCatalog.puzzles.first;
    final readingBefore = (await TaskService(storage).getAllQuests())
        .where((q) => q.questType == 'reading')
        .map((q) => q.currentProgress)
        .toList();
    final r = await app.completeActivity(a.id,
        answers: {for (final w in a.words) w.answer: w.answer});
    expect(r.changes.any((c) => c.startsWith('Daily Quest:')), isTrue);
    expect(r.changes.any((c) => c.startsWith('Weekly Quest:')), isTrue);
    final quests = (await TaskService(storage).getAllQuests())
        .map((q) => q.currentProgress)
        .toList();
    expect(
        (await TaskService(storage).getAllQuests())
            .where((q) => q.questType == 'reading')
            .map((q) => q.currentProgress)
            .toList(),
        readingBefore);
    final before = app.currentUser!.totalXP;
    final snapshot = await ContinuityReader.read(app);
    final action = NextActionGuidance()
        .resolve(snapshot, passage: a.passage, learning: true);
    expect(action.destination.route, isNotEmpty);
    await app.completeActivity(a.id,
        answers: {for (final w in a.words) w.answer: w.answer});
    expect(app.currentUser!.totalXP, before);
    expect(
        (await TaskService(storage).getAllQuests())
            .map((q) => q.currentProgress)
            .toList(),
        quests);
    expect(app.discoveryRecords, isEmpty);
  });
  test('failed reward write leaves pending completion and retry pays only once',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final platform = ActivityFailingStore(
        {for (final k in prefs.getKeys()) 'flutter.$k': prefs.get(k)!});
    SharedPreferencesStorePlatform.instance = platform;
    final before = app.currentUser!.totalXP;
    platform.failKey = 'flutter.current_user';
    await expectLater(app.completeActivity('matching_v1'), throwsStateError);
    expect((app.activityRecords['matching_v1'] as Map)['pending'], true);
    platform.failKey = null;
    await app.completeActivity('matching_v1');
    expect(app.currentUser!.totalXP, greaterThan(before));
    final paid = app.currentUser!.totalXP;
    await app.completeActivity('matching_v1');
    expect(app.currentUser!.totalXP, paid);
  });
}
