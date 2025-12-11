import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:level_up_your_faith/models/settings.dart';
import 'package:level_up_your_faith/services/settings_service.dart';
import 'package:level_up_your_faith/models/quiz_difficulty.dart';
import 'package:level_up_your_faith/services/notification_service.dart';

class SettingsProvider extends ChangeNotifier {
  Settings _settings = Settings.defaults();
  late final SettingsService _service;
  bool _loaded = false;

  bool get isLoaded => _loaded;
  Settings get settings => _settings;
  
  // Reader prefs getters
  double get bibleFontScale => _settings.bibleFontScale;
  String get bibleReaderTheme => _settings.bibleReaderTheme;
  bool get redLettersEnabled => _settings.redLettersEnabled;
  // Typed font style getter
  ReaderFontStyle get readerFontStyle {
    switch ((_settings.bibleReaderFontStyle).toLowerCase()) {
      case 'cleansans':
        return ReaderFontStyle.cleanSans;
      case 'classicserif':
      default:
        return ReaderFontStyle.classicSerif;
    }
  }

  // Typed reader text size getter
  ReaderTextSize get readerTextSize {
    switch ((_settings.bibleReaderTextSize).toLowerCase()) {
      case 'small':
        return ReaderTextSize.small;
      case 'large':
        return ReaderTextSize.large;
      case 'medium':
      default:
        return ReaderTextSize.medium;
    }
  }

  // Quiz difficulty preference
  QuizDifficulty get preferredQuizDifficulty => QuizDifficultyHelpers.fromCode(_settings.preferredQuizDifficulty);

  Future<void> setPreferredQuizDifficulty(QuizDifficulty value) async {
    _settings = _settings.copyWith(preferredQuizDifficulty: value.code);
    await _service.save(_settings);
    notifyListeners();
  }

  // Map text size to an effective font scale (kept for legacy sites using bibleFontScale)
  double _scaleFor(ReaderTextSize size) {
    switch (size) {
      case ReaderTextSize.small:
        return 0.9;
      case ReaderTextSize.large:
        return 1.15;
      case ReaderTextSize.medium:
      default:
        return 1.0;
    }
  }

  // Typed reader color scheme mapping for convenience
  ReaderColorScheme get readerColorScheme {
    switch ((_settings.bibleReaderTheme).toLowerCase()) {
      case 'sepia':
        return ReaderColorScheme.sepia;
      case 'night':
        return ReaderColorScheme.night;
      case 'paper':
      default:
        return ReaderColorScheme.paper;
    }
  }

  Future<void> initialize() async {
    _service = await SettingsService.getInstance();
    _settings = await _service.load();
    _loaded = true;
    // Initialize notifications and request permissions if enabled, then resync
    try {
      await NotificationService.instance.init();
      if (_settings.notificationsEnabled) {
        await NotificationService.instance.requestPermissions();
        await resyncNotifications();
      }
    } catch (e, st) {
      debugPrint('SettingsProvider.initialize notifications error: $e\n$st');
    }
    notifyListeners();
  }

