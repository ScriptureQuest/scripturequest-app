# Scripture Quest

## Overview
Scripture Quest is a Flutter web application that blends Christian scripture with engaging RPG-style mechanics. Users can deepen their spiritual journey through daily reading tasks, quests, and gentle challenges.

## Project Structure
- `lib/` - Flutter/Dart source code
  - `main.dart` - Application entry point with routing
  - `screens/` - UI screens (home, quests, profile, etc.)
  - `services/` - Business logic services
  - `models/` - Data models
  - `providers/` - State management with Provider
  - `widgets/` - Reusable UI components
  - `theme/` - App theming
- `assets/` - Static assets (Bible data, images, icons)
- `web/` - Web-specific files (index.html, manifest.json)
- `android/` - Android platform files
- `ios/` - iOS platform files

## Technologies
- **Framework**: Flutter 3.32.0
- **Language**: Dart 3.8.0
- **State Management**: Provider
- **Routing**: go_router
- **Storage**: shared_preferences

## Running the App
The app runs as a Flutter web application on port 5000. The workflow:
1. Builds the Flutter web app in release mode
2. Serves the static files using Python's http.server

## Key Features
- Daily verse of the day
- Scripture reading and memorization
- Quest/task system for engagement
- Achievements and progression
- Journal and bookmarks
- Mini-games (matching, scramble, etc.)

## Recent Changes
- 2025-12-17: Today's Verse actual text display (v2.9)
  - Fixed VOTD to show actual verse text using robust reference parsing
  - BibleService enhanced with:
    - parseReference() now extracts book, chapter, verse, and verseEnd
    - normalizeBookName() handles aliases (Psalm/Psalms, Song of Songs, Revelations)
    - getVerseText() async lookup with multi-translation support
  - Added 8 common VOTD passages to mock data (John 3:16, 2 Cor 12:9, Prov 3:5-6, etc.)
  - QuestHubScreen uses async state management for VOTD text loading
  - Placeholder "Tap to read this verse" only shown when data truly unavailable
  - No changes to quest generation, XP, streaks, or completion logic

- 2025-12-17: Bottom bar polish + Today's Verse sync (v2.8)
  - Quest Hub icon changed from flag to home icon (Icons.home_outlined)
  - Active tab emphasis: soft pill background + subtle border (already present)
  - Bible and Profile icons unchanged
  - No changes to quest generation, XP, streaks, or completion logic

- 2025-12-17: Simplified navigation + streak visibility (v2.6)
  - Bottom navigation reduced to 3 tabs: Quest Hub, Bible, Profile
  - Avatar and Community removed from bottom bar (accessible from Profile → Explore)
  - Quest Hub header now shows inline streak (🔥 N) on the right when streak >= 1
  - Profile screen gained new "Explore" section with links to:
    - Reading Plans, Avatar & Cosmetics, Community, Play & Learn
  - No changes to quest generation, XP, streak calculations, or Bible reader logic

- 2025-12-17: QuestHub filter wiring fix (v2.5)
  - Fixed filter chips to show mutually exclusive quest lists:
    - Tonight/Today: ONLY action quests (scripture_reading, routine, service, community) from daily/nightly
    - Weekly: ONLY quests marked as weekly (isWeekly, category=weekly, questFrequency=weekly)
    - Reflection: ONLY reflection-type quests (reflection, prayer, journal, gratitude, memorization)
    - Events: ONLY event/seasonal quests
  - Added explicit exclusion filters to prevent weekly/event quests from appearing in daily lists
  - Added isWeeklyQuest() and isEventQuest() helper functions for consistent categorization
  - Debug logging (kDebugMode) prints filter counts when switching tabs
  - No changes to quest generation, XP, streaks, or completion flow

- 2025-12-17: Complete Chapter UX polish (v2.4)
  - Replaced toast-based blocking with live countdown on button:
    - Button shows "Complete (Xs)" countdown when not yet eligible
    - Button automatically enables when countdown reaches 0
    - Disabled button state is visually clear (grayed out)
  - Timer-based updates every second when completion panel is visible
  - No changes to eligibility rules (still 12s presence + engagement)
  - No changes to quest progression, XP, or streaks

