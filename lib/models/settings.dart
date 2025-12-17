import 'package:flutter/foundation.dart';

/// Reader color schemes for the Bible reader area
/// Stored as strings in Settings.bibleReaderTheme for persistence/back-compat.
enum ReaderColorScheme { paper, sepia, night }

/// Reader font styles for the Bible reader area only
/// Stored as strings in Settings.bibleReaderFontStyle for persistence/back-compat.
enum ReaderFontStyle { classicSerif, cleanSans }

/// Reader text sizes for the Bible reader area only
/// Stored as strings in Settings.bibleReaderTextSize for persistence/back-compat.
enum ReaderTextSize { small, medium, large }

class Settings {
  final bool notificationsEnabled;
  final bool dailyReminderEnabled;
  final bool streakProtectionReminderEnabled;
  final bool weeklySummaryEnabled;
  final String themeMode; // "dark" | "light" | "system"
  final bool scripturePopupsEnabled;
  // Bible rendering preferences
  final bool redLettersEnabled; // Show Jesus' words in red (KJV Gospels + Acts 1)
  final int dailyReminderHour;
  final int dailyReminderMinute;
  // Reader preferences
  final double bibleFontScale; // 0.8 - 1.6, default 1.0
  final String bibleReaderTheme; // e.g., "paper" (default)
  // Reader font style (scoped to Bible area only)
  final String bibleReaderFontStyle; // e.g., "classicSerif" (default)
  // Reader text size (scoped to Bible area only)
  final String bibleReaderTextSize; // e.g., "medium" (default)
  // Quiz preferences
  final String preferredQuizDifficulty; // quick | standard | deep

  // Personalized onboarding (v1.0)
  // Store as simple strings for forward-compatibility and easy defaults
  final String bibleExperienceLevel; // beginner | gettingTheHang | comfortable | '' (default)
  final String guidanceLevel; // gentle | someStructure | fullGuidance | ''
  final String mainGoal; // peace | consistency | learning | closerToJesus | ''
  final String dailyRhythmStyle; // short | fiveMinutes | unstructured | ''
  final String rpgComfort; // yes | little | simple | ''
  final String preferredReminderTime; // morning | afternoon | evening | none | ''
  final bool hasCompletedPersonalizedSetup; // default false
  final bool hasCompletedQuickTour; // default false

  const Settings({
    required this.notificationsEnabled,
    required this.dailyReminderEnabled,
    required this.streakProtectionReminderEnabled,
    required this.weeklySummaryEnabled,
    required this.themeMode,
    required this.scripturePopupsEnabled,
    required this.redLettersEnabled,
    required this.dailyReminderHour,
    required this.dailyReminderMinute,
    required this.bibleFontScale,
    required this.bibleReaderTheme,
    required this.bibleReaderFontStyle,
    required this.bibleReaderTextSize,
    required this.preferredQuizDifficulty,
    required this.bibleExperienceLevel,
    required this.guidanceLevel,
    required this.mainGoal,
    required this.dailyRhythmStyle,
    required this.rpgComfort,
    required this.preferredReminderTime,
    required this.hasCompletedPersonalizedSetup,
    required this.hasCompletedQuickTour,
  });

  factory Settings.defaults() => const Settings(
        notificationsEnabled: true,
        dailyReminderEnabled: false,
        streakProtectionReminderEnabled: true,
        weeklySummaryEnabled: true,
        themeMode: 'dark',
        scripturePopupsEnabled: true,
        redLettersEnabled: true,
        dailyReminderHour: 20,
        dailyReminderMinute: 0,
        bibleFontScale: 1.3,
        bibleReaderTheme: 'paper',
        bibleReaderFontStyle: 'classicSerif',
        bibleReaderTextSize: 'medium',
        preferredQuizDifficulty: 'standard',
        bibleExperienceLevel: '',
        guidanceLevel: '',
        mainGoal: '',
        dailyRhythmStyle: '',
        rpgComfort: '',
        preferredReminderTime: '',
        hasCompletedPersonalizedSetup: false,
        hasCompletedQuickTour: false,
      );

