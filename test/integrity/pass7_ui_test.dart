import 'package:level_up_your_faith/services/activities/activity_history.dart';
import 'package:level_up_your_faith/screens/quest_hub_screen.dart';
import 'package:level_up_your_faith/widgets/connected/reading_result_sheet.dart';
import 'package:level_up_your_faith/widgets/sessions/passage_learning_panel.dart';
import 'package:level_up_your_faith/widgets/sessions/startup_gate.dart';
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
    final router = GoRouter(routes: [
      ShellRoute(
          builder: (_, __, child) => MainNavigation(child: child),
          routes: [
            GoRoute(path: '/', builder: (_, __) => screen),
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
                path: '/learn',
                builder: (_, state) =>
                    LearnScreen(reference: state.uri.queryParameters['ref'])),
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

  testWidgets(
      'Pass 7 session: route and lifecycle clocks, 28 responsive views, stopping and startup Retry',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester, const VersesScreen(selectedReference: 'Psalms 23'),
        const Size(390, 900));
    await settleIO(tester);
    final dynamic state = tester.state(find.byType(VersesScreen));
    final router = GoRouter.of(tester.element(find.byType(VersesScreen)));
    router.push('/learn');
    await settleIO(tester);
    final Duration covered = state.debugReadingTime;
    await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 180)));
    final Duration after = state.debugReadingTime;
    expect(after - covered, lessThan(const Duration(milliseconds: 40)),
        reason: 'A covered reader is not active reading');
    router.pop();
    await settleIO(tester);
    final Duration resumed = state.debugReadingTime;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 180)));
    expect(state.debugReadingTime - resumed,
        lessThan(const Duration(milliseconds: 40)));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    final Duration activeAgain = state.debugReadingTime;
    await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 180)));
    expect(state.debugReadingTime, greaterThan(activeAgain));
    // Direct route entry and a query change reuse the reader safely.
    router.go('/verses?ref=John+3');
    await settleIO(tester);
    expect(find.byType(VersesScreen), findsOneWidget);
    router.go('/verses?ref=Romans+8');
    await settleIO(tester);
    expect(app.lastBibleReference, contains('Romans 8'));
    final dynamic changed = tester.state(find.byType(VersesScreen));
    expect(changed.debugReadingTime, lessThan(const Duration(seconds: 2)));
    router.go('/learn?ref=Romans+8');
    await settleIO(tester);
    expect(find.text('Romans 8'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));

    await tester.runAsync(() async {
      await app.focusJourney('knowing_jesus');
      await app.completeReaderChapter('John', 1, qualified: true);
    });
    final semantics = tester.ensureSemantics();
    for (final dark in [false, true]) {
      for (final width in [320.0, 1280.0]) {
        for (final screen in <Widget>[
          const QuestHubScreen(),
          const LearnScreen(reference: 'Romans 8'),
          const LearnScreen(reference: 'John 3'),
          const GuidedJourneyScreen(id: 'knowing_jesus'),
          ReadingResultSheet(result: app.lastReadingCompletion!),
          const ScriptureActivityScreen(id: 'crossword_shepherd_v1'),
          const ScriptureActivityScreen(id: 'wordSearch_shepherd_v1'),
        ]) {
          await mount(tester, screen, Size(width, 900),
              dark: dark, scale: width == 320 ? 1.5 : 1);
          await settleIO(tester);
          if (screen is LearnScreen) {
            expect(find.byType(PassageLearningPanel), findsOneWidget);
            expect(find.text('YOUR PASSAGE'), findsOneWidget);
          }
          if (screen is ReadingResultSheet) {
            expect(find.text('Reading saved'), findsOneWidget);
            expect(
                find.byWidgetPredicate(
                    (w) => w is Semantics && w.properties.liveRegion == true),
                findsWidgets);
          }
          if (screen is GuidedJourneyScreen) {
            expect(find.text('Continue without writing'), findsOneWidget);
            await tester.scrollUntilVisible(
                find.text('See the Journey outline'), 200,
                scrollable: find.byType(Scrollable).first);
            expect(find.text('See the Journey outline'), findsOneWidget);
          }
          expect(tester.takeException(), isNull,
              reason: '${screen.runtimeType} $width $dark');
          await capture(tester,
              'pass7-${screen.runtimeType}-${screen is LearnScreen ? screen.reference : ""}-$width-$dark');
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(seconds: 3));
        }
      }
    }
    final savedStorage = (await tester.runAsync(StorageService.getInstance))!;
    await tester.runAsync(() => ActivityHistory(savedStorage)
        .record(app.currentUser!.id, 'crossword_shepherd_v1', 3));
    await mount(
        tester,
        const ScriptureActivityScreen(id: 'crossword_shepherd_v1'),
        const Size(390, 900));
    await settleIO(tester);
    final retrySaved = find.text('Retry saved completion');
    await tester.ensureVisible(retrySaved);
    await tester.runAsync(() => tester.tap(retrySaved));
    await settleIO(tester);
    expect(app.activityRecords['crossword_shepherd_v1']['pending'], false);
    expect(app.activityRecords['crossword_shepherd_v1']['bestHints'], 3);
    expect(find.text('Activity completed'), findsOneWidget);
    final paid = app.currentUser!.totalXP;
    await tester.runAsync(() => app.completeActivity('crossword_shepherd_v1',
        answers: {
          'SHEPHERD': 'SHEPHERD',
          'GREEN': 'GREEN',
          'WATERS': 'WATERS',
          'SOUL': 'SOUL',
          'TABLE': 'TABLE'
        },
        hints: 3));
    expect(app.currentUser!.totalXP, paid);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await mount(tester, const QuestHubScreen(), const Size(390, 900));
    await settleIO(tester);
    late Future<void> resultClosed;
    await tester.runAsync(() async {
      resultClosed = showReadingResult(
          tester.element(find.byType(QuestHubScreen)),
          app.lastReadingCompletion!);
    });
    await settleIO(tester);
    final done = find.text('Done for now');
    await tester.scrollUntilVisible(done, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(done);
    await settleIO(tester);
    await tester.runAsync(() => resultClosed);
    final storage = (await tester.runAsync(StorageService.getInstance))!;
    expect(
        SessionReturn.read(storage, app.currentUser!.id)!.reference, 'John 1');
    await tester.pumpWidget(const SizedBox.shrink());
    await mount(tester, const QuestHubScreen(), const Size(390, 900));
    await settleIO(tester);
    expect(find.text('OPTIONAL REVISIT'), findsOneWidget);
    expect(find.textContaining('session is saved'), findsOneWidget);
    await capture(tester, 'pass7-stopped-today');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    // Startup gate blocks direct content even with a previously loaded user.
    final profile = storage.getString('current_user')!;
    await tester.runAsync(() => storage.save('current_user', 'broken'));
    await tester.runAsync(app.startInitialization);
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: app,
        child: RepaintBoundary(
            key: captureKey,
            child: MaterialApp(
                theme: ScriptureThemes.build(ScriptureThemes.scriptureLight),
                home: const StartupGate(child: Text('Restored content'))))));
    await settleIO(tester);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Restored content'), findsNothing);
    expect(storage.getString('current_user'), 'broken');
    await capture(tester, 'pass7-startup-retry');
    await tester.runAsync(() => storage.save('current_user', profile));
    await tester.tap(find.text('Retry'));
    await settleIO(tester);
    expect(find.text('Restored content'), findsOneWidget);
    expect(app.initializationError, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
    semantics.dispose();
  });
}
