import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/services/storage_service.dart';
import 'package:level_up_your_faith/services/continuity/continuity_reader.dart';
import 'package:level_up_your_faith/services/continuity/next_action.dart';
import 'package:level_up_your_faith/services/sessions/passage_learning.dart';
import 'package:level_up_your_faith/services/sessions/session_return.dart';
import 'package:level_up_your_faith/services/reading/reading_presence.dart';
import 'package:level_up_your_faith/models/connected/passage_reference.dart';
import 'package:level_up_your_faith/data/connected/connected_catalog.dart';
import 'package:level_up_your_faith/data/activities/activity_catalog.dart';

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
  final guidance = NextActionGuidance();
  test(
      'new user has one starting action; returning and midway Journey use real progress',
      () async {
    expect(
        guidance
            .resolve(await ContinuityReader.read(app),
                context: SessionContext.today)
            .destination
            .route,
        '/journeys/onboarding_getting_started');
    await app.focusJourney('knowing_jesus');
    await app.completeReaderChapter('John', 1, qualified: true);
    final s = await ContinuityReader.read(app);
    expect(s.activeJourney!.currentStep!.id, 'k2');
    final action = guidance.resolve(s, context: SessionContext.today);
    expect(action.title, contains('Knowing Jesus'));
    expect(action.reason, contains('without writing'));
  });
  test('unrelated self study stays Romans 8 despite a standing John Journey',
      () async {
    await app.focusJourney('knowing_jesus');
    final s = await ContinuityReader.read(app);
    for (final context in [
      SessionContext.freeReading,
      SessionContext.passageLearning
    ]) {
      final action = guidance.resolve(s,
          passage: const PassageReference('Romans', 8), context: context);
      expect(action.destination.route, '/chapter-quiz?book=Romans&chapter=8');
      expect(action.reason, contains('Romans 8'));
      expect(action.optionalReplay, isFalse);
    }
  });
  test('all five existing quizzes exposed without duplicate definitions', () {
    expect(app.currentActivityCapacity, 10);
    expect(ConnectedCatalog.chapterLearning.map((p) => p.label),
        ['John 3', 'Romans 8', 'Psalms 23', 'Proverbs 3', 'Luke 2']);
    for (final p in ConnectedCatalog.chapterLearning) {
      expect(
          PassageLearning.build(p)
              .opportunities
              .where((o) => o.title == 'Chapter learning')
              .length,
          1);
    }
    final view = PassageLearning.build(const PassageReference('Genesis', 1));
    expect(view.opportunities, isEmpty);
    expect(view.remembering, isEmpty);
    expect(view.caughtUp, isFalse);
  });
  test('completed and pending activities change contextual recommendations',
      () {
    const p = PassageReference('Psalms', 23);
    final all = {
      for (final a in ActivityCatalog.forPassage(p)) a.id: {'pending': false}
    };
    final s = ContinuitySnapshot(
        learned: {'shepherd'}, quizzes: {p.chapterKey}, activities: all);
    final action = guidance.resolve(s,
        passage: p, context: SessionContext.passageLearning);
    expect(action.optionalReplay, isTrue);
    expect(action.reason, contains('at your pace'));
    expect(action.destination.route, p.destination.route);
    final id = ActivityCatalog.forPassage(p).first.id;
    all[id] = {'pending': true};
    final pending = guidance.resolve(
        ContinuitySnapshot(
            learned: {'shepherd'}, quizzes: {p.chapterKey}, activities: all),
        passage: p,
        context: SessionContext.passageLearning);
    expect(pending.destination.route, ActivityCatalog.byId(id).route);
    expect(pending.optionalReplay, isFalse);
  });
  test('unsupported and exhausted collections make honest optional suggestions',
      () {
    final unsupported = guidance.resolve(const ContinuitySnapshot(),
        passage: const PassageReference('Genesis', 1),
        context: SessionContext.passageLearning);
    expect(unsupported.reason, contains('No authored challenges'));
    expect(unsupported.optionalReplay, isTrue);
    final done = guidance.resolve(
        ContinuitySnapshot(
            completedJourneys: ConnectedCatalog.current.journeyIds),
        context: SessionContext.today);
    expect(done.destination.route, '/journey-board');
  });
  test('Done for now persists independently; tomorrow returns to ongoing work',
      () async {
    await app.focusJourney('knowing_jesus');
    final before = app.currentUser!.totalXP;
    await SessionReturn.save(
        app.currentUser!.id, const PassageReference('Romans', 8));
    final s = await ContinuityReader.read(app);
    final today = guidance.resolve(s,
        context: SessionContext.today, now: s.returnPoint!.stoppedAt);
    expect(today.optionalReplay, isTrue);
    expect(today.reason, contains('session is saved'));
    final tomorrow = guidance.resolve(s,
        context: SessionContext.today,
        now: s.returnPoint!.stoppedAt.add(const Duration(days: 1)));
    expect(tomorrow.destination.route, '/journeys/knowing_jesus');
    expect(app.currentUser!.totalXP, before);
    final restarted = AppProvider();
    await restarted.initialize();
    expect((await ContinuityReader.read(restarted)).returnPoint!.reference,
        'Romans 8');
    restarted.dispose();
  });
  test('malformed return point is preserved and blocks overwrite', () async {
    final key = SessionReturn.key(app.currentUser!.id);
    await storage.save(key, 'broken');
    await expectLater(
        SessionReturn.save(
            app.currentUser!.id, const PassageReference('John', 3)),
        throwsFormatException);
    expect(storage.getString(key), 'broken');
  });
  test(
      'startup failure is recoverable, bytes preserved, concurrent retry shares attempt',
      () async {
    final profile = storage.getString('current_user')!;
    await storage.save('journal_sentinel', 'private journal bytes');
    await storage.save('current_user', 'broken');
    final retrying = AppProvider();
    await expectLater(retrying.initialize(), throwsFormatException);
    expect(retrying.isLoading, isFalse);
    expect(retrying.isInitialized, isFalse);
    expect(retrying.initializationError, isNotNull);
    expect(storage.getString('current_user'), 'broken');
    expect(storage.getString('journal_sentinel'), 'private journal bytes');
    // Restore the valid fixture externally, as if the temporary cause resolved.
    await storage.save('current_user', profile);
    final one = retrying.initialize(), two = retrying.initialize();
    expect(identical(one, two), isTrue);
    await Future.wait([one, two]);
    expect(retrying.isInitialized, isTrue);
    expect(retrying.initializationError, isNull);
    expect(retrying.currentUser!.id, app.currentUser!.id);
    expect(storage.getString('journal_sentinel'), 'private journal bytes');
    retrying.dispose();
  });
  test(
      'foreground route time pauses, resumes and resets only on chapter changes',
      () {
    var now = Duration.zero;
    final clock = ReadingPresence(now: () => now);
    clock.select('John:3');
    now += const Duration(seconds: 10);
    clock.setVisible(false);
    now += const Duration(seconds: 90);
    expect(clock.elapsed, const Duration(seconds: 10));
    clock.setForeground(false);
    clock.setVisible(true);
    now += const Duration(seconds: 90);
    expect(clock.elapsed, const Duration(seconds: 10));
    clock.setForeground(true);
    now += const Duration(seconds: 34);
    expect(clock.qualified, isFalse);
    now += const Duration(seconds: 1);
    expect(clock.qualified, isTrue);
    expect(clock.elapsedFor('John:4'), Duration.zero);
    clock.select('John:4');
    expect(clock.qualified, isFalse);
    expect(clock.elapsed, Duration.zero);
    clock.dispose();
    now += const Duration(seconds: 100);
    expect(clock.elapsed, Duration.zero);
  });
  test(
      'unqualified then qualified reading repairs Journey credit once and replay stays safe',
      () async {
    await app.focusJourney('knowing_jesus');
    await app.completeReaderChapter('John', 1, qualified: false);
    expect(app.lastReadingCompletion!.qualified, isFalse);
    expect(app.focusedJourney!.currentStep!.id, 'k1');
    await app.completeReaderChapter('John', 1, qualified: true);
    expect(app.focusedJourney!.currentStep!.id, 'k2');
    final paid = app.currentUser!.totalXP;
    await app.completeReaderChapter('John', 1, qualified: true);
    expect(app.currentUser!.totalXP, paid);
    expect(app.focusedJourney!.currentStep!.id, 'k2');
  });
  test(
      'interrupted activity delivery recovers through same receipt, repeated recovery is read-only',
      () async {
    final uid = app.currentUser!.id;
    await storage.save(
        'activities_v1_$uid',
        jsonEncode({
          'matching_v1': {
            'completedAt': DateTime.now().toIso8601String(),
            'bestHints': 0,
            'pending': true
          }
        }));
    await app.completeActivity('matching_v1');
    final paid = app.currentUser!.totalXP;
    await app.completeActivity('matching_v1');
    final snapshot = await ContinuityReader.read(app);
    expect(snapshot.activities['matching_v1']['pending'], false);
    expect(app.currentUser!.totalXP, paid);
  });
  test(
      'passage projection preserves labeled editorial connections and reads without writes',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
    final snapshot = await ContinuityReader.read(app);
    final view = PassageLearning.build(const PassageReference('John', 3),
        learned: snapshot.learned, activities: snapshot.activities);
    expect(view.connections, isNotEmpty);
    expect(view.journeys.length, greaterThan(1));
    expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
  });
}
