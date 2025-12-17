import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/screens/main_navigation.dart';
import 'package:level_up_your_faith/screens/home_screen.dart';
import 'package:level_up_your_faith/screens/verses_screen.dart';
import 'package:level_up_your_faith/screens/quest_board_screen.dart';
import 'package:level_up_your_faith/screens/profile_screen.dart';
import 'package:level_up_your_faith/screens/verse_detail_screen.dart';
import 'package:level_up_your_faith/screens/achievements_screen.dart';
import 'package:level_up_your_faith/screens/journal_screen.dart';
import 'package:level_up_your_faith/screens/scripture_screen.dart';
import 'package:level_up_your_faith/screens/favorites_screen.dart';
import 'package:level_up_your_faith/screens/public_profile_screen.dart';
// Journey Board replaces the old Leaderboards screen (private, offline)
import 'package:level_up_your_faith/screens/journey_board_screen.dart';
import 'package:level_up_your_faith/screens/friends_screen.dart';
import 'package:level_up_your_faith/screens/community_screen.dart';
import 'package:level_up_your_faith/screens/settings_screen.dart';
import 'package:level_up_your_faith/providers/settings_provider.dart';
import 'package:level_up_your_faith/screens/completed_quests_screen.dart';
// Inventory and Equip UIs are hidden in v1.0 (routes redirect to Coming Soon)
import 'package:level_up_your_faith/screens/questlines_screen.dart';
import 'package:level_up_your_faith/services/gear_inventory_service.dart';
import 'package:level_up_your_faith/providers/equipment_provider.dart';
import 'package:level_up_your_faith/screens/avatar/soul_avatar_equip_screen.dart';
import 'package:level_up_your_faith/screens/questline_detail_screen.dart';
import 'package:level_up_your_faith/screens/collection/collection_screen.dart';
import 'package:level_up_your_faith/screens/book_mastery_screen.dart';
import 'package:level_up_your_faith/services/bible_service.dart';
import 'package:level_up_your_faith/screens/reading_stats_screen.dart';
import 'package:level_up_your_faith/screens/reading_plans_screen.dart';
import 'package:level_up_your_faith/screens/chapter_quiz_screen.dart';
import 'package:level_up_your_faith/screens/favorite_verses_screen.dart';
import 'package:level_up_your_faith/screens/memorization_screen.dart';
import 'package:level_up_your_faith/screens/memorization_practice_screen.dart';
import 'package:level_up_your_faith/screens/highlights_screen.dart';
import 'package:level_up_your_faith/screens/bookmarks_screen.dart';
import 'package:level_up_your_faith/theme/app_theme.dart';
import 'package:level_up_your_faith/screens/onboarding_screen.dart';
import 'package:level_up_your_faith/screens/onboarding_personalized/personalized_setup_flow.dart';
import 'package:level_up_your_faith/services/cosmetic_service.dart';
import 'package:level_up_your_faith/screens/cosmetics_preview_screen.dart';
import 'package:level_up_your_faith/screens/matching_game_screen.dart';
import 'package:level_up_your_faith/screens/verse_scramble_screen.dart';
import 'package:level_up_your_faith/screens/book_order_game_screen.dart';
import 'package:level_up_your_faith/screens/emoji_parables_screen.dart';
import 'package:level_up_your_faith/screens/support_screen.dart';
import 'package:level_up_your_faith/screens/play_learn_hub_screen.dart';
import 'package:level_up_your_faith/screens/quest_hub_screen.dart';

