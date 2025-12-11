import 'package:flutter/foundation.dart';
import 'package:level_up_your_faith/models/reward.dart';
import 'package:level_up_your_faith/services/achievement_service.dart';
import 'package:level_up_your_faith/services/inventory_service.dart';
import 'package:level_up_your_faith/services/progress/progress_event.dart';
import 'package:level_up_your_faith/services/reward_service.dart';
import 'package:level_up_your_faith/services/storage_service.dart';
import 'package:level_up_your_faith/services/titles_service.dart';
import 'package:level_up_your_faith/services/user_service.dart';
import 'package:level_up_your_faith/services/user_stats_service.dart';

/// Unified Progress Engine (foundation):
/// - Listens to ProgressEvent
/// - Routes to XP, Achievements, and UserStats (local/offline)
/// - No UI wiring here (RewardToast handled by UI layer later)
class ProgressEngine {
  ProgressEngine._();
  static final ProgressEngine instance = ProgressEngine._();

  // Lazy singletons
  StorageService? _storage;
  UserService? _userService;
  TitlesService? _titlesService;
  InventoryService? _inventoryService;
  RewardService? _rewardService;
  AchievementService? _achievementService;
  UserStatsService? _statsService;

  Future<void> _ensureInit() async {
    if (_storage == null) {
      _storage = await StorageService.getInstance();
    }
    _userService ??= UserService(_storage!);
    _titlesService ??= TitlesService(_storage!);
    _inventoryService ??= InventoryService(_storage!);
    _rewardService ??= RewardService(_userService!, _titlesService!, _inventoryService!);
    _achievementService ??= AchievementService(_storage!);
    _statsService ??= UserStatsService(_storage!);
  }

  /// Public entrypoint.
  Future<void> emit(ProgressEvent event) async {
    await _ensureInit();
    try {
      switch (event.type) {
        case ProgressEventType.chapterCompleted:
          await _handleChapterCompleted(event);
          break;
        case ProgressEventType.chapterQuizStarted:
          await _handleChapterQuizStarted(event);
          break;
        case ProgressEventType.chapterQuizCompleted:
          await _handleChapterQuizCompleted(event);
          break;
        case ProgressEventType.dailyTaskCompleted:
        case ProgressEventType.nightlyTaskCompleted:
        case ProgressEventType.reflectionTaskCompleted:
          await _handleTaskCompleted(event);
          break;
        case ProgressEventType.questStepCompleted:
          await _handleQuestStepCompleted(event);
          break;
        case ProgressEventType.readingPlanDayCompleted:
          await _handleReadingPlanDayCompleted(event);
          break;
        case ProgressEventType.streakDayKept:
        case ProgressEventType.streakBroken:
          await _handleStreakEvent(event);
          break;
      }
    } catch (e) {
      debugPrint('ProgressEngine.emit error: $e');
    }
  }

  // =============== Handlers ===============
  Future<void> _handleChapterCompleted(ProgressEvent e) async {
    try {
      final uid = (await _userService!.getCurrentUser()).id;
      await _statsService!.incChaptersCompleted(uid);
      await _awardXp(10, reason: 'Chapter Completed', source: e.type.name);

      // Achievement suggestions (no UI here). We only unlock known seeds if present later.
      // The richer chapter/book achievements are handled elsewhere in the app currently.
    } catch (err) {
      debugPrint('_handleChapterCompleted error: $err');
    }
  }

  Future<void> _handleChapterQuizStarted(ProgressEvent e) async {
    try {
      // For foundation: we may increment total quizzes started later. No XP award here.
      // left intentionally minimal.
    } catch (err) {
      debugPrint('_handleChapterQuizStarted error: $err');
    }
  }

