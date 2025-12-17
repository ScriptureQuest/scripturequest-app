# Scripture Quest

## Overview
Scripture Quest is a Flutter web application designed to integrate Christian scripture engagement with RPG-style mechanics. It aims to deepen users' spiritual journeys through daily reading tasks, quests, and gentle challenges, fostering consistent interaction with biblical texts. The project envisions a future where spiritual growth is gamified and engaging, appealing to a broad audience seeking meaningful interaction with scripture.

## User Preferences
I prefer detailed explanations and an iterative development approach. Please ask before making major changes. Do not make changes to the `android/` and `ios/` folders.

## System Architecture
The application is built with Flutter 3.32.0 and Dart 3.8.0, utilizing the Provider package for state management and `go_router` for navigation. The UI/UX prioritizes a calm, intentional design with normalized spacing and consistent tap affordances.

### Key Features
- **Daily Engagement:** Daily verse of the day and scripture reading tasks.
- **Gamified Progression:** Quest/task system, achievements, and progression tracking.
- **Personalization:** Journaling, bookmarks, and customizable reader preferences (reading style, font, text size, red letters toggle).
- **Interactive Learning:** Mini-games like matching and scramble, and chapter quizzes (for specific chapters like John 3, Romans 8, Psalm 23, Proverbs 3, Luke 2).
- **Navigation & Accessibility:** Unified Bible Menu for all controls, robust reference parsing for navigation, and haptic feedback for mobile users.
- **Quest System:**
    - Quest Hub acts as the primary landing page, featuring filtered quests (Today/Tonight for action quests, Reflection for reflective prompts, Weekly, Events).
    - Quests have specific targets (e.g., `targetBook`, `scriptureReference`) for accurate completion tracking.
    - Strict auto-progress rules: only `scripture_reading` quests auto-progress upon chapter completion if they match the quest's target.
- **Profile Screen:** Simplified layout focusing on an identity card, journey progress (chapters completed, streak), tools (Journal, Favorites, Settings, Friends), and an expandable "Explore" section for future features.

### Technical Implementations
- **Bible Service:** Enhanced `BibleService` with `parseReference()`, `normalizeBookName()`, and `getVerseText()` for robust scripture parsing and multi-translation support.
- **Chapter Completion:** Eligibility for chapter completion requires a minimum presence (12s) and engagement (e.g., scrolling, read time), with visual countdowns for pending eligibility.
- **State Management:** Provider for managing application state.
- **Routing:** `go_router` for declarative navigation.
- **Persistent Storage:** `shared_preferences` for local data persistence.
- **Deployment:** Flutter web application served via Python's `http.server`.

## External Dependencies
- **Framework:** Flutter (version 3.32.0)
- **Language:** Dart (version 3.8.0)
- **State Management:** Provider package
- **Routing:** `go_router` package
- **Local Storage:** `shared_preferences` package
- **Web Server:** Python's `http.server` (for local development/serving web build)