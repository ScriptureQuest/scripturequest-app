# Scripture Quest - Architecture Plan

## Overview
A mobile app that combines Christian scripture with RPG-style gaming mechanics to help users grow spiritually through gamified Bible engagement. Features a modern dark mode interface with neon accents, smooth animations, and an immersive gamer aesthetic.

## Design System
- **Theme**: Dark mode with neon accents (cyan, purple, green)
- **Aesthetic**: Modern RPG/gaming interface with cyberpunk influences
- **Typography**: Bold, readable fonts (Orbitron for titles, Rajdhani for body)
- **Colors**: Deep dark backgrounds (#0A0E1A, #121620) with vibrant neon accents
- **Animations**: Smooth transitions, level-up effects, streak celebrations

## Data Models (lib/models/)

### 1. User Model
- id, username, email, avatarUrl
- currentLevel, currentXP, totalXP
- streakDays, longestStreak
- achievements (list of achievement IDs)
- completedVerses, completedQuests
- created_at, updated_at

### 2. Verse Model
- id, reference (book, chapter, verse)
- text, category (faith, love, strength, wisdom, courage)
- xpReward, difficulty
- isCompleted, completedAt
- notes (user's personal notes)
- created_at, updated_at

### 3. Quest Model
- id, title, description
- type (daily, weekly, challenge)
- targetCount, currentProgress
- xpReward, status (active, completed, expired)
- startDate, endDate
- created_at, updated_at

### 4. Achievement Model
- id, title, description, iconName
- category, tier (bronze, silver, gold, legendary)
- requirement, progress, isUnlocked
- unlockedAt, created_at, updated_at

### 5. DailyReflection Model
- id, userId, date
- verseId, reflectionText
- mood (inspired, grateful, hopeful, peaceful)
- created_at, updated_at

## Service Classes (lib/services/)

### 1. UserService
- getCurrentUser(), updateUser()
- addXP(amount), levelUp()
- updateStreak(), checkStreakStatus()
- unlockAchievement(achievementId)
- CRUD operations with local storage

### 2. VerseService
- getAllVerses(), getVersesByCategory()
- getDailyVerse(), getRandomVerse()
- completeVerse(verseId), saveNote(verseId, note)
- Sample data: 50+ popular Bible verses with categories
- CRUD operations with local storage

### 3. QuestService
- getActiveQuests(), getQuestsByType()
- createDailyQuests(), updateQuestProgress()
- completeQuest(questId), expireOldQuests()
- Sample data: variety of quest types
- CRUD operations with local storage

### 4. AchievementService
- getAllAchievements(), getUnlockedAchievements()
- checkAndUnlockAchievements()
- getAchievementProgress(achievementId)
- Sample data: 20+ achievements
- CRUD operations with local storage

### 5. ReflectionService
- saveReflection(reflection), getTodayReflection()
- getReflectionsByDateRange(), deleteReflection()
- CRUD operations with local storage

### 6. StorageService
- Generic local storage wrapper using shared_preferences
- save(), get(), delete(), clear()
- Handles JSON serialization/deserialization

## Screens (lib/screens/)

### 1. Home Screen (Dashboard)
- User profile card: level, XP bar, avatar
- Daily streak tracker with flame animation
- Today's verse card with neon glow
- Quick stats: completed verses, active quests
- Bottom navigation

### 2. Verses Screen
- Category tabs: All, Faith, Love, Strength, Wisdom, Courage
- Verse cards with difficulty badges
- Tap to read full verse and mark complete
- Search and filter options
- XP reward display

### 3. Quests Screen
- Three sections: Daily, Weekly, Challenges
- Quest cards with progress bars
- Quest type icons and XP rewards
- Completion animation
- Auto-refresh daily quests

### 4. Achievements Screen
- Grid layout with achievement tiles
- Locked/unlocked states with visual distinction
- Tier badges (bronze, silver, gold, legendary)
- Progress tracking for incomplete achievements
- Celebration animation on unlock

### 5. Profile Screen
- User stats overview
- Level progression chart
- Streak calendar
- Recent achievements showcase
- Settings and preferences
- Edit profile option

### 6. Verse Detail Screen
- Full verse display with reference
- Complete button with XP reward
- Personal notes section
- Share functionality
- Related verses suggestions

### 7. Reflection Screen
- Create daily reflection
- Verse selection
- Text input for thoughts
- Mood selector
- View past reflections

## Navigation Structure
- Bottom Navigation Bar (4 tabs):
  - Home (dashboard icon)
  - Verses (book icon)
  - Quests (target icon)
  - Profile (user icon)
- Modal routes for:
  - Verse detail
  - Achievement detail
  - Create reflection
  - Quest completion celebration

## Business Logic

### Level & XP System
- XP required for next level: level * 100
- XP sources: completing verses, finishing quests, maintaining streaks, unlocking achievements
- Level-up triggers animation and unlocks new features

### Streak System
- Daily streak increments when user completes any verse
- Streak resets if user misses a day
- Bonus XP for 7-day, 30-day, 100-day streaks
- Visual flame indicator grows with streak

### Quest System
- Daily quests auto-generate at midnight
- Weekly quests refresh every Monday
- Challenges are permanent until completed
- Progress tracked automatically based on user actions
- Auto-complete when target reached

### Achievement System
- Background checking after each user action
- Categories: Streaks, Verses, Quests, Levels
- Progressive unlocking (must complete tier 1 before tier 2)
- Special legendary achievements for major milestones

### Sample Data
- 50+ Bible verses across 5 categories
- 15+ quest templates
- 20+ achievements
- 5 user stats to track
- All stored in local storage

## Key Features
1. **Gamification**: XP, levels, achievements, quests
2. **Daily Engagement**: Streaks, daily verses, daily quests
3. **Personalization**: Notes, reflections, mood tracking
4. **Progress Tracking**: Stats, charts, history
5. **Modern UI**: Dark mode, neon accents, smooth animations
6. **Offline-First**: All data stored locally

## Implementation Steps
1. ✅ Setup theme with dark mode + neon colors
2. ✅ Create all data models with local storage
3. ✅ Implement service layer with sample data
4. ✅ Build Home screen with dashboard
5. ✅ Build Verses screen with categories
6. ✅ Build Quests screen with progress tracking
7. ✅ Build Achievements screen with unlock animations
8. ✅ Build Profile screen with stats
9. ✅ Build Verse Detail screen
10. ✅ Build Reflection screen
11. ✅ Implement navigation with bottom bar
12. ✅ Add level-up and achievement animations
13. ✅ Test all features and fix bugs
14. ✅ Run compile_project to ensure no errors