  // Theme mode conversions
  ThemeMode get themeMode {
    switch (_settings.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }

  Future<void> setThemeMode(String mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    await _service.save(_settings);
    notifyListeners();
  }

  Future<void> setBibleFontScale(double scale) async {
    final double clamped = scale.clamp(0.8, 1.6).toDouble();
    _settings = _settings.copyWith(bibleFontScale: clamped);
    await _service.save(_settings);
    notifyListeners();
  }

  Future<void> setBibleReaderTheme(String theme) async {
    _settings = _settings.copyWith(bibleReaderTheme: theme);
    await _service.save(_settings);
    notifyListeners();
  }

  Future<void> setReaderColorScheme(ReaderColorScheme scheme) async {
    await setBibleReaderTheme(scheme.name);
  }

  Future<void> setReaderFontStyle(ReaderFontStyle style) async {
    _settings = _settings.copyWith(bibleReaderFontStyle: style.name);
    await _service.save(_settings);
    notifyListeners();
  }

  // New: set Bible reader text size; also update the legacy numeric scale for immediate effect
  Future<void> setReaderTextSize(ReaderTextSize size) async {
    final scale = _scaleFor(size).clamp(0.8, 1.6).toDouble();
    _settings = _settings.copyWith(
      bibleReaderTextSize: size.name,
      bibleFontScale: scale,
    );
    await _service.save(_settings);
    notifyListeners();
  }

  Future<void> setRedLettersEnabled(bool value) async {
    _settings = _settings.copyWith(redLettersEnabled: value);
    await _service.save(_settings);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _settings = _settings.copyWith(notificationsEnabled: value);
    await _service.save(_settings);
    // If enabling, request permissions first
    if (value) {
      await NotificationService.instance.init();
      await NotificationService.instance.requestPermissions();
    }
    await resyncNotifications();
    notifyListeners();
  }

  Future<void> setDailyReminderEnabled(bool value) async {
    _settings = _settings.copyWith(dailyReminderEnabled: value);
    await _service.save(_settings);
    await resyncNotifications();
    notifyListeners();
  }

  Future<void> setStreakProtectionReminderEnabled(bool value) async {
    _settings = _settings.copyWith(streakProtectionReminderEnabled: value);
    await _service.save(_settings);
    await resyncNotifications();
    notifyListeners();
  }

  Future<void> setWeeklySummaryEnabled(bool value) async {
    _settings = _settings.copyWith(weeklySummaryEnabled: value);
    await _service.save(_settings);
    await resyncNotifications();
    notifyListeners();
  }

  Future<void> setScripturePopupsEnabled(bool value) async {
    _settings = _settings.copyWith(scripturePopupsEnabled: value);
    await _service.save(_settings);
    notifyListeners();
  }

  Future<void> setDailyReminderTime({required int hour, required int minute}) async {
    _settings = _settings.copyWith(dailyReminderHour: hour, dailyReminderMinute: minute);
    await _service.save(_settings);
    await resyncNotifications();
    notifyListeners();
  }

  Future<void> resyncNotifications() async {
    // If master notifications are disabled, cancel everything and return.
    if (!_settings.notificationsEnabled) {
      await NotificationService.instance.cancelAll();
      return;
    }

    // Daily reminder
    if (_settings.dailyReminderEnabled) {
      await NotificationService.instance.scheduleDailyReminder(
        _settings.dailyReminderHour,
        _settings.dailyReminderMinute,
      );
    } else {
      await NotificationService.instance.cancelDailyReminder();
    }

    // Streak protection reminder
    if (_settings.streakProtectionReminderEnabled) {
      await NotificationService.instance.scheduleStreakProtection();
    } else {
      await NotificationService.instance.cancelStreakProtection();
    }

    // Weekly summary
    if (_settings.weeklySummaryEnabled) {
      await NotificationService.instance.scheduleWeeklySummary();
    } else {
      await NotificationService.instance.cancelWeeklySummary();
    }
  }

  // ================= Personalized Onboarding (v1.0) =================
  String get bibleExperienceLevel => _settings.bibleExperienceLevel;
  String get guidanceLevel => _settings.guidanceLevel;
  String get mainGoal => _settings.mainGoal;
  String get dailyRhythmStyle => _settings.dailyRhythmStyle;
  String get rpgComfort => _settings.rpgComfort;
  String get preferredReminderTime => _settings.preferredReminderTime;

  bool get hasCompletedPersonalizedSetup => _settings.hasCompletedPersonalizedSetup;
  bool get hasCompletedQuickTour => _settings.hasCompletedQuickTour;

  Future<void> setBibleExperienceLevel(String value) async {
    _settings = _settings.copyWith(bibleExperienceLevel: value);
    await _service.save(_settings);
    notifyListeners();
  }

  Future<void> setGuidanceLevel(String value) async {
    _settings = _settings.copyWith(guidanceLevel: value);
    await _service.save(_settings);
    notifyListeners();
  }

  Future<void> setMainGoal(String value) async {
    _settings = _settings.copyWith(mainGoal: value);
    await _service.save(_settings);
    notifyListeners();
  }

  Future<void> setDailyRhythmStyle(String value) async {
    _settings = _settings.copyWith(dailyRhythmStyle: value);
    await _service.save(_settings);
    notifyListeners();
  }

  Future<void> setRpgComfort(String value) async {
    _settings = _settings.copyWith(rpgComfort: value);
    await _service.save(_settings);
    notifyListeners();
  }

  Future<void> setPreferredReminderTime(String value) async {
    _settings = _settings.copyWith(preferredReminderTime: value);
    await _service.save(_settings);
    notifyListeners();
  }

  Future<void> onboardingPersonalizedComplete() async {
    _settings = _settings.copyWith(hasCompletedPersonalizedSetup: true);
    await _service.save(_settings);
    notifyListeners();
  }

  Future<void> setHasCompletedQuickTour(bool value) async {
    _settings = _settings.copyWith(hasCompletedQuickTour: value);
    await _service.save(_settings);
    notifyListeners();
  }
}
