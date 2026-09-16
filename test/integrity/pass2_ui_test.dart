import 'package:level_up_your_faith/theme/scripture_theme.dart';
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
import 'package:level_up_your_faith/screens/verses_screen.dart';
import 'package:level_up_your_faith/screens/quest_hub_screen.dart';
import 'package:level_up_your_faith/screens/connected/journeys_screen.dart';
import 'package:level_up_your_faith/screens/connected/discovery_screen.dart';
import 'package:level_up_your_faith/widgets/bible_reader_styles.dart';
import 'package:level_up_your_faith/widgets/reading_v2/reading_design.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppProvider app;
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'), (_) async => Directory.systemTemp.path);
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
  Future<void> mount(WidgetTester tester, Widget screen, Size size, {bool dark = false}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    await tester.runAsync(() async {
      await app.loadKjvPassage('John 3');
      final icons = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
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
    final router =
        GoRouter(routes: [GoRoute(path: '/', builder: (_, __) => MainNavigation(child: screen))]);
    addTearDown(router.dispose);
    final settings=SettingsProvider();
    await tester.runAsync(() async { await settings.initialize(); await settings.setQuestTheme(dark?ScriptureThemes.scriptureDark:ScriptureThemes.scriptureLight); });
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
                builder: (_, child) => ReadingDesign(child: child!)))));
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

  for(final dark in [false,true]) testWidgets(
      'actual John 3 reader renders Nicodemus 4 and 9 as body text, retaining Jesus speech (dark=$dark)',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester, const VersesScreen(selectedReference: 'John 3'),
        const Size(390, 844), dark:dark);
    await capture(tester, 'john3-initial-${dark?'dark':'light'}');
    Finder verse(int n) => find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().startsWith('$n '));
    final bodyColor =
        BibleReaderStyles.verseBody(1, BibleReaderStyles.themeFor(dark?'night':'paper'))
            .color;
    final speechColor =
        BibleReaderStyles.jesusWords(1, BibleReaderStyles.themeFor(dark?'night':'paper'))
            .color;
    List<Color?> colors(TextSpan span, [Color? parent]) => [
          if ((span.text ?? '').isNotEmpty) span.style?.color ?? parent,
          for (final child in span.children ?? <InlineSpan>[])
            if (child is TextSpan)
              ...colors(child, span.style?.color ?? parent),
        ];
    for (final n in [3, 4, 5, 9, 10]) {
      for (var i = 0; verse(n).evaluate().isEmpty && i < 12; i++) {
        await tester.drag(find.byType(VersesScreen), const Offset(0, -220));
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(verse(n), findsOneWidget,
          reason: 'Verse $n must be present in the actual reader');
      await tester.ensureVisible(verse(n));
      await tester.pump(const Duration(milliseconds: 400));
      final rendered = tester.widget<RichText>(verse(n)).text as TextSpan;
      final actual = colors(rendered);
      if (n == 4 || n == 9) {
        expect(rendered.toPlainText(), contains('Nicodemus'));
        expect(actual, isNot(contains(speechColor)),
            reason: 'Nicodemus must never inherit the Jesus speech color');
        expect(actual, contains(bodyColor));
        await capture(tester, 'john3-$n-${dark?'dark':'light'}');
      } else {
        expect(actual, contains(speechColor),
            reason: 'Jesus speech must remain red');
      }
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'connected Journey and Codex screens fit phone and desktop widths',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() => app.focusJourney('psalms_of_peace'));
    for (final size in [const Size(320, 740), const Size(1280, 900)]) {
      for (final entry in <String, Widget>{
        'today': const QuestHubScreen(),
        'journey': const GuidedJourneyScreen(id: 'psalms_of_peace'),
        'board': const JourneysScreen(board: true),
        'codex': const DiscoveryScreen(),
      }.entries) {
        await mount(tester, entry.value, size);
        expect(tester.takeException(), isNull,
            reason: '${entry.key} at ${size.width}');
        await capture(tester, '${entry.key}-${size.width.toInt()}');
        await tester.pumpWidget(const SizedBox());
      }
    }
  });
}