- 2025-12-17: Core loop reliability fixes (v2.3)
  - Complete Chapter now foolproof for fast readers and short chapters:
    - Eligibility requires: 12s minimum presence + engagement (45s read time OR short chapter OR scrolled OR panel visible)
    - Short chapters (≤8 verses) auto-detected and panel shown immediately
    - Toast/snackbar shown when tapped while ineligible with helpful message
    - ScrollStartNotification tracks user interaction for engagement
  - Psalms quest Start navigation improved:
    - If last-read reference is in target book, open that chapter (not always chapter 1)
    - E.g., Psalms quest with lastRef="Psalms 23" → opens Psalms 23
  - Bottom padding increased (90px → 140px) so Complete Chapter never blocks last verses
  - Panel reveal threshold lowered (95% → 92%) for earlier access
  - Cached chapters now also run short chapter detection
  - No XP, rewards, or quest logic changes

- 2025-12-17: Nightly quest completion + Psalms targeting fixes (v2 wiring fix)
  - Added targetBook field to TaskModel for book-level targeting without exact reference
  - Nightly quest templates updated:
    - "Nightly Reading" (generic): questType=scripture_reading, no target → any chapter completes
    - "Read a calming Psalm before bed": questType=scripture_reading, targetBook=Psalms → only Psalms chapters complete
    - "Read a verse about God's protection": questType=scripture_reading, targetBook=Psalms
  - Start button navigation now uses priority: scriptureReference > targetBook > lastBibleReference
  - QuestProgressService passes q.targetBook to matchesQuestTarget()
  - Fixed chapter completion wiring:
    - progressDailyReadingQuest now accepts book/chapter params
    - Calls QuestProgressService.handleEvent with correct signature (event:, payload:, callbacks:)
    - verses_screen.dart passes _selectedBook/_selectedChapter on Complete Chapter
  - Fixed quest callback wiring:
    - onApplyProgress/onMarkComplete now call TaskService methods (not Quest Board)
    - TaskService.updateQuestProgress and completeQuest properly update TaskModel quests in storage
  - Quest migration system added (v2):
    - _questMigrationVersion = 2 forces daily/nightly quest regeneration
    - createDailyQuests now also clears old nightly quests before regenerating
    - Ensures targetBook metadata is applied to nightly quests
  - Debug-only logging added (kDebugMode gated):
    - QuestHubScreen: logs rendered quests with targetBook/scriptureRef metadata
    - TaskCard.Start: logs quest metadata before navigation
    - AppProvider: logs book/chapter on quest progress
  - No XP, rewards, or UI layout changes

- 2025-12-17: Quest correctness system v2.1 (safety refinements)
  - Priority-based scripture detection in matchesQuestTarget():
    - A) scriptureReference → source of truth
    - B) allowedBooks/targetBook metadata → when available
    - C) title keyword detection → fallback (e.g., "Psalm")
  - Routine quest triggers explicitly documented:
    - onBibleOpened: Opening Bible tab (primary trigger)
    - onReadingTimerComplete: Reading timer threshold met
    - onChapterComplete: NOT a trigger for routine quests
  - Debug logging gated by kDebugMode (auto-disabled in release builds)
  - Start button safety guarantee:
    - Every quest type resolves to a non-null action
    - Unknown types fallback to Details sheet
    - Defensive warning logged in debug builds
  - No XP, quest generation, or backend logic changes

- 2025-12-17: Quest Start navigation + strict auto-progress rules
  - Start button now navigates based on quest type:
    - scripture_reading → Bible reader at quest target (or last-read reference)
    - reflection/journal/prayer → Journal screen
    - memorization → Favorites/Memorization screen
    - service/community → Details sheet (manual completion)
    - routine → Bible reader
  - Strict matching in QuestProgressService for onChapterComplete:
    - Only scripture_reading quests auto-progress from chapter completion
    - Must match quest's target book/chapter exactly
    - Psalm quests only credit Psalms book completions
    - Debug logging added with [QuestProgress] prefix
  - No XP/backend logic changes

- 2025-12-17: Quest Hub action/reflection separation + sticky chips
  - Today/Tonight filter shows ONLY action quests (scripture_reading, routine, service, community)
  - Reflection filter shows ONLY reflective prompts (reflection, prayer, journal, gratitude, memorization)
  - Filter chips are sticky (pinned) while scrolling the quest list via NestedScrollView + SliverPersistentHeader
  - Weekly and Events filters unchanged
  - Classification logic: `_isActionQuest()` and `_isReflectionQuest()` helpers in QuestHubScreen
  - No XP or backend logic changes - presentation only

- 2025-12-17: Quest Hub as primary home
  - QuestHubScreen is primary landing page at /
  - Bottom-left nav tab renamed from "Tasks" to "Quest Hub"
  - Home screen preserved at /home but not in primary navigation
  - Moved Reading Plans to Community screen
  
- 2025-12-17: Initial Replit environment setup
  - Installed Flutter via nix packages
  - Configured web build and serving on port 5000
  - Set up release mode build for better performance
