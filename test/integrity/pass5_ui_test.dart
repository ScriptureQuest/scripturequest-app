import 'package:level_up_your_faith/widgets/connected/reading_result_sheet.dart';
import 'package:level_up_your_faith/screens/quest_hub_screen.dart';
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

  testWidgets(
      'continuation navigates Today to Journey to Scripture and back in both themes and sizes',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final dark in [false, true]) {
      for (final width in [320.0, 1280.0]) {
        await mount(tester, const QuestHubScreen(), Size(width, 900),
            dark: dark);
        await settleIO(tester);
        final next = find.widgetWithText(FilledButton, 'Begin Getting Started');
        // Once enrolled, returning Today must recognize the existing Journey.
        final resume =
            find.widgetWithText(FilledButton, 'Continue Getting Started');
        final action = next.evaluate().isNotEmpty ? next : resume;
        await tester.ensureVisible(action);
        await tester.tap(action);
        await settleIO(tester);
        expect(find.text('Read in the Bible'), findsWidgets);
        final begin = find.text('Begin this Journey');
        if (begin.evaluate().isNotEmpty) {
          await tester.ensureVisible(begin);
          await tester.runAsync(() => tester.tap(begin));
          await settleIO(tester);
        }
        final read = find.text('Read in the Bible').first;
        await tester.ensureVisible(read);
        await tester.tap(read);
        await settleIO(tester);
        expect(find.byType(VersesScreen), findsOneWidget);
        final readerContext = tester.element(find.byType(VersesScreen));
        GoRouter.of(readerContext).pop();
        await settleIO(tester);
        expect(find.byType(GuidedJourneyScreen), findsOneWidget);
        GoRouter.of(tester.element(find.byType(GuidedJourneyScreen))).pop();
        await settleIO(tester);
        expect(find.byType(QuestHubScreen), findsOneWidget);
        expect(find.text('Continue Getting Started'), findsOneWidget);
        await capture(
            tester, 'pass5-today-${dark ? 'dark' : 'light'}-${width.toInt()}');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 3));
      }
    }
  });
  testWidgets(
      'completion and learning share Journey guidance; Codex and finished history remain reachable',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await app.focusJourney('knowing_jesus');
      await app.completeReaderChapter('John', 1, qualified: true);
    });
    for (final dark in [false, true]) {
      for (final width in [320.0, 1280.0]) {
        for (final screen in <Widget>[
          ReadingResultSheet(result: app.lastReadingCompletion!),
          const LearnScreen(),
          const CodexScreen(id: 'word'),
          const JourneysScreen(board: true),
        ]) {
          await mount(tester, screen, Size(width, 900), dark: dark);
          await settleIO(tester);
          if (screen is ReadingResultSheet || screen is LearnScreen) {
            expect(find.text('Continue Knowing Jesus'), findsOneWidget);
            expect(find.textContaining('without writing'), findsOneWidget);
          }
          await capture(tester,
              'pass5-${screen.runtimeType}-${dark ? 'dark' : 'light'}-${width.toInt()}');
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(seconds: 3));
        }
      }
    }
  });
}
