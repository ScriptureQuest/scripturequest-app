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
    await tester.runAsync(() async { await settings.initialize(); await settings.setBibleReaderTheme(dark ? 'night' : 'paper'); });
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
                    child: ReadingDesign(child: child!))))));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });
    await tester.pump(const Duration(milliseconds: 400));
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

  testWidgets(
      'Pass 3 real layouts at phone and desktop widths, with optional art',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await app.focusJourney('knowing_jesus');
      await app.completeReaderChapter('John', 1, qualified: true);
    });
    for (final size in [const Size(320, 740), const Size(1280, 900)]) {
      for (final entry in <String, Widget>{
        'learn': const LearnScreen(),
        'discovery': const CodexScreen(id: 'word'),
        'board': const JourneysScreen(board: true),
        'memory': const MemorizationPracticeScreen(verseKey: 'John:1:14'),
        'you': const YouScreen(),
      }.entries) {
        await mount(tester, entry.value, size);
        expect(tester.takeException(), isNull, reason: '${entry.key} at $size');
        await capture(tester, 'pass3-${entry.key}-${size.width.toInt()}');
        await tester.pumpWidget(const SizedBox());
      }
    }
    await tester.runAsync(() => app.setIllustratedExploration(false));
    await mount(tester, const CodexScreen(id: 'word'), const Size(320, 740));
    expect(
        find.byType(CustomPaint).evaluate().where((e) =>
            (e.widget as CustomPaint).painter.runtimeType.toString() ==
            '_Landscape'),
        isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'dark large-text discovery and reduced-motion result retain readable layout',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester, const CodexScreen(id: 'shepherd'), const Size(390, 844),
        dark: true, scale: 1.8, reduceMotion: true);
    expect(tester.takeException(), isNull);
    await capture(tester, 'pass3-dark-large-text');
    for (var i = 0; i < 8; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets(
      'finding evidence gives a single saved result and real next actions',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(
        tester, const FindPassageScreen(id: 'refuge'), const Size(390, 844));
    await tester.tap(find.text('Show a clue'));
    await tester.pump();
    expect(find.textContaining('Look for'), findsOneWidget);
    final verse = find.widgetWithText(OutlinedButton,
        '1 God is our refuge and strength, a very present help in trouble.');
    await tester.ensureVisible(verse);
    await tester.runAsync(() => tester.tap(verse));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 30)));
    }
    await tester.pump(const Duration(milliseconds: 400));
    expect(
        find.textContaining('Evidence found in Psalms 46:1.'), findsOneWidget);
    expect(find.text('Keep exploring this discovery'), findsOneWidget);
    expect(find.text('Remember a verse from this passage'), findsOneWidget);
    expect((app.explorationState['learning'] as Map).containsKey('refuge'),
        isTrue);
    expect(app.questProgressEvent, 0);
    expect(tester.takeException(), isNull);
    await capture(tester, 'pass3-evidence-result');
  });
  testWidgets(
      'memory displays complete selected Scripture, records help honestly and saves once',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester, const MemorizationPracticeScreen(verseKey: 'John:3:16'),
        const Size(390, 844));
    expect(find.textContaining('For God so loved the world'), findsOneWidget);
    await tester.tap(find.text('Hide the verse and try recalling'));
    await tester.pump();
    expect(find.textContaining('For God so loved the world'), findsNothing);
    await tester.tap(find.text('Show the passage for help'));
    await tester.pump();
    expect(find.text('I recalled it independently'), findsNothing);
    final button = find.text('I recalled it with help');
    await tester.ensureVisible(button);
    await tester.runAsync(() => tester.tap(button));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 30)));
    }
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Recalled with help · saved'), findsOneWidget);
    final sessions =
        app.explorationState['memory']['John:3:16']['sessions'] as Map;
    expect(sessions.length, 1);
    expect(sessions.values.single['outcome'], 'helped');
    expect(find.text('I recalled it with help'), findsNothing);
    expect(tester.takeException(), isNull);
    await capture(tester, 'pass3-memory-result');
  });
  testWidgets(
      'connected discovery to learning to memory to further Scripture uses real routes',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(
        () => app.completeReaderChapter('Psalms', 46, qualified: true));
    await mount(tester, const CodexScreen(id: 'refuge'), const Size(390, 844));
    Future<void> tapText(String text) async {
      final finder = find.text(text);
      for (var i = 0; finder.evaluate().isEmpty && i < 20; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -300));
        await tester.pump(const Duration(milliseconds: 400));
      }
      await tester.ensureVisible(finder);
      await tester.runAsync(() => tester.tap(finder));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        await tester.runAsync(
            () async => Future<void>.delayed(const Duration(milliseconds: 30)));
      }
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    }

    await tapText('Find it in the Passage');
    await tapText(
        '1 God is our refuge and strength, a very present help in trouble.');
    await tapText('Remember a verse from this passage');
    await tapText('I practiced today');
    expect(
        app.explorationState['memory']['Psalms:46:1']['sessions'], isNotEmpty);
    await tapText('My remembered Scripture');
    expect(find.textContaining('1 practiced'), findsOneWidget);
    await tapText('Discover a passage to remember');
    expect(app.discoveryRecords.containsKey('refuge'), isTrue);
    await tapText('Read Psalms 23');
    expect(find.byType(VersesScreen), findsOneWidget);
  });
}
