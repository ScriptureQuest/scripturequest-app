import 'package:level_up_your_faith/widgets/common/game_end_panel.dart';
import 'package:level_up_your_faith/screens/chapter_quiz_screen.dart';
import 'package:level_up_your_faith/screens/play_learn_hub_screen.dart';
import 'package:level_up_your_faith/widgets/sessions/session_ending.dart';
import 'package:level_up_your_faith/services/chapter_quiz_service.dart';
import 'package:level_up_your_faith/models/connected/passage_reference.dart';
import 'package:level_up_your_faith/services/activities/activity_history.dart';
import 'package:level_up_your_faith/screens/quest_hub_screen.dart';
import 'package:level_up_your_faith/widgets/connected/reading_result_sheet.dart';
import 'package:level_up_your_faith/widgets/sessions/passage_learning_panel.dart';
import 'package:level_up_your_faith/services/sessions/session_return.dart';
import 'package:level_up_your_faith/screens/activities/activity_screen.dart';
import 'package:level_up_your_faith/theme/scripture_theme.dart';
import 'package:level_up_your_faith/widgets/product/product_ui.dart';
import 'package:level_up_your_faith/screens/verses_screen.dart';
import 'package:level_up_your_faith/screens/connected/exploration_screen.dart';
import 'package:level_up_your_faith/screens/memorization_practice_screen.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import 'package:google_fonts/src/google_fonts_base.dart'
    as fonts; // ignore: implementation_imports
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:level_up_your_faith/screens/main_navigation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/providers/settings_provider.dart';
import 'package:level_up_your_faith/services/storage_service.dart';
import 'package:level_up_your_faith/screens/connected/journeys_screen.dart';
import 'package:level_up_your_faith/widgets/reading_v2/reading_design.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppProvider app;
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => Directory.systemTemp.path);
    fonts.httpClient = MockClient((request) async {
      final name = request.url.pathSegments.last;
      return http.Response.bytes(
          File('test/fixtures/fonts/$name').readAsBytesSync(), 200);
    });
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.getInstance();
    await storage.clear();

    app = AppProvider();
    await app.initialize();

    await storage.save('has_completed_onboarding_${app.currentUser!.id}', true);
    await app.loadData();
  });
  tearDown(() => app.dispose());
  final captureKey = GlobalKey();
  Future<void> mount(WidgetTester tester, Widget screen, Size size,
      {bool dark = false, double scale = 1, bool reduceMotion = false}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;

    await tester.runAsync(() async {
      await app.loadKjvPassage('John 1');
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      for (final weight in [
        FontWeight.w400,
        FontWeight.w500,
        FontWeight.w600,
        FontWeight.w700
      ]) {
        GoogleFonts.inter(fontWeight: weight);
        GoogleFonts.lora(fontWeight: weight);
      }

      await GoogleFonts.pendingFonts();
    });
    final router = GoRouter(initialLocation: '/under-test', routes: [
      ShellRoute(
          builder: (_, __, child) => MainNavigation(child: child),
          routes: [
            GoRoute(path: '/', builder: (_, __) => const QuestHubScreen()),
            GoRoute(path: '/under-test', builder: (_, __) => screen),
            GoRoute(
                path: '/chapter-quiz',
                builder: (_, state) => ChapterQuizScreen(
                    bookId: state.uri.queryParameters['book']!,
                    chapter: int.parse(state.uri.queryParameters['chapter']!))),
            GoRoute(
                path: '/play-learn/activity/:id',
                builder: (_, state) =>
                    ScriptureActivityScreen(id: state.pathParameters['id']!)),
            GoRoute(
                path: '/play-learn',
                builder: (_, __) => const PlayLearnHubScreen()),
            GoRoute(
                path: '/learn',
                builder: (_, state) =>
                    LearnScreen(reference: state.uri.queryParameters['ref'])),
            GoRoute(
                path: '/journeys/:id',
                builder: (_, state) =>
                    GuidedJourneyScreen(id: state.pathParameters['id']!)),
            GoRoute(
                path: '/journey-board',
                builder: (_, __) => const JourneysScreen(board: true)),
            GoRoute(
                path: '/discoveries', builder: (_, __) => const CodexScreen()),
            GoRoute(
                path: '/discoveries/:id',
                builder: (_, state) =>
                    CodexScreen(id: state.pathParameters['id'])),
            GoRoute(
                path: '/find-passage/:id',
                builder: (_, state) =>
                    FindPassageScreen(id: state.pathParameters['id']!)),
            GoRoute(
                path: '/memorization-practice',
                builder: (_, state) => MemorizationPracticeScreen(
                    verseKey: state.uri.queryParameters['key']!)),
            GoRoute(
                path: '/remembered',
                builder: (_, __) => const RememberedScreen()),
            GoRoute(
                path: '/verses',
                builder: (_, state) => VersesScreen(
                    selectedReference: state.uri.queryParameters['ref'])),
          ])
    ]);
    addTearDown(router.dispose);
    final settings = SettingsProvider();
    await tester.runAsync(() async {
      await settings.initialize();
      await settings.setQuestTheme(dark
          ? ScriptureThemes.scriptureDark
          : ScriptureThemes.scriptureLight);
    });
    addTearDown(settings.dispose);

    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: app),
          ChangeNotifierProvider.value(value: settings),
        ],
        child: RepaintBoundary(
            key: captureKey,
            child: MaterialApp.router(
                routerConfig: router,
                theme: dark ? ThemeData.dark() : ThemeData.light(),
                builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(scale),
                        disableAnimations: reduceMotion),
                    child:
                        ReadingDesign(child: ProductWidth(child: child!)))))));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });
    await tester.pump(const Duration(milliseconds: 400));
    await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(seconds: 3));
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (Platform.environment['SQ_CAPTURE'] != '1') return;
    await tester.runAsync(() async {
      await GoogleFonts.pendingFonts();

      final boundary = captureKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('/tmp/sq-$name.png').writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  }

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.clearAllTestValues();
  });

  Future<void> settleIO(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 60)));
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  Future<void> tap(WidgetTester tester, String label) async {
    debugPrint('PASS8 task: $label');
    final matches = find.text(label);
    if (matches.evaluate().isEmpty) {
      await tester.scrollUntilVisible(matches, 200,
          scrollable: find.byType(Scrollable).first);
    }
    final f = matches.first;
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    expect(f.hitTestable(), findsOneWidget, reason: label);
    await tester.runAsync(() => tester.tap(f));
    await settleIO(tester);
    expect(tester.takeException(), isNull, reason: label);
  }

  testWidgets(
      'Pass 8: guided choices, saved endings, disclosure, failures and responsive tasks',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();

    await tester.runAsync(() async {
      await app.focusJourney('knowing_jesus');
      await app.completeReaderChapter('John', 1, qualified: true);
    });
    // A locally studied passage stays primary despite the unrelated active Journey.
    await mount(
        tester, const LearnScreen(reference: 'John 3'), const Size(390, 900));
    await settleIO(tester);
    expect(find.byType(PassageLearningPanel), findsOneWidget);
    expect(find.text('Chapter learning'), findsNothing);
    expect(find.text('Related Journeys · optional'), findsNothing);
    expect(find.textContaining('Not yet completed'), findsNothing);
    expect(
        find.widgetWithText(
            FilledButton, 'Find it in the Passage · A Conversation at Night'),
        findsOneWidget);
    await capture(tester, 'pass8-guided-learn');
    await tap(tester, 'Explore this passage');
    expect(find.text('Chapter learning'), findsOneWidget);
    expect(find.textContaining('Word Search ·'), findsWidgets);
    expect(find.textContaining('Crossword ·'), findsWidgets);
    await tap(tester, 'Connections & discoveries');
    expect(find.textContaining('discovery'), findsWidgets);
    await tap(tester, 'Remember these words');
    expect(find.textContaining('Remember John'), findsWidgets);
    await tap(tester, 'Related Journeys · optional');
    expect(find.text('Knowing Jesus'), findsOneWidget);
    await tap(tester, 'Browse all learning');
    expect(find.text('Play & Learn'), findsOneWidget);
    expect(find.text('Chapter Learning'), findsOneWidget);
    await tap(tester, 'Chapter learning');
    expect(find.byType(ChapterQuizScreen), findsOneWidget);
    expect(find.textContaining('Standard ·'), findsOneWidget);
    await tap(tester, 'Change question count');
    expect(find.textContaining('Quick •'), findsOneWidget);
    final q = ChapterQuizService.getQuizForChapter('John', 3)!;
    await tap(
        tester,
        find.textContaining('Quick •').evaluate().single.widget is Text
            ? (find.textContaining('Quick •').evaluate().single.widget as Text)
                .data!
            : 'Quick');
    expect(find.text('Quick · 3 questions'), findsOneWidget);
    // Answer real authored factual questions; optional reflection remains ungraded.
    for (final question in q.questions.take(3)) {
      if (question.correctOptionIndex != null) {
        await tap(tester, question.options[question.correctOptionIndex!]);
      }
    }
    await tap(tester, 'Finish');
    expect(find.text('Chapter learning saved.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Done for now'), 180,
        scrollable: find.byType(Scrollable).first);
    expect(
        find.ancestor(
            of: find.text('Done for now'),
            matching: find.byWidgetPredicate((w) => w is FilledButton)),
        findsOneWidget);
    expect(find.text('Try again'), findsNothing);
    await tap(tester, 'Saved progress details');
    expect(find.textContaining('XP'), findsWidgets);
    await tap(tester, 'Explore more');
    expect(find.text('Try again'), findsOneWidget);
    await tap(tester, 'Try again');
    await tap(tester, 'Finish');
    expect(find.text('Chapter learning saved.'), findsOneWidget);
    expect(find.textContaining('Earlier'), findsWidgets);

    // Memory is a complete, honest session ending, not a demand to choose again.
    await mount(tester, const MemorizationPracticeScreen(verseKey: 'John:3:16'),
        const Size(390, 900));
    await settleIO(tester);
    await tap(tester, 'I practiced today');
    expect(find.textContaining('Practiced · saved'), findsOneWidget);
    expect(find.text('Choose what to explore next'), findsNothing);
    final paid = app.currentUser!.totalXP;
    await tap(tester, 'Done for now');
    expect(find.byType(QuestHubScreen), findsOneWidget);
    expect(app.sessionReturn!.reference, 'John 3:16');
    expect(app.currentUser!.totalXP, paid);
    await capture(tester, 'pass8-memory-stopped');

    // A corrupt stopping marker cannot be overwritten by the stronger button.
    final storage = (await tester.runAsync(StorageService.getInstance))!;
    final key = SessionReturn.key(app.currentUser!.id);
    final original = storage.getString(key)!;
    await tester.runAsync(() => storage.save(key, 'unreadable marker'));
    await mount(
        tester,
        const Scaffold(
            body: SingleChildScrollView(
                child: SessionEnding(passage: PassageReference('John', 3)))),
        const Size(390, 900));
    await tap(tester, 'Done for now');
    expect(find.textContaining('Could not keep your return point'),
        findsOneWidget);
    expect(storage.getString(key), 'unreadable marker');
    await tester.runAsync(() => storage.save(key, original));
    await tap(tester, 'Done for now');
    expect(find.byType(QuestHubScreen), findsOneWidget);
    expect(app.currentUser!.totalXP, paid);

    // Failed memory saving stays visible, offers another attempt, keeps bytes.
    final historyKey = 'exploration_v1_${app.currentUser!.id}';
    final history = storage.getString(historyKey)!;
    await mount(tester, const MemorizationPracticeScreen(verseKey: 'John:3:16'),
        const Size(390, 900));
    await settleIO(tester);
    await tester.runAsync(() => storage.save(historyKey, 'broken history'));
    await tap(tester, 'I practiced today');
    expect(find.textContaining('Could not save your practice'), findsOneWidget);
    expect(find.text('Done for now'), findsNothing);
    expect(storage.getString(historyKey), 'broken history');
    await tester.runAsync(() => storage.save(historyKey, history));
    await tap(tester, 'I practiced today');
    expect(find.text('Done for now'), findsOneWidget);

    // Pending delivery never hides behind result disclosure or credits a replay.
    await tester.runAsync(() => ActivityHistory(storage)
        .record(app.currentUser!.id, 'crossword_shepherd_v1', 3));
    await mount(
        tester,
        const ScriptureActivityScreen(id: 'crossword_shepherd_v1'),
        const Size(390, 900));
    await settleIO(tester);
    expect(find.text('Done for now'), findsNothing);
    await tap(tester, 'Retry saved completion');
    expect(app.activityRecords['crossword_shepherd_v1']['pending'], false);
    expect(app.activityRecords['crossword_shepherd_v1']['bestHints'], 3);
    expect(find.text('Done for now'), findsOneWidget);
    await tap(tester, 'Saved progress details');
    expect(find.textContaining('3 answer hints used'), findsOneWidget);

    // A book-order result has no fabricated passage or return-marker write.
    var replayed = false;
    final returnBeforeClassic = app.sessionReturn!.reference;
    final xpBeforeClassic = app.currentUser!.totalXP;
    await mount(
        tester,
        Scaffold(
            body: SingleChildScrollView(
                child: GameEndPanel(
          header: 'Book order complete',
          summary: 'All books ordered.',
          xp: 0,
          onPlayAgain: () => replayed = true,
          onBackToHub: () {},
        ))),
        const Size(390, 900));
    expect(find.text('Done for now'), findsOneWidget);
    expect(find.text('Play Again'), findsNothing);
    await tap(tester, 'Explore more');
    await tap(tester, 'Play Again');
    expect(replayed, true);
    await tap(tester, 'Done for now');
    expect(find.byType(QuestHubScreen), findsOneWidget);
    expect(app.sessionReturn!.reference, returnBeforeClassic);
    expect(app.currentUser!.totalXP, xpBeforeClassic);

    // Forty-eight views, plus task interactions above. Source references stay visible.
    for (final dark in [false, true]) {
      for (final width in [320.0, 768.0, 1280.0]) {
        final screens = <Widget>[
          const QuestHubScreen(),
          const LearnScreen(reference: 'John 3'),
          const LearnScreen(reference: 'Genesis 1'),
          ReadingResultSheet(result: app.lastReadingCompletion!),
          const CodexScreen(id: 'questions'),
          const MemorizationPracticeScreen(verseKey: 'John:3:16'),
          const ScriptureActivityScreen(id: 'wordSearch_night_v1'),
          const ScriptureActivityScreen(id: 'crossword_night_v1'),
        ];
        for (var i = 0; i < screens.length; i++) {
          await mount(tester, screens[i], Size(width, 900),
              dark: dark, scale: width == 320 ? 1.5 : 1);
          await settleIO(tester);
          expect(tester.takeException(), isNull, reason: '$i $width $dark');
          if (screens[i] is ReadingResultSheet) {
            expect(find.text('Reading saved'), findsOneWidget);
            expect(
                find.ancestor(
                    of: find.text('Done for now'),
                    matching: find.byWidgetPredicate((w) => w is FilledButton)),
                findsOneWidget);
            expect(find.text('Open my discovery'), findsNothing);
            await tap(tester, 'Saved progress details');
            expect(find.textContaining('John 1'), findsWidgets);
          }
          if (screens[i] is ScriptureActivityScreen) {
            final cells = find.byKey(const Key('search-0-0'));
            if (cells.evaluate().isNotEmpty) {
              expect(tester.getSize(cells).width, greaterThanOrEqualTo(44));
              expect(tester.getSize(cells).height, greaterThanOrEqualTo(44));
            } else {
              final input = find.byType(TextField);
              await tester.ensureVisible(input);
              await tester.tap(input);
              await tester.enterText(input, 'NIGHT');
              expect(tester.testTextInput.isVisible, true);
            }
          }
          await capture(
              tester, 'pass8-$i-${width.toInt()}-${dark ? 'dark' : 'light'}');
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }
      }
    }
    expect(find.bySemanticsLabel('Done for now'),
        findsNothing); // matrix is unmounted
    await mount(
        tester, const LearnScreen(reference: 'John 3'), const Size(390, 900));
    await settleIO(tester);
    expect(find.bySemanticsLabel(RegExp('Explore this passage')), findsWidgets);
    await tap(tester, 'Explore this passage');
    expect(find.textContaining('Available · optional'), findsWidgets);
    expect(app.activityRecords['crossword_shepherd_v1']['pending'], false);
    await tap(tester, 'Word Search · A Conversation at Night');
    expect(find.byType(ScriptureActivityScreen), findsOneWidget);
    expect(find.text('John 3 · KJV · 5 words'), findsOneWidget);
    semantics.dispose();
  });
}
