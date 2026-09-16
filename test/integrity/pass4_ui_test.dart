import 'package:level_up_your_faith/widgets/connected/reading_result_sheet.dart';
import 'package:level_up_your_faith/screens/profile_screen.dart';
import 'package:level_up_your_faith/screens/achievements_screen.dart';
import 'package:level_up_your_faith/screens/play_learn_hub_screen.dart';
import 'package:level_up_your_faith/screens/chapter_quiz_screen.dart';
import 'package:level_up_your_faith/screens/journal_screen.dart';
import 'package:level_up_your_faith/screens/bookmarks_screen.dart';
import 'package:level_up_your_faith/screens/highlights_screen.dart';
import 'package:level_up_your_faith/screens/reading_stats_screen.dart';
import 'package:level_up_your_faith/screens/settings_screen.dart';
import 'package:level_up_your_faith/screens/matching_game_screen.dart';
import 'package:level_up_your_faith/screens/verse_scramble_screen.dart';
import 'package:level_up_your_faith/screens/book_order_game_screen.dart';
import 'package:level_up_your_faith/screens/emoji_parables_screen.dart';
import 'package:level_up_your_faith/screens/memorization_screen.dart';
import 'package:level_up_your_faith/screens/quest_hub_screen.dart';
import 'package:level_up_your_faith/widgets/common/game_end_panel.dart';
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
    await tester.runAsync(() async => Future<void>.delayed(const Duration(milliseconds:50)));
    await tester.pump(const Duration(seconds:3));
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

  testWidgets('Pass 4 real light and dark pages at phone and larger widths',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await app.focusJourney('knowing_jesus');
      await app.completeReaderChapter('John', 1, qualified: true);
      await app.toggleBookmark('John:1:14');
      await app.setHighlight('John:1:14','sun');
      await app.createJournalEntry(title:'A thought to keep',body:'What does it mean that the Word dwelt among us?',tags:['John','question'],linkedRef:'John 1:14',linkedRefRoute:'/verses?ref=John%201');
    });
    final xp = app.currentUser!.totalXP;
    for (final dark in [false, true]) {
      for (final size in [const Size(320, 740), const Size(1280, 900)]) {
        for (final entry in <String, Widget>{
          'today': const QuestHubScreen(),
          'journey': const GuidedJourneyScreen(id: 'knowing_jesus'),
          'learn': const LearnScreen(),
          'play': const PlayLearnHubScreen(),
          'achievements': const AchievementsScreen(),
          'you': const YouScreen(),
          'codex': const CodexScreen(id: 'word'),
          'board': const JourneysScreen(board: true),
          'reading-result':Scaffold(body:ReadingResultSheet(result:app.lastReadingCompletion!)),
          'journal': const JournalScreen(),
          'bookmarks': const BookmarksScreen(),
          'highlights': const HighlightsScreen(),
          'history': const ReadingStatsScreen(),
          'profile': const ProfileScreen(),
          'settings': const SettingsScreen(),
          'chapter': const ChapterQuizScreen(bookId: 'John', chapter: 3),
          'matching': const MatchingGameScreen(),
          'scramble': const VerseScrambleScreen(),
          'order': const BookOrderGameScreen(),
          'parables': const EmojiParablesScreen(),
          'practice': const MemorizationScreen(),
          'game-result': Scaffold(
              body: SingleChildScrollView(
                  child: GameEndPanel(
                      header: 'Well explored!',
                      summary: 'You matched all pairs.',
                      xp: 10,
                      onPlayAgain: () {},
                      onBackToHub: () {}))),
        }.entries) {
          await mount(tester, entry.value, size, dark: dark);
          expect(tester.takeException(), isNull,
              reason: '${entry.key} $size dark=$dark');
          await capture(tester,
              'pass4-${entry.key}-${dark ? 'dark' : 'light'}-${size.width.toInt()}');
          for (var i = 0; i < 3; i++) {
            final list = find.byType(Scrollable);
            if (list.evaluate().isNotEmpty) {
              await tester.drag(list.first, const Offset(0, -500));
              await tester.pump(const Duration(milliseconds: 400));
              expect(tester.takeException(), isNull,
                  reason: 'scrolled ${entry.key} $size dark=$dark');
            }
          }
          if (entry.key == 'achievements')
            await capture(tester,
                'pass4-badges-${dark ? 'dark' : 'light'}-${size.width.toInt()}');
          await tester.pumpWidget(const SizedBox());
        }
      }
    }
    expect(app.currentUser!.totalXP, xp,
        reason: 'browsing appearance and accomplishments must not grant XP');
  });
  testWidgets(
      'large text theme selection and achievement filters remain usable',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final dark in [false, true]) {
      await mount(
          tester,
          const Scaffold(
              body: SingleChildScrollView(
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child: AppearanceChoices()))),
          const Size(320, 740),
          dark: dark,
          scale: 1.8,
          reduceMotion: true);
      expect(tester.takeException(), isNull);
      final selection = find.text(dark ? 'Scripture Light' : 'Scripture Dark');
      await tester.ensureVisible(selection);
      await tester.runAsync(() => tester.tap(selection));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await mount(tester, const AchievementsScreen(), const Size(320, 740),
          dark: dark, scale: 1.8, reduceMotion: true);
      final earned = find.widgetWithText(ChoiceChip, 'Earned');
      await tester.scrollUntilVisible(earned, 250,
          scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(earned);
      await tester.tap(earned);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await capture(
          tester, 'pass4-achievement-large-${dark ? 'dark' : 'light'}');
      await tester.pumpWidget(const SizedBox());
    }
  });
}
