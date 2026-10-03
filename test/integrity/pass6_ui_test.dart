import 'package:level_up_your_faith/screens/activities/activity_screen.dart';
import 'package:level_up_your_faith/screens/play_learn_hub_screen.dart';
import 'package:level_up_your_faith/data/activities/activity_catalog.dart';
import 'package:level_up_your_faith/services/activities/puzzle_engine.dart';
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
            GoRoute(path: '/learn', builder: (_, __) => const LearnScreen()),
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

  Future<void> checkLayouts(WidgetTester tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final dark in [false, true])
      for (final width in [320.0, 1280.0]) {
        for (final screen in <Widget>[
          const PlayLearnHubScreen(),
          const ScriptureActivityScreen(id: 'wordSearch_shepherd_v1'),
          const ScriptureActivityScreen(id: 'crossword_shepherd_v1')
        ]) {
          await mount(tester, screen, Size(width, 900), dark: dark);
          await settleIO(tester);
          expect(tester.takeException(), isNull);
          expect(find.textContaining('could not load'), findsNothing);
          await capture(tester, 'pass6-${screen.runtimeType}-$width-$dark');
          await tester.pumpWidget(const SizedBox());
        }
      }
  }
  Future<void> solveCrossword(WidgetTester tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(
        tester,
        const ScriptureActivityScreen(id: 'crossword_shepherd_v1'),
        const Size(390, 900));
    await settleIO(tester);
    final puzzle = CrosswordPuzzle(ActivityCatalog.shepherd);
    for (var i = 0; i < puzzle.entries.length; i++) {
      final e = puzzle.entries[i];
      final clue = find.text('${i + 1} ${e.across ? 'Across' : 'Down'}');
      await tester.scrollUntilVisible(clue, 200,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(clue);
      await tester.pump();
      final input = find.byKey(const Key('crossword-answer'));
      await tester.scrollUntilVisible(input, 150,
          scrollable: find.byType(Scrollable).first);
      await tester.pump();
      await tester.enterText(input, e.word.answer);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
    }
    final save = find.text('Save completed activity');
    await tester.scrollUntilVisible(save, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(save);
    await settleIO(tester);
    expect(find.text('Passage explored'), findsOneWidget);
    expect(app.activityRecords.containsKey('crossword_shepherd_v1'), isTrue);
    expect(find.text('Choose a verse to remember'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await capture(tester, 'pass6-crossword-complete');
  }
  Future<void> solveWordSearch(WidgetTester tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(
        tester,
        const ScriptureActivityScreen(id: 'wordSearch_shepherd_v1'),
        const Size(390, 900),
        dark: true);
    await settleIO(tester);

    var firstXP = 0;
    for (var seed = 0; seed < 2; seed++) {

      final puzzle = WordSearchPuzzle(ActivityCatalog.shepherd, seed: seed);
      for (final path in puzzle.paths.values) {
        for (final cell in [path.first, path.last]) {

          final target = find.byKey(Key('search-${cell.row}-${cell.col}'));
          if (target.evaluate().isEmpty)
            await tester.scrollUntilVisible(target, 200,
                scrollable: find.byType(Scrollable).first);
          final visible = tester.ensureVisible(target);
          await tester.pumpAndSettle();
          await visible;
          await tester.pump();
          await tester.tap(target);
          await tester.pump();
        }
      }

      final save = find.text('Save completed activity');
      await tester.scrollUntilVisible(save, 200,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(save);
      await settleIO(tester);
      expect(find.text('Passage explored'), findsOneWidget);
      if (seed == 0) {
        firstXP = app.currentUser!.totalXP;
        final replay = find.text('Play again · no repeat XP');
        await tester.scrollUntilVisible(replay, 200,
            scrollable: find.byType(Scrollable).first);
        await tester.tap(replay);
        await tester.pump();
      } else {
        expect(app.currentUser!.totalXP, firstXP);
      }
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }
  testWidgets('Pass 6 continuous session: theme/size matrix, crossword, word search and replay', (tester) async {
    // Keep the real completion queues in one test event loop, as in one app session.
    // All layout, completion, continuation and replay assertions remain in place.
    await checkLayouts(tester);
    await solveCrossword(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await solveWordSearch(tester);
  });
}
