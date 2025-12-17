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
- 2025-12-17: Quest Hub as primary home
  - Created new QuestHubScreen as primary landing page (/)
  - Header shows: "Welcome Back, Warrior", Today's Verse (always visible), Continue Reading card
  - Tasks (Daily/Nightly/Reflection) are the main content below header
  - Moved Reading Plans entry to Community screen (first in "Get involved" section)
  - Bottom-left nav tab renamed from "Tasks" to "Quest Hub", routes to "/" 
  - AppBar has no home icon - users return via bottom tab
  - Home screen preserved at /home but not in primary navigation
  
- 2025-12-17: Initial Replit environment setup
  - Installed Flutter via nix packages
  - Configured web build and serving on port 5000
  - Set up release mode build for better performance
