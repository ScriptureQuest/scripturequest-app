import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/services/storage_service.dart';
import 'package:level_up_your_faith/services/user_service.dart';
import 'package:level_up_your_faith/services/quest_service.dart';
import 'package:level_up_your_faith/services/questline_service.dart';
import 'package:level_up_your_faith/services/quest_progress_service.dart';
import 'package:level_up_your_faith/services/verse_service.dart';
import 'package:level_up_your_faith/widgets/connected/reading_result_sheet.dart';
import 'package:level_up_your_faith/providers/settings_provider.dart';
import 'package:level_up_your_faith/widgets/reading_v2/reading_design.dart';

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
      'one reading advances daily, weekly and Journey with a single replay-safe result',
      () async {
    await app.focusJourney('knowing_jesus');
    final before = app.currentUser!.totalXP;
    await app.completeReaderChapter('John', 1, qualified: true);
    final journey = (await app.journeyHistory())
        .firstWhere((v) => v.questline.id == 'knowing_jesus');
    expect(journey.progress.completedStepIds, ['k1']);
    expect(journey.currentStep!.id, 'k2');
    final result = app.lastReadingCompletion!;
    expect(result.changes.any((c) => c.startsWith('Daily Quest:')), isTrue);
    expect(result.changes.any((c) => c.startsWith('Weekly Quest:')), isTrue);
    expect(result.changes.any((c) => c.startsWith('Knowing Jesus:')), isTrue);
    expect(result.xp, app.currentUser!.totalXP - before);
    final xp = app.currentUser!.totalXP;
    await Future.wait(List.generate(
        4, (_) => app.completeReaderChapter('John', 1, qualified: true)));
    expect(app.currentUser!.totalXP, xp);
    expect(app.lastReadingCompletion!.changes, isEmpty);
    expect(app.lastReadingCompletion!.xp, 0);
  });

  test(
      'optional responses can be passed without XP; completed journey cannot be replayed or erased',
      () async {
    await app.focusJourney('knowing_jesus');
    await app.completeReaderChapter('John', 1, qualified: true);
    final xp = app.currentUser!.totalXP;
    await app.markQuestlineStepDone('knowing_jesus', 'k2',
        stepXp: 0, skipReflection: true);
    expect(app.currentUser!.totalXP, xp);
    await app.completeReaderChapter('John', 3, qualified: true);
    await app.markQuestlineStepDone('knowing_jesus', 'k4',
        stepXp: 0, skipReflection: true);
    final completed = (await app.journeyHistory())
        .firstWhere((v) => v.questline.id == 'knowing_jesus');
    expect(completed.progress.isCompleted, isTrue);
    expect(completed.progress.skippedStepIds, ['k2', 'k4']);
    final earned = app.currentUser!.totalXP;
    await Future.wait(List.generate(
        5, (_) => app.markQuestlineStepDone('knowing_jesus', 'k4')));
    await app.focusJourney('knowing_jesus');
    expect(app.currentUser!.totalXP, earned);
    final history = await app.journeyHistory();
    expect(history.where((v) => v.questline.id == 'knowing_jesus').length, 1);
    expect(
        history
            .firstWhere((v) => v.questline.id == 'knowing_jesus')
            .progress
            .dateCompleted,
        completed.progress.dateCompleted);
    expect((await UserService(storage).getCurrentUser()).totalXP, earned);
  });

  test(
      'Codex requires qualified Psalm 23 reading, persists without a Journey and does not unlock twice',
      () async {
    await app.completeReaderChapter('Psalms', 23, qualified: false);
    expect(app.shepherdDiscovery, isNull);
    await app.completeReaderChapter('Psalms', 23, qualified: true);
    expect(app.lastReadingCompletion!.discovered, isTrue);
    final record = app.shepherdDiscovery!;
    expect(record['reference'], 'Psalms 23');
    expect(record['source'], 'Reading Psalm 23 in the Bible');
    await app.completeReaderChapter('Psalms', 23, qualified: true);
    expect(app.lastReadingCompletion!.discovered, isFalse);
    expect(app.shepherdDiscovery, record);
    final reloaded = AppProvider();
    await reloaded.initialize();
    expect(reloaded.shepherdDiscovery, record);
    reloaded.dispose();
  });

  test('wrong or early reading does not bypass ordered journey steps',
      () async {
    await app.focusJourney('knowing_jesus');
    await app.completeReaderChapter('John', 3, qualified: true);
    await app.completeReaderChapter('John', 1, qualified: false);
    var v = (await app.journeyHistory())
        .firstWhere((v) => v.questline.id == 'knowing_jesus');
    expect(v.completedSteps, 0);
    await app.markQuestlineStepDone('knowing_jesus', 'k4',
        stepXp: 0, skipReflection: true);
    v = (await app.journeyHistory())
        .firstWhere((v) => v.questline.id == 'knowing_jesus');
    expect(v.completedSteps, 0);
  });

  test(
      'new reading slots retain XP and target on reload; quizzes cannot impersonate reading or reflection',
      () async {
    final tasks = TaskService(storage);
    final all = await tasks.getAllQuests();
    final daily = all.firstWhere((q) => q.title == 'Read your next chapter');
    final weekly =
        all.firstWhere((q) => q.title == 'Continue your Scripture exploration');
    expect(daily.questType, 'scripture_reading');
    expect(weekly.questType, 'scripture_reading');
    final progress = QuestProgressService(
        questService: tasks, verseService: VerseService(storage));
    await progress.handleEvent(
        event: 'onQuizCompleted',
        payload: {'book': 'John'},
        onApplyProgress: tasks.updateQuestProgress,
        onMarkComplete: tasks.completeQuest);
    final after = await tasks.getAllQuests();
    expect(after.firstWhere((q) => q.id == daily.id).currentProgress,
        daily.currentProgress);
    await tasks.createDailyQuests();
    await tasks.createWeeklyQuests();
    final reload = await tasks.getAllQuests();
    expect(
        reload.firstWhere((q) => q.id == weekly.id).xpReward, weekly.xpReward);
    expect(reload.firstWhere((q) => q.id == weekly.id).targetCount,
        weekly.targetCount);
  });

  test('malformed Journey history remains intact and blocks enrollment',
      () async {
    final key = 'questline_progress_${app.currentUser!.id}';
    final raw = jsonEncode([
      {'questlineId': 'known', 'dateStarted': 'broken'},
      12
    ]);
    await storage.save(key, raw);
    final service = QuestlineService(storage, TaskService(storage));
    await expectLater(
        service.enrollInQuestline(app.currentUser!.id, 'knowing_jesus'),
        throwsFormatException);
    expect(storage.getString(key), raw);
  });

  test('all curated passages finish their original journeys and survive reload',
      () async {
    await app.focusJourney('psalms_of_peace');
    for (final chapter in [4, 23, 46, 91, 121]) {
      await app.completeReaderChapter('Psalms', chapter, qualified: true);
    }
    await app.focusJourney('onboarding_getting_started');
    await app.completeReaderChapter('John', 3, qualified: true);
    await app.completeReaderChapter('Romans', 8, qualified: true);
    await app.markQuestlineStepDone('onboarding_getting_started', 's3',
        stepXp: 0, skipReflection: true);
    final history = await app.journeyHistory();
    expect(history.where((v) => v.progress.isCompleted).length, 2);
    final reloaded = AppProvider();
    await reloaded.initialize();
    expect(
        (await reloaded.journeyHistory())
            .where((v) => v.progress.isCompleted)
            .length,
        2);
    expect(reloaded.shepherdDiscovery, isNotNull);
    expect(reloaded.currentUser!.totalXP, app.currentUser!.totalXP);
    reloaded.dispose();
  });

  test(
      'a saved transition retries after interruption without repeating its step reward',
      () async {
    await app.focusJourney('knowing_jesus');
    final uid = app.currentUser!.id;
    final key = 'journey_pending_${uid}_knowing_jesus_k1';
    await storage.save(
        key, jsonEncode({'stepXp': 25, 'skipReflection': false}));
    // Simulate interruption after history and base step credit, before manual reward.
    await QuestlineService(storage, TaskService(storage))
        .markStepComplete(uid, 'knowing_jesus', 'k1');
    final before = (await UserService(storage).getCurrentUser()).totalXP;
    await app.markQuestlineStepDone('knowing_jesus', 'k1');
    final after = app.currentUser!.totalXP;
    expect(after - before, 25);
    expect(storage.getString(key), '');
    await app.markQuestlineStepDone('knowing_jesus', 'k1');
    expect(app.currentUser!.totalXP, after);
  });

  testWidgets(
      'actual completion sheet fits narrow screens and large text, with reachable next step',
      (tester) async {
    await tester.runAsync(() async {
      await app.focusJourney('psalms_of_peace');
      await app.completeReaderChapter('Psalms', 23, qualified: true);
    });
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
            home: ChangeNotifierProvider(
                create: (_) => SettingsProvider(),
                child: ReadingDesign(
                    child: MediaQuery(
                        data: const MediaQueryData(
                            size: Size(320, 640),
                            textScaler: TextScaler.linear(1.8)),
                        child: Scaffold(
                            body: ReadingResultSheet(
                                result: app.lastReadingCompletion!))))))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('The Shepherd’s Care'), findsOneWidget);
    await tester.ensureVisible(find.text('Keep reading'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
