import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:level_up_your_faith/data/connected/connected_catalog.dart';
import 'package:level_up_your_faith/data/connected/journey_definitions.dart';
import 'package:level_up_your_faith/models/connected/destination.dart';
import 'package:level_up_your_faith/models/connected/passage_reference.dart';
import 'package:level_up_your_faith/models/questline.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/services/storage_service.dart';
import 'package:level_up_your_faith/services/continuity/continuity_reader.dart';
import 'package:level_up_your_faith/services/continuity/next_action.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final catalog = ConnectedCatalog.current;
  final guidance = NextActionGuidance();
  test(
      'existing catalog IDs, aliases and many-to-many relationships stay connected',
      () {
    expect(catalog.validate(), isEmpty);
    expect(catalog.journeyIds,
        {'onboarding_getting_started', 'knowing_jesus', 'psalms_of_peace'});
    expect(catalog.guides.map((d) => d.id),
        ['shepherd', 'word', 'questions', 'refuge']);
    expect(catalog.forJourney('knowing_jesus').map((d) => d.id),
        ['word', 'questions']);
    expect(catalog.forJourney('onboarding_getting_started').map((d) => d.id),
        ['questions']);
    expect(
        catalog.forPassage(PassageReference.tryParse('Psalm 23:1')!).single.id,
        'shepherd');
    for (final invalid in [
      'John 999',
      'John 0',
      'Unknown 3',
      'John 3:9-4',
      'John 3junk'
    ]) {
      expect(PassageReference.tryParse(invalid), isNull, reason: invalid);
    }
    expect(catalog.orientation('knowing_jesus', 's1'), isNull);
  });
  test(
      'invalid registration fails validation; fixture content needs no screen ID branch',
      () {
    expect(
        ConnectedCatalog(
                curated: [const JourneyPresentation('missing', 'night')])
            .validate(),
        isNotEmpty);
    expect(
        ConnectedCatalog(definitions: [
          ...journeyDefinitions(),
          journeyDefinitions().first
        ]).validate(),
        isNotEmpty);
    final extra = Questline(
        id: 'test_only',
        title: 'Test journey',
        description: 'Fixture only',
        category: 'test',
        steps: const [
          QuestlineStep(id: 'first', questId: 'tpl:read:John 3', order: 1)
        ]);
    final extended = ConnectedCatalog(definitions: [
      ...journeyDefinitions(),
      extra
    ], curated: [
      ...ConnectedCatalog.presentations,
      const JourneyPresentation('test_only', 'night')
    ]);
    expect(extended.validate(), isEmpty);
    expect(extended.forJourney('test_only').single.id, 'questions');
    final next = NextActionGuidance(extended)
        .resolve(ContinuitySnapshot(completedJourneys: catalog.journeyIds));
    expect(next.destination.route, '/journeys/test_only');
  });
  test('new, free and long-term guidance is deterministic and honest', () {
    const fresh = ContinuitySnapshot();
    expect(guidance.resolve(fresh).destination.route,
        '/journeys/onboarding_getting_started');
    for (var i = 0; i < 10; i++) {
      expect(guidance.resolve(fresh).title, guidance.resolve(fresh).title);
    }
    final free = ContinuitySnapshot(
        recentReading: PassageReference.tryParse('Genesis 1'));
    expect(guidance.resolve(free).destination.owner, ProductTab.bible);
    final read = ContinuitySnapshot(
        recentReading: PassageReference.tryParse('John 3'),
        discoveries: const {'questions'});
    expect(guidance.resolve(read).destination.route, '/find-passage/questions');
    final all = ContinuitySnapshot(completedJourneys: catalog.journeyIds);
    expect(guidance.resolve(all).destination.route, '/journey-board');
    expect(
        guidance
            .resolve(const ContinuitySnapshot(remembered: {'John:3:16'}),
                learning: true)
            .destination
            .route,
        '/remembered');
  });
  test('destination ownership is stable for query strings and nested routes',
      () {
    for (final route in [
      '/remembered',
      '/discoveries/questions',
      '/journey-board',
      '/journal'
    ]) {
      expect(ConnectedDestination.ownerOf(route), ProductTab.you);
    }
    expect(ConnectedDestination.ownerOf('/memorization-practice?key=John:3:16'),
        ProductTab.learn);
    expect(
        ConnectedDestination.ownerOf('/verses?ref=John%203'), ProductTab.bible);
    expect(ConnectedDestination.ownerOf('/journeys/knowing_jesus'),
        ProductTab.journeys);
  });
  group('existing persisted progression integration', () {
    late AppProvider app;
    late StorageService storage;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.getInstance();
      await storage.clear();
      app = AppProvider();
      await app.initialize();
    });
    tearDown(() => app.dispose());
    test(
        'active Journey agrees across Today, completion and Learn; optional response remains optional',
        () async {
      await app.focusJourney('knowing_jesus');
      var s = await ContinuityReader.read(app);
      expect(guidance.resolve(s).destination.route, '/journeys/knowing_jesus');
      await app.completeReaderChapter('John', 1, qualified: true);
      s = await ContinuityReader.read(app);
      expect(s.activeJourney!.currentStep!.id, 'k2');
      for (final learning in [false, true]) {
        final a = guidance.resolve(s,
            passage: PassageReference.tryParse('John 1'), learning: learning);
        expect(a.destination.route, '/journeys/knowing_jesus');
        expect(a.reason, contains('without writing'));
      }
    });
    test(
        'guidance leaves all persisted keys and rewards untouched across repeated reads and restart',
        () async {
      await app.focusJourney('psalms_of_peace');
      await app.completeReaderChapter('Psalms', 4, qualified: true);
      await storage.save('existing-private-data-sentinel',
          jsonEncode({'journal': 'private', 'highlight': 'Psalms:4:8'}));
      final prefs = await SharedPreferences.getInstance();
      Map<String, Object?> snapshot() =>
          {for (final k in prefs.getKeys()) k: prefs.get(k)};
      final before = snapshot();
      final xp = app.currentUser!.totalXP;
      for (var i = 0; i < 10; i++) {
        final s = await ContinuityReader.read(app);
        guidance.resolve(s);
        guidance.resolve(s, learning: true);
      }
      expect(snapshot(), before);
      expect(app.currentUser!.totalXP, xp);
      final fresh = AppProvider();
      await fresh.initialize();
      final resumed = await ContinuityReader.read(fresh);
      expect(resumed.activeJourney!.currentStep!.id, 'pp2');
      expect(guidance.resolve(resumed).destination.route,
          '/journeys/psalms_of_peace');
      fresh.dispose();
    });
    test(
        'finished Journey keeps history and points onward without reenrollment',
        () async {
      await app.focusJourney('onboarding_getting_started');
      await app.completeReaderChapter('John', 3, qualified: true);
      await app.completeReaderChapter('Romans', 8, qualified: true);
      await app.markQuestlineStepDone('onboarding_getting_started', 's3',
          stepXp: 0, skipReflection: true);
      final s = await ContinuityReader.read(app);
      expect(s.completedJourneys, contains('onboarding_getting_started'));
      final next =
          guidance.resolve(s, finishedJourney: 'onboarding_getting_started');
      expect(next.destination.route, '/journeys/knowing_jesus');
      expect(
          (await app.journeyHistory())
              .where((v) => v.questline.id == 'onboarding_getting_started')
              .single
              .progress
              .isCompleted,
          isTrue);
    });
    test(
        'reading plan has priority over free continuation without changing enrollment',
        () async {
      await app.activatePlan(app.availableReadingPlans.first.planId);
      final s = await ContinuityReader.read(app);
      expect(guidance.resolve(s).destination.route, '/reading-plans');
      expect(app.getPlanProgressPercent(), 0);
    });
    test(
        'unreadable exploration is surfaced rather than overwritten or treated as fresh',
        () async {
      final key = 'exploration_v1_${app.currentUser!.id}';
      await storage.save(key, '{broken');
      await expectLater(ContinuityReader.read(app), throwsA(anything));
      expect(storage.getString(key), '{broken');
    });
  });
}
