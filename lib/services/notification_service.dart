import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// NotificationService: Singleton wrapper around FlutterLocalNotificationsPlugin
/// - Provides scheduling for daily reminder, streak protection, and weekly summary
/// - Uses a single channel across Android
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Notification IDs per requirement
  static const int _dailyReminderId = 1;
  static const int _streakProtectionId = 2;
  static const int _weeklySummaryId = 3;

  static const String _channelId = 'faithquest_notifications';
  static const String _channelName = 'Scripture Quest™ Notifications';
  static const String _channelDescription =
      'Spiritual reminders to stay engaged with God’s Word.';

  AndroidNotificationDetails get _androidDetails => const AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

  DarwinNotificationDetails get _iosDetails => const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

  NotificationDetails get _platformDetails => NotificationDetails(
        android: _androidDetails,
        iOS: _iosDetails,
      );

  Future<void> init() async {
    if (_initialized) return;
    try {
      // Initialize timezone database for zoned scheduling
      tz.initializeTimeZones();
      // Do not force-set local location; tz.local should map appropriately on devices.

      const AndroidInitializationSettings androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const InitializationSettings initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      await _plugin.initialize(
        initSettings,
      );

      // Explicitly create the Android notification channel (Android 8+)
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
        ));
      }

      _initialized = true;
    } catch (e, st) {
      debugPrint('NotificationService.init error: $e\n$st');
    }
  }

  Future<void> requestPermissions() async {
    try {
      // iOS/macOS
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      await _plugin
          .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      // Android 13+
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e, st) {
      debugPrint('NotificationService.requestPermissions error: $e\n$st');
    }
  }

  Future<void> scheduleDailyReminder(int hour, int minute) async {
    try {
      await init();
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        _dailyReminderId,
        'Your Daily Scripture Awaits ⚡',
        'Open Scripture Quest™ to read today’s verse and grow in God’s Word.',
        scheduled,
        _platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e, st) {
      debugPrint('NotificationService.scheduleDailyReminder error: $e\n$st');
    }
  }

  Future<void> cancelDailyReminder() async {
    try {
      await _plugin.cancel(_dailyReminderId);
    } catch (e, st) {
      debugPrint('NotificationService.cancelDailyReminder error: $e\n$st');
    }
  }

  Future<void> scheduleStreakProtection() async {
    try {
      await init();
      const int hour = 20; // 8 PM local time
      const int minute = 0;
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        _streakProtectionId,
        'Protect Your Scripture Streak 🔥',
        'Don’t lose your streak—take a moment to read and reflect.',
        scheduled,
        _platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e, st) {
      debugPrint('NotificationService.scheduleStreakProtection error: $e\n$st');
    }
  }

  Future<void> cancelStreakProtection() async {
    try {
      await _plugin.cancel(_streakProtectionId);
    } catch (e, st) {
      debugPrint('NotificationService.cancelStreakProtection error: $e\n$st');
    }
  }

  Future<void> scheduleWeeklySummary() async {
    try {
      await init();
      // Schedule for Sunday 9:00 AM local time
      const targetWeekday = DateTime.sunday; // 7
      const targetHour = 9;
      const targetMinute = 0;

      final now = tz.TZDateTime.now(tz.local);
      int daysUntil(int weekday) {
        final today = now.weekday; // 1..7
        int diff = (weekday - today) % 7;
        if (diff < 0) diff += 7;
        return diff == 0 ? 7 : diff; // ensure future occurrence
      }

      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        targetHour,
        targetMinute,
      );

      // Move to the next target weekday
      final d = daysUntil(targetWeekday);
      scheduled = scheduled.add(Duration(days: d));

      await _plugin.zonedSchedule(
        _weeklySummaryId,
        'Your Weekly Faith Summary ✨',
        'See how you’ve leveled up your faith this week in Scripture Quest™.',
        scheduled,
        _platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e, st) {
      debugPrint('NotificationService.scheduleWeeklySummary error: $e\n$st');
    }
  }

  Future<void> cancelWeeklySummary() async {
    try {
      await _plugin.cancel(_weeklySummaryId);
    } catch (e, st) {
      debugPrint('NotificationService.cancelWeeklySummary error: $e\n$st');
    }
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e, st) {
      debugPrint('NotificationService.cancelAll error: $e\n$st');
    }
  }
}