  Settings copyWith({
    bool? notificationsEnabled,
    bool? dailyReminderEnabled,
    bool? streakProtectionReminderEnabled,
    bool? weeklySummaryEnabled,
    String? themeMode,
    bool? scripturePopupsEnabled,
    bool? redLettersEnabled,
    int? dailyReminderHour,
    int? dailyReminderMinute,
    double? bibleFontScale,
    String? bibleReaderTheme,
    String? bibleReaderFontStyle,
    String? bibleReaderTextSize,
    String? preferredQuizDifficulty,
    String? bibleExperienceLevel,
    String? guidanceLevel,
    String? mainGoal,
    String? dailyRhythmStyle,
    String? rpgComfort,
    String? preferredReminderTime,
    bool? hasCompletedPersonalizedSetup,
    bool? hasCompletedQuickTour,
  }) {
    return Settings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      streakProtectionReminderEnabled:
          streakProtectionReminderEnabled ?? this.streakProtectionReminderEnabled,
      weeklySummaryEnabled: weeklySummaryEnabled ?? this.weeklySummaryEnabled,
      themeMode: themeMode ?? this.themeMode,
      scripturePopupsEnabled: scripturePopupsEnabled ?? this.scripturePopupsEnabled,
      redLettersEnabled: redLettersEnabled ?? this.redLettersEnabled,
      dailyReminderHour: dailyReminderHour ?? this.dailyReminderHour,
      dailyReminderMinute: dailyReminderMinute ?? this.dailyReminderMinute,
      bibleFontScale: bibleFontScale ?? this.bibleFontScale,
      bibleReaderTheme: bibleReaderTheme ?? this.bibleReaderTheme,
      bibleReaderFontStyle: bibleReaderFontStyle ?? this.bibleReaderFontStyle,
      bibleReaderTextSize: bibleReaderTextSize ?? this.bibleReaderTextSize,
      preferredQuizDifficulty: preferredQuizDifficulty ?? this.preferredQuizDifficulty,
      bibleExperienceLevel: bibleExperienceLevel ?? this.bibleExperienceLevel,
      guidanceLevel: guidanceLevel ?? this.guidanceLevel,
      mainGoal: mainGoal ?? this.mainGoal,
      dailyRhythmStyle: dailyRhythmStyle ?? this.dailyRhythmStyle,
      rpgComfort: rpgComfort ?? this.rpgComfort,
      preferredReminderTime: preferredReminderTime ?? this.preferredReminderTime,
      hasCompletedPersonalizedSetup:
          hasCompletedPersonalizedSetup ?? this.hasCompletedPersonalizedSetup,
      hasCompletedQuickTour: hasCompletedQuickTour ?? this.hasCompletedQuickTour,
    );
  }

  Map<String, dynamic> toJson() => {
        'notificationsEnabled': notificationsEnabled,
        'dailyReminderEnabled': dailyReminderEnabled,
        'streakProtectionReminderEnabled': streakProtectionReminderEnabled,
        'weeklySummaryEnabled': weeklySummaryEnabled,
        'themeMode': themeMode,
        'scripturePopupsEnabled': scripturePopupsEnabled,
        'redLettersEnabled': redLettersEnabled,
        'dailyReminderHour': dailyReminderHour,
        'dailyReminderMinute': dailyReminderMinute,
        'bibleFontScale': bibleFontScale,
        'bibleReaderTheme': bibleReaderTheme,
        'bibleReaderFontStyle': bibleReaderFontStyle,
        'bibleReaderTextSize': bibleReaderTextSize,
        'preferredQuizDifficulty': preferredQuizDifficulty,
        'bibleExperienceLevel': bibleExperienceLevel,
        'guidanceLevel': guidanceLevel,
        'mainGoal': mainGoal,
        'dailyRhythmStyle': dailyRhythmStyle,
        'rpgComfort': rpgComfort,
        'preferredReminderTime': preferredReminderTime,
        'hasCompletedPersonalizedSetup': hasCompletedPersonalizedSetup,
        'hasCompletedQuickTour': hasCompletedQuickTour,
      };

  factory Settings.fromJson(Map<String, dynamic> json) {
    try {
      // Safely parse reader prefs with sane defaults
      final Object? rawScale = json['bibleFontScale'];
      double parsedScale;
      if (rawScale is num) {
        parsedScale = rawScale.toDouble();
      } else if (rawScale is String) {
        parsedScale = double.tryParse(rawScale) ?? 1.0;
      } else {
        parsedScale = 1.0;
      }
      if (parsedScale < 0.8) parsedScale = 1.0;
      if (parsedScale > 1.6) parsedScale = 1.0;
      final String readerTheme = (json['bibleReaderTheme'] as String?)?.trim().isNotEmpty == true
          ? (json['bibleReaderTheme'] as String)
          : 'paper';
      final String readerFontStyle =
          (json['bibleReaderFontStyle'] as String?)?.trim().isNotEmpty == true
              ? (json['bibleReaderFontStyle'] as String)
              : 'classicSerif';
      final String readerTextSize =
          (json['bibleReaderTextSize'] as String?)?.trim().isNotEmpty == true
              ? (json['bibleReaderTextSize'] as String)
              : 'medium';

      return Settings(
        notificationsEnabled: (json['notificationsEnabled'] as bool?) ?? true,
        dailyReminderEnabled: (json['dailyReminderEnabled'] as bool?) ?? false,
        streakProtectionReminderEnabled:
            (json['streakProtectionReminderEnabled'] as bool?) ?? true,
        weeklySummaryEnabled: (json['weeklySummaryEnabled'] as bool?) ?? true,
        themeMode: (json['themeMode'] as String?) ?? 'dark',
        scripturePopupsEnabled: (json['scripturePopupsEnabled'] as bool?) ?? true,
        redLettersEnabled: (json['redLettersEnabled'] as bool?) ?? true,
        dailyReminderHour: (json['dailyReminderHour'] as int?) ?? 20,
        dailyReminderMinute: (json['dailyReminderMinute'] as int?) ?? 0,
        bibleFontScale: parsedScale,
        bibleReaderTheme: readerTheme,
        bibleReaderFontStyle: readerFontStyle,
        bibleReaderTextSize: readerTextSize,
        preferredQuizDifficulty: (json['preferredQuizDifficulty'] as String?) ?? 'standard',
        bibleExperienceLevel: (json['bibleExperienceLevel'] as String?) ?? '',
        guidanceLevel: (json['guidanceLevel'] as String?) ?? '',
        mainGoal: (json['mainGoal'] as String?) ?? '',
        dailyRhythmStyle: (json['dailyRhythmStyle'] as String?) ?? '',
        rpgComfort: (json['rpgComfort'] as String?) ?? '',
        preferredReminderTime: (json['preferredReminderTime'] as String?) ?? '',
        hasCompletedPersonalizedSetup:
            (json['hasCompletedPersonalizedSetup'] as bool?) ?? false,
        hasCompletedQuickTour: (json['hasCompletedQuickTour'] as bool?) ?? false,
      );
    } catch (e) {
      debugPrint('Settings.fromJson error: $e');
      return Settings.defaults();
    }
  }
}