void main() {
  // Capture and log framework errors early so we can diagnose startup issues.
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    if (details.stack != null) {
      debugPrint(details.stack.toString());
    }
    // Also forward to default error handler in debug to keep behavior consistent
    FlutterError.presentError(details);
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Global BibleService singleton
        Provider<BibleService>.value(value: BibleService.instance),
        // Gear inventory: in-memory manager. Debug builds may auto-seed a few canonical items.
        ChangeNotifierProvider(create: (_) => GearInventoryService()),
        // App provider depends on GearInventoryService for LootService wiring.
        ChangeNotifierProxyProvider<GearInventoryService, AppProvider>(
          create: (_) => AppProvider(),
          update: (context, gear, app) {
            app ??= AppProvider();
            if (gear != null) {
              app.attachGearInventory(gear);
            }
            if (!app.isInitialized) {
              app.initialize();
            }
            return app;
          },
        ),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..initialize()),
        // Soul Avatar equipment provider (depends on GearInventoryService and AppProvider user)
        ChangeNotifierProxyProvider2<GearInventoryService, AppProvider, EquipmentProvider>(
          create: (ctx) => EquipmentProvider(gearInventoryService: ctx.read<GearInventoryService>()),
          update: (ctx, gear, app, eq) {
            eq ??= EquipmentProvider(gearInventoryService: gear);
            eq.setUser(app.currentUser?.id);
            return eq;
          },
        ),
        // CosmeticService (architecture-only; purchases disabled)
        ChangeNotifierProxyProvider<AppProvider, CosmeticService>(
          create: (ctx) => CosmeticService(app: ctx.read<AppProvider>()),
          update: (ctx, app, svc) => svc ?? CosmeticService(app: app),
        ),
      ],
      child: Consumer2<AppProvider, CosmeticService>(
        builder: (context, app, cosmetics, _) {
          final mode = app.themeMode;
          final theme = cosmetics.previewTheme ?? appThemeFor(mode);
          debugPrint('MyApp: building MaterialApp with theme mode=$mode');
          return MaterialApp.router(
            title: 'Scripture Quest',
            debugShowCheckedModeBanner: false,
            theme: theme,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

final _router = GoRouter(
  routes: [
    // Onboarding shown outside the shell (no bottom nav)
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/onboarding/personalized',
      builder: (context, state) => const PersonalizedSetupFlow(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainNavigation(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const QuestHubScreen(),
        ),
            // Convenience alias to always navigate Home via /home
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
        // Bible center tab convenience route
        GoRoute(
          path: '/bible',
          builder: (context, state) => const VersesScreen(),
        ),
        GoRoute(
          path: '/verses',
          builder: (context, state) {
            final ref = state.uri.queryParameters['ref'];
            final focusStr = state.uri.queryParameters['focus'];
            final focus = focusStr == null ? null : int.tryParse(focusStr);
            return VersesScreen(selectedReference: ref, initialFocusVerse: focus);
          },
        ),
        GoRoute(
          path: '/scripture',
          builder: (context, state) => const ScriptureScreen(),
        ),
        // New: Quests (formerly Questlines)
        GoRoute(
          path: '/quests',
          builder: (context, state) => const QuestlinesScreen(),
        ),
        // Backward-compat: /questlines -> Quests
        GoRoute(
          path: '/questlines',
          builder: (context, state) => const QuestlinesScreen(),
        ),
        // New: Tasks (formerly small Quests) board
        GoRoute(
          path: '/tasks',
          builder: (context, state) => const QuestBoardScreen(),
        ),
        GoRoute(
          path: '/tasks/completed',
          builder: (context, state) => const CompletedQuestsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        // Journey Board (personal stats)
        GoRoute(
          path: '/journey-board',
          builder: (context, state) => const JourneyBoardScreen(),
        ),
        // Backward-compat alias
        GoRoute(
          path: '/leaderboards',
          builder: (context, state) => const JourneyBoardScreen(),
        ),
        // Community tab entry point (offline Community v1.0)
        GoRoute(
          path: '/community',
          builder: (context, state) => const CommunityScreen(),
        ),
        GoRoute(
          path: '/friends',
          builder: (context, state) => const FriendsScreen(),
        ),
        GoRoute(
          path: '/journal',
          builder: (context, state) => const JournalScreen(),
        ),
        GoRoute(
          path: '/favorites',
          builder: (context, state) => const FavoritesScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        // Inventory/Eq routes now show Coming Soon to preserve backend but hide UI
        GoRoute(
          path: '/inventory',
          builder: (context, state) => const SoulAvatarEquipScreen(),
        ),
        GoRoute(
          path: '/inventory/list',
          builder: (context, state) => const SoulAvatarEquipScreen(),
        ),
        GoRoute(
          path: '/equip',
          builder: (context, state) => const SoulAvatarEquipScreen(),
        ),
        GoRoute(
          path: '/collection',
          builder: (context, state) => const CollectionScreen(),
        ),
        // Avatar Coming Soon — tab target
        GoRoute(
          path: '/avatar',
          builder: (context, state) => const SoulAvatarEquipScreen(),
        ),
        GoRoute(
          path: '/cosmetics',
          builder: (context, state) => const CosmeticsPreviewScreen(),
        ),
        GoRoute(
          path: '/reading-stats',
          builder: (context, state) => const ReadingStatsScreen(),
        ),
        GoRoute(
          path: '/reading-plans',
          builder: (context, state) => const ReadingPlansScreen(),
        ),
        // Play & Learn hub (lists all mini-games)
        GoRoute(
          path: '/play-learn',
          builder: (context, state) => const PlayLearnHubScreen(),
        ),
        GoRoute(
          path: '/highlights',
          builder: (context, state) => const HighlightsScreen(),
        ),
        GoRoute(
          path: '/bookmarks',
          builder: (context, state) => const BookmarksScreen(),
        ),
        GoRoute(
          path: '/favorite-verses',
          builder: (context, state) => const FavoriteVersesScreen(),
        ),
        GoRoute(
          path: '/matching-game',
          builder: (context, state) => const MatchingGameScreen(),
        ),
        GoRoute(
          path: '/verse-scramble',
          builder: (context, state) => const VerseScrambleScreen(),
        ),
        GoRoute(
          path: '/book-order-game',
          builder: (context, state) => const BookOrderGameScreen(),
        ),
        GoRoute(
          path: '/emoji-parables',
          builder: (context, state) => const EmojiParablesScreen(),
        ),
        GoRoute(
          path: '/support',
          builder: (context, state) => const SupportScreen(),
        ),
        GoRoute(
          path: '/memorization',
          builder: (context, state) => const MemorizationScreen(),
        ),
        GoRoute(
          path: '/memorization-practice',
          builder: (context, state) {
            final key = state.uri.queryParameters['key'] ?? '';
            return MemorizationPracticeScreen(verseKey: key);
          },
        ),
        GoRoute(
          path: '/chapter-quiz',
          builder: (context, state) {
            final book = state.uri.queryParameters['book'] ?? '';
            final chapterStr = state.uri.queryParameters['chapter'] ?? '0';
            final chapter = int.tryParse(chapterStr) ?? 0;
            return ChapterQuizScreen(bookId: book, chapter: chapter);
          },
        ),
        GoRoute(
          path: '/book-mastery',
          builder: (context, state) => const BookMasteryScreen(),
        ),
        GoRoute(
          path: '/avatar/equip',
          builder: (context, state) => const SoulAvatarEquipScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/verse/:id',
      builder: (context, state) {
        final verseId = state.pathParameters['id']!;
        return VerseDetailScreen(verseId: verseId);
      },
    ),
    // New: Quest detail (formerly Questline detail)
    GoRoute(
      path: '/quest/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return QuestlineDetailScreen(questlineId: id);
      },
    ),
    // Backward-compat: /questline/:id -> Quest detail
    GoRoute(
      path: '/questline/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return QuestlineDetailScreen(questlineId: id);
      },
    ),
    GoRoute(
      path: '/achievements',
      builder: (context, state) => const AchievementsScreen(),
    ),
    // Public player profile routes (outside shell to avoid bottom nav)
    GoRoute(
      path: '/player/me',
      builder: (context, state) => const PublicProfileScreen(userId: null),
    ),
    GoRoute(
      path: '/player/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return PublicProfileScreen(userId: id);
      },
    ),
  ],
);