  Future<void> _handleChapterQuizCompleted(ProgressEvent e) async {
    try {
      final uid = (await _userService!.getCurrentUser()).id;
      await _statsService!.incQuizzesCompleted(uid);
      final passed = (e.payload['passed'] == true);
      if (passed) {
        await _statsService!.incQuizzesPassed(uid);
      }

      final difficulty = (e.payload['difficulty']?.toString() ?? '').toLowerCase();
      int xp = 10; // Quick default
      if (difficulty == 'standard') xp = 15;
      if (difficulty == 'deep') xp = 20;
      await _awardXp(xp, reason: 'Chapter Quiz', source: e.type.name);

      // Example unlock hooks (only if such ids exist in seeds; safe if not present)
      await _unlockIfDefined(uid, 'first_quiz_completed');
      if (passed) await _unlockIfDefined(uid, 'quiz_passed_1');
    } catch (err) {
      debugPrint('_handleChapterQuizCompleted error: $err');
    }
  }

  Future<void> _handleTaskCompleted(ProgressEvent e) async {
    try {
      final uid = (await _userService!.getCurrentUser()).id;
      final t = e.type;
      if (t == ProgressEventType.reflectionTaskCompleted) {
        await _statsService!.incReflectionsCompleted(uid);
        await _awardXp(8, reason: 'Reflection Task', source: t.name);
        // Achievement seed available
        await _unlockIfDefined(uid, 'quiet_reflections_5');
      } else if (t == ProgressEventType.nightlyTaskCompleted) {
        await _statsService!.incTasksCompleted(uid);
        await _awardXp(5, reason: 'Nightly Task', source: t.name);
        await _unlockIfDefined(uid, 'night_scholar_5');
      } else {
        await _statsService!.incTasksCompleted(uid);
        await _awardXp(5, reason: 'Daily Task', source: t.name);
      }
    } catch (err) {
      debugPrint('_handleTaskCompleted error: $err');
    }
  }

  Future<void> _handleQuestStepCompleted(ProgressEvent e) async {
    try {
      final uid = (await _userService!.getCurrentUser()).id;
      await _statsService!.incQuestStepsCompleted(uid);
      await _awardXp(10, reason: 'Quest Step', source: e.type.name);
      await _unlockIfDefined(uid, 'questline_step_1');
    } catch (err) {
      debugPrint('_handleQuestStepCompleted error: $err');
    }
  }

  Future<void> _handleReadingPlanDayCompleted(ProgressEvent e) async {
    try {
      final uid = (await _userService!.getCurrentUser()).id;
      await _statsService!.incReadingPlanDaysCompleted(uid);
      await _awardXp(10, reason: 'Reading Plan Day', source: e.type.name);
    } catch (err) {
      debugPrint('_handleReadingPlanDayCompleted error: $err');
    }
  }

  Future<void> _handleStreakEvent(ProgressEvent e) async {
    try {
      final uid = (await _userService!.getCurrentUser()).id;
      if (e.type == ProgressEventType.streakDayKept) {
        await _statsService!.incStreakDaysKept(uid);
        await _awardXp(3, reason: 'Daily Streak', source: e.type.name);
      } else {
        await _statsService!.incStreakBreaks(uid);
        // no XP for break
      }
    } catch (err) {
      debugPrint('_handleStreakEvent error: $err');
    }
  }

  // =============== Helpers ===============
  Future<void> _awardXp(int amount, {required String reason, required String source}) async {
    try {
      if (amount <= 0) return;
      final reward = Reward(type: RewardTypes.xp, amount: amount, label: '$amount XP');
      await _rewardService!.applyReward(reward, xpOverride: amount);
      // UI toast/animations intentionally omitted here (foundation only).
      debugPrint('ProgressEngine: +$amount XP ($reason) [source=$source]');
    } catch (e) {
      debugPrint('ProgressEngine._awardXp error: $e');
    }
  }

  Future<void> _unlockIfDefined(String uid, String achievementId) async {
    try {
      // Load current list, attempt unlock, and save back if changed.
      final list = await _achievementService!.getAchievementsForUser(uid);
      final unlocked = _achievementService!.unlockIfNeeded(list, achievementId);
      if (unlocked.isNotEmpty) {
        await _achievementService!.saveAchievementsForUser(uid, list);
        debugPrint('ProgressEngine: achievement unlocked "$achievementId"');
      }
    } catch (e) {
      debugPrint('ProgressEngine._unlockIfDefined error: $e');
    }
  }
}
