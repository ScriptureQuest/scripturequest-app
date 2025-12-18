import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:level_up_your_faith/models/quest_model.dart';
import 'package:level_up_your_faith/models/reward.dart';
import 'package:level_up_your_faith/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class TaskService {
  static const String _storageKey = 'quests';
  static const String _lastDailyGenerationKey = 'last_daily_generation';
  static const String _lastWeeklyGenerationKey = 'last_weekly_generation';
  // Quest history keys for preventing repetition
  static const String _dailyQuestHistoryKey = 'daily_quest_history';
  static const String _weeklyQuestHistoryKey = 'weekly_quest_history';
  static const String _generatedDailyQuestsKey = 'generated_daily_quests';
  static const String _generatedWeeklyQuestsKey = 'generated_weekly_quests';
  // Migration key: bump this version to force quest regeneration when templates change
  static const String _questMigrationKey = 'quest_migration_v';
  static const int _questMigrationVersion = 3; // v3: added quest history for anti-repetition
  final StorageService _storage;
  final _uuid = const Uuid();

  TaskService(this._storage);

  /// Check and run one-time quest migration if needed (e.g., template metadata changed)
  Future<void> _runQuestMigrationIfNeeded() async {
    try {
      final migrationKey = '$_questMigrationKey$_questMigrationVersion';
      final migrated = _storage.getString(migrationKey);
      if (migrated == 'done') return;

      // Clear lastDailyGenerationKey to force regeneration of daily/nightly quests
      // This ensures new targetBook metadata is applied to nightly quests
      await _storage.save(_lastDailyGenerationKey, '');
      await _storage.save(migrationKey, 'done');
      if (kDebugMode) {
        debugPrint('[TaskService] Quest migration v$_questMigrationVersion: forcing daily/nightly quest regeneration');
      }
    } catch (e) {
      debugPrint('Quest migration error: $e');
    }
  }

  // ================== Quest History Management (Anti-Repetition) ==================
  
  /// Get today's date key in YYYY-MM-DD format (local timezone)
  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
  
  /// Get week key in YYYY-WW format (ISO week number, local timezone)
  String _getWeekKey() {
    final now = DateTime.now();
    final weekNumber = _getIsoWeekNumber(now);
    return '${now.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }
  
  /// Calculate ISO week number
  int _getIsoWeekNumber(DateTime date) {
    final dayOfYear = int.parse(date.difference(DateTime(date.year, 1, 1)).inDays.toString()) + 1;
    final woy = ((dayOfYear - date.weekday + 10) / 7).floor();
    if (woy < 1) return _getIsoWeekNumber(DateTime(date.year - 1, 12, 31));
    if (woy > 52) {
      final nextYear = DateTime(date.year + 1, 1, 1);
      if (nextYear.weekday <= 4) return 1;
    }
    return woy;
  }
  
  /// Load quest history for daily quests (Map of dateKey -> List of quest titles)
  Map<String, List<String>> _loadDailyQuestHistory() {
    try {
      final raw = _storage.getString(_dailyQuestHistoryKey);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final result = <String, List<String>>{};
      decoded.forEach((k, v) {
        result[k] = (v as List<dynamic>).cast<String>();
      });
      return result;
    } catch (e) {
      debugPrint('_loadDailyQuestHistory error: $e');
      return {};
    }
  }
  
  /// Save quest history for daily quests (rolling 7 days)
  Future<void> _saveDailyQuestHistory(Map<String, List<String>> history) async {
    try {
      // Prune to last 7 days
      final keys = history.keys.toList()..sort();
      while (keys.length > 7) {
        history.remove(keys.removeAt(0));
      }
      await _storage.save(_dailyQuestHistoryKey, jsonEncode(history));
    } catch (e) {
      debugPrint('_saveDailyQuestHistory error: $e');
    }
  }
  
  /// Load quest history for weekly quests (Map of weekKey -> List of quest titles)
  Map<String, List<String>> _loadWeeklyQuestHistory() {
    try {
      final raw = _storage.getString(_weeklyQuestHistoryKey);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final result = <String, List<String>>{};
      decoded.forEach((k, v) {
        result[k] = (v as List<dynamic>).cast<String>();
      });
      return result;
    } catch (e) {
      debugPrint('_loadWeeklyQuestHistory error: $e');
      return {};
    }
  }
  
  /// Save quest history for weekly quests (rolling 4 weeks)
  Future<void> _saveWeeklyQuestHistory(Map<String, List<String>> history) async {
    try {
      // Prune to last 4 weeks
      final keys = history.keys.toList()..sort();
      while (keys.length > 4) {
        history.remove(keys.removeAt(0));
      }
      await _storage.save(_weeklyQuestHistoryKey, jsonEncode(history));
    } catch (e) {
      debugPrint('_saveWeeklyQuestHistory error: $e');
    }
  }
  
  /// Get all recently used quest titles (daily: last 7 days, fallback to 2 days if pool too small)
  Set<String> _getRecentDailyQuestTitles({int lookbackDays = 7}) {
    try {
      final history = _loadDailyQuestHistory();
      final now = DateTime.now();
      final recent = <String>{};
      for (int i = 1; i <= lookbackDays; i++) {
        final d = now.subtract(Duration(days: i));
        final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        if (history.containsKey(key)) {
          recent.addAll(history[key]!);
        }
      }
      return recent;
    } catch (e) {
      debugPrint('_getRecentDailyQuestTitles error: $e');
      return {};
    }
  }
  
  /// Get all recently used weekly quest titles (last 1-2 weeks)
  Set<String> _getRecentWeeklyQuestTitles({int lookbackWeeks = 1}) {
    try {
      final history = _loadWeeklyQuestHistory();
      final keys = history.keys.toList()..sort();
      final recent = <String>{};
      final takeCount = lookbackWeeks.clamp(1, keys.length);
      for (final key in keys.reversed.take(takeCount)) {
        recent.addAll(history[key]!);
      }
      return recent;
    } catch (e) {
      debugPrint('_getRecentWeeklyQuestTitles error: $e');
      return {};
    }
  }
  
  /// Load saved daily quest IDs for a specific day (returns null if not found)
  List<String>? _loadGeneratedDailyQuestIds(String todayKey) {
    try {
      final raw = _storage.getString(_generatedDailyQuestsKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      if (decoded['dateKey'] != todayKey) return null;
      return (decoded['questIds'] as List<dynamic>?)?.cast<String>();
    } catch (e) {
      debugPrint('_loadGeneratedDailyQuestIds error: $e');
      return null;
    }
  }
  
  /// Save generated daily quest IDs for today
  Future<void> _saveGeneratedDailyQuestIds(String todayKey, List<String> questIds) async {
    try {
      await _storage.save(_generatedDailyQuestsKey, jsonEncode({
        'dateKey': todayKey,
        'questIds': questIds,
      }));
    } catch (e) {
      debugPrint('_saveGeneratedDailyQuestIds error: $e');
    }
  }
  
  /// Load saved weekly quest IDs for a specific week (returns null if not found)
  List<String>? _loadGeneratedWeeklyQuestIds(String weekKey) {
    try {
      final raw = _storage.getString(_generatedWeeklyQuestsKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      if (decoded['weekKey'] != weekKey) return null;
      return (decoded['questIds'] as List<dynamic>?)?.cast<String>();
    } catch (e) {
      debugPrint('_loadGeneratedWeeklyQuestIds error: $e');
      return null;
    }
  }
  
  /// Save generated weekly quest IDs for this week
  Future<void> _saveGeneratedWeeklyQuestIds(String weekKey, List<String> questIds) async {
    try {
      await _storage.save(_generatedWeeklyQuestsKey, jsonEncode({
        'weekKey': weekKey,
        'questIds': questIds,
      }));
    } catch (e) {
      debugPrint('_saveGeneratedWeeklyQuestIds error: $e');
    }
  }

  Future<void> _initializeSampleData() async {
    final quests = _getSampleQuests();
    final jsonList = quests.map((q) => q.toJson()).toList();
    await _storage.save(_storageKey, jsonEncode(jsonList));
  }

  Future<List<TaskModel>> getAllQuests() async {
    try {
      final jsonString = _storage.getString(_storageKey);
      if (jsonString == null) {
        await _initializeSampleData();
        return getAllQuests();
      }
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final quests = <TaskModel>[];
      for (final item in jsonList) {
        try {
          final parsed = TaskModel.fromJson(item as Map<String, dynamic>);
          quests.add(parsed);
        } catch (e) {
          debugPrint('Skipping corrupted quest entry: $e');
        }
      }

      // Sanitize and write back clean data to avoid repeated issues
      bool changed = false;
      final sanitized = quests.map((q) {
        var updated = q;
        // Ensure category and type are non-empty strings
        if (q.category.isEmpty && q.type.isNotEmpty) {
          updated = updated.copyWith(category: q.type);
          changed = true;
        }
        if (updated.category.isEmpty) {
          updated = updated.copyWith(category: 'daily');
          changed = true;
        }
        if (updated.type.isEmpty) {
          updated = updated.copyWith(type: 'daily');
          changed = true;
        }
        if (updated.difficulty.isEmpty) {
          updated = updated.copyWith(difficulty: 'Easy');
          changed = true;
        }
        if (updated.questType.isEmpty) {
          updated = updated.copyWith(questType: 'scripture_reading');
          changed = true;
        }
        if (updated.title.isEmpty || updated.description.isEmpty) {
          // Titles and descriptions are required for UI; fill with placeholders
          updated = updated.copyWith(
            title: updated.title.isEmpty ? 'Untitled Quest' : null,
            description: updated.description.isEmpty ? 'No description provided' : null,
          );
          changed = true;
        }
        return updated;
      }).toList();

      if (changed) {
        debugPrint('Sanitized quest data and writing back to storage');
        await _saveQuests(sanitized);
        return sanitized;
      }

      // Ensure Reflection task seeds are present (idempotent)
      final ensured = await _ensureReflectionSeeds(quests);
      return ensured;
    } catch (e) {
      debugPrint('Error loading quests: $e');
      return [];
    }
  }

  // Add a custom quest to storage (e.g., Streak Recovery Quest)
  Future<void> addQuest(TaskModel quest) async {
    try {
      final quests = await getAllQuests();
      // Ensure id uniqueness
      final exists = quests.any((q) => q.id == quest.id);
      if (exists) {
        debugPrint('addQuest skipped: quest with id ${quest.id} already exists');
        return;
      }
      quests.add(quest);
      await _saveQuests(quests);
    } catch (e) {
      debugPrint('addQuest error: $e');
    }
  }

  Future<List<TaskModel>> getActiveQuests() async {
    final quests = await getAllQuests();
    await expireOldQuests();
    // Active means not started or in progress (not completed/expired)
    return quests.where((q) => q.status == 'not_started' || q.status == 'in_progress').toList();
  }

  Future<List<TaskModel>> getQuestsByCategory(String category, {bool includeCompleted = false}) async {
    final quests = includeCompleted ? await getAllQuests() : await getActiveQuests();
    return quests.where((q) => (q.category) == category).toList();
  }

  Future<void> createDailyQuests() async {
    // Run migration first to ensure fresh templates are used
    await _runQuestMigrationIfNeeded();
    
    final today = DateTime.now();
    final todayKey = _getTodayKey();
    final lastGen = _storage.getString(_lastDailyGenerationKey);
    
    if (kDebugMode) {
      debugPrint('[TaskService] createDailyQuests: todayKey=$todayKey, lastGen=$lastGen');
    }
    
    // Check if we already generated for today
    if (lastGen == todayKey) {
      if (kDebugMode) {
        debugPrint('[TaskService] Daily quests already generated for $todayKey - loading existing');
      }
      return;
    }
    
    final quests = await getAllQuests();
    // Remove old daily and nightly quests that are not completed
    quests.removeWhere((q) => 
      ((q.category == 'daily' || q.isDaily || q.type == 'daily') && q.status != 'completed') ||
      ((q.category == 'nightly' || q.type == 'nightly') && q.status != 'completed')
    );
    
    // Generate new daily quests with history-aware selection
    final newDailyQuests = _generateDailyQuestsWithHistory();
    // Add Nightly tasks (v2.0) with history-aware selection  
    final nightly = _generateNightlyQuestsWithHistory(today);
    
    quests.addAll([...newDailyQuests, ...nightly]);
    
    // Record quest titles in history
    final usedTitles = [...newDailyQuests.map((q) => q.title), ...nightly.map((q) => q.title)];
    final history = _loadDailyQuestHistory();
    history[todayKey] = usedTitles;
    await _saveDailyQuestHistory(history);
    
    // Save quest IDs for stable loading
    final questIds = [...newDailyQuests.map((q) => q.id), ...nightly.map((q) => q.id)];
    await _saveGeneratedDailyQuestIds(todayKey, questIds);
    
    await _saveQuests(quests);
    await _storage.save(_lastDailyGenerationKey, todayKey);
    
    if (kDebugMode) {
      debugPrint('[TaskService] Generated ${newDailyQuests.length} daily + ${nightly.length} nightly quests for $todayKey');
      debugPrint('[TaskService] Daily quest titles: ${newDailyQuests.map((q) => q.title).toList()}');
      debugPrint('[TaskService] History size: ${history.length} days');
    }
  }

  Future<void> createWeeklyQuests() async {
    final now = DateTime.now();
    final weekKey = _getWeekKey();
    final last = _storage.getString(_lastWeeklyGenerationKey);
    
    if (kDebugMode) {
      debugPrint('[TaskService] createWeeklyQuests: weekKey=$weekKey, lastGen=$last');
    }
    
    if (last == weekKey) {
      if (kDebugMode) {
        debugPrint('[TaskService] Weekly quests already generated for $weekKey - loading existing');
      }
      return;
    }

    final quests = await getAllQuests();
    // Remove old weekly quests that are not completed
    quests.removeWhere((q) => (q.category == 'weekly' || q.isWeekly || q.type == 'weekly') && q.status != 'completed');

    // Use Monday as week start for quest generation with history-aware selection
    final monday = now.subtract(Duration(days: (now.weekday - DateTime.monday))).copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    final weekly = _generateWeeklyQuestsWithHistory(monday);
    quests.addAll(weekly);
    
    // Record quest titles in history
    final usedTitles = weekly.map((q) => q.title).toList();
    final history = _loadWeeklyQuestHistory();
    history[weekKey] = usedTitles;
    await _saveWeeklyQuestHistory(history);
    
    // Save quest IDs for stable loading
    await _saveGeneratedWeeklyQuestIds(weekKey, weekly.map((q) => q.id).toList());

    await _saveQuests(quests);
    await _storage.save(_lastWeeklyGenerationKey, weekKey);
    
    if (kDebugMode) {
      debugPrint('[TaskService] Generated ${weekly.length} weekly quests for $weekKey');
      debugPrint('[TaskService] Weekly quest titles: $usedTitles');
      debugPrint('[TaskService] Weekly history size: ${history.length} weeks');
    }
  }

  // Mark quest rewards claimed (v2.0)
  Future<void> markQuestClaimed(String questId) async {
    try {
      final quests = await getAllQuests();
      final idx = quests.indexWhere((q) => q.id == questId);
      if (idx == -1) return;
      final q = quests[idx];
      quests[idx] = q.copyWith(isClaimed: true, updatedAt: DateTime.now());
      await _saveQuests(quests);
    } catch (e) {
      debugPrint('markQuestClaimed error: $e');
    }
  }

  // Auto-generate a simple book quest based on reading context (v2.0)
  Future<void> ensureBookQuestsForBook(String book, {int? chapter}) async {
    try {
      final b = book.trim();
      if (b.isEmpty) return;
      final quests = await getAllQuests();
      // Only one active simple book quest per book
      final exists = quests.any((q) => (q.category == 'book' || q.type == 'book') && (q.scriptureReference ?? '').toLowerCase().startsWith(b.toLowerCase()) && (q.status == 'not_started' || q.status == 'in_progress'));
      if (exists) return;

      final now = DateTime.now();
      final ref = chapter != null && chapter > 0 ? '$b $chapter' : b;
      final q = TaskModel(
        id: _uuid.v4(),
        title: 'Read $ref',
        description: 'Open and read $ref in the Bible tonight.',
        type: 'book',
        category: 'book',
        questType: 'scripture_reading',
        scriptureReference: ref,
        targetCount: 1,
        xpReward: 25,
        rewards: const [Reward(type: RewardTypes.xp, amount: 25, label: '25 XP')],
        startDate: now,
        endDate: now.add(const Duration(days: 7)),
        createdAt: now,
        updatedAt: now,
      );
      quests.add(q);
      await _saveQuests(quests);
    } catch (e) {
      debugPrint('ensureBookQuestsForBook error: $e');
    }
  }

  Future<void> updateQuestProgress(String questId, int progress) async {
    final quests = await getAllQuests();
    final index = quests.indexWhere((q) => q.id == questId);
    
    if (index != -1) {
      final quest = quests[index];
      final newProgress = quest.currentProgress + progress;
      
      if (newProgress >= quest.targetCount) {
        quests[index] = quest.copyWith(
          currentProgress: quest.targetCount,
          status: 'completed',
          completedAt: DateTime.now(),
          lastCompletedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        quests[index] = quest.copyWith(
          currentProgress: newProgress,
          status: 'in_progress',
          updatedAt: DateTime.now(),
        );
      }
      
      await _saveQuests(quests);
    }
  }

  Future<void> startQuest(String questId) async {
    final quests = await getAllQuests();
    final index = quests.indexWhere((q) => q.id == questId);
    if (index != -1) {
      final quest = quests[index];
      quests[index] = quest.copyWith(
        status: 'in_progress',
        updatedAt: DateTime.now(),
      );
      await _saveQuests(quests);
    }
  }

  Future<void> completeQuest(String questId) async {
    final quests = await getAllQuests();
    final index = quests.indexWhere((q) => q.id == questId);
    
    if (index != -1) {
      quests[index] = quests[index].copyWith(
        status: 'completed',
        currentProgress: quests[index].targetCount,
        completedAt: DateTime.now(),
        lastCompletedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _saveQuests(quests);
    }
  }

  Future<void> expireOldQuests() async {
    final quests = await getAllQuests();
    final now = DateTime.now();
    bool hasChanges = false;
    
    for (int i = 0; i < quests.length; i++) {
      final quest = quests[i];
      if (quest.endDate != null && now.isAfter(quest.endDate!) && (quest.status == 'not_started' || quest.status == 'in_progress')) {
        quests[i] = quest.copyWith(status: 'expired', updatedAt: now);
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      await _saveQuests(quests);
    }
  }

  // Expire a quest by id immediately
  Future<void> expireQuestById(String questId) async {
    try {
      final quests = await getAllQuests();
      final idx = quests.indexWhere((q) => q.id == questId);
      if (idx == -1) return;
      final q = quests[idx];
      if (q.status == 'completed' || q.status == 'expired') return;
      quests[idx] = q.copyWith(status: 'expired', updatedAt: DateTime.now());
      await _saveQuests(quests);
    } catch (e) {
      debugPrint('expireQuestById error: $e');
    }
  }

  Future<void> _saveQuests(List<TaskModel> quests) async {
    final jsonList = quests.map((q) => q.toJson()).toList();
    await _storage.save(_storageKey, jsonEncode(jsonList));
  }

  List<TaskModel> _generateDailyQuests() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Build a large daily pool (>= 15) and pick a varied subset per day
    final pool = _dailyTaskPool(now, endOfDay);
    final picked = _pickRandom(pool, min: 6, max: 8);
    return picked;
  }

  List<TaskModel> _generateNightlyQuests(DateTime now) {
    final endOfNight = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final pool = _nightlyTaskPool(now, endOfNight);
    // Pick a few gentle nightly prompts each day
    return _pickRandom(pool, min: 4, max: 6);
  }

  List<TaskModel> _generateWeeklyQuests(DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
    final now = DateTime.now();
    return [
      // Read on 3 different days this week (days active)
      TaskModel(
        id: _uuid.v4(),
        title: 'Read on 3 different days',
        description: 'Return on three separate days this week. Gentle rhythm.',
        type: 'weekly',
        category: 'weekly',
        questFrequency: 'weekly',
        questType: 'days_active',
        isAutoTracked: true,
        targetCount: 3,
        xpReward: 100,
        rewards: const [Reward(type: RewardTypes.xp, amount: 100, label: '100 XP')],
        isWeekly: true,
        difficulty: 'Easy',
        startDate: weekStart,
        endDate: end,
        createdAt: now,
        updatedAt: now,
      ),
      // Complete 5 total quests this week (meta)
      TaskModel(
        id: _uuid.v4(),
        title: 'Complete 5 quests',
        description: 'Finish any five quests across the week—keep it kind.',
        type: 'weekly',
        category: 'weekly',
        questFrequency: 'weekly',
        questType: 'meta',
        isAutoTracked: true,
        targetCount: 5,
        xpReward: 150,
        rewards: const [Reward(type: RewardTypes.xp, amount: 150, label: '150 XP')],
        isWeekly: true,
        difficulty: 'Medium',
        startDate: weekStart,
        endDate: end,
        createdAt: now,
        updatedAt: now,
      ),
      // Read 5 Chapters This Week (existing)
      TaskModel(
        id: _uuid.v4(),
        title: 'Read 5 chapters this week',
        description: 'Steady pace: complete 5 chapters this week.',
        type: 'weekly',
        category: 'weekly',
        questFrequency: 'weekly',
        questType: 'scripture_reading',
        isAutoTracked: true,
        targetCount: 5,
        xpReward: 120,
        rewards: const [Reward(type: RewardTypes.xp, amount: 120, label: '120 XP')],
        isWeekly: true,
        difficulty: 'Medium',
        startDate: weekStart,
        endDate: end,
        createdAt: now,
        updatedAt: now,
      ),
      // Complete 3 Reflection Moments (existing)
      TaskModel(
        id: _uuid.v4(),
        title: 'Complete 3 reflection moments',
        description: 'Pause with three short reflections this week.',
        type: 'weekly',
        category: 'weekly',
        questFrequency: 'weekly',
        questType: 'reflection',
        isAutoTracked: true,
        targetCount: 3,
        xpReward: 90,
        rewards: const [Reward(type: RewardTypes.xp, amount: 90, label: '90 XP')],
        isWeekly: true,
        difficulty: 'Easy',
        startDate: weekStart,
        endDate: end,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  List<TaskModel> _getSampleQuests() {
    final now = DateTime.now();
    final endOfWeek = now.add(Duration(days: 7 - now.weekday));
    
    return [
      ..._generateDailyQuests(),
      // Beginner quests: gentle on-ramp tasks tied to scripture
      TaskModel(
        id: _uuid.v4(),
        title: 'Read John 3',
        description: 'Open and read John chapter 3. Breathe in the Gospel.',
        scriptureReference: 'John 3',
        type: 'challenge',
        category: 'beginner',
        questType: 'scripture_reading',
        spiritualFocus: 'Love',
        isAutoTracked: true,
        difficulty: 'Easy',
        targetCount: 1,
        xpReward: 25,
        possibleRewardGearIds: const [
          'hand_water_jars_of_cana',
          'hand_loaves_basket',
          'charm_pearl_of_great_price',
        ],
        guaranteedFirstClearGearId: 'pearl_of_great_price',
        rewards: const [
          Reward(type: RewardTypes.xp, amount: 25, label: '25 XP', rarity: RewardRarities.common),
        ],
        startDate: now,
        createdAt: now,
        updatedAt: now,
      ),
      TaskModel(
        id: _uuid.v4(),
        title: 'Hope in Hard Times – Romans 8',
        description: 'Read Romans 8 and reflect on God\'s purpose',
        scriptureReference: 'Romans 8',
        type: 'challenge',
        category: 'beginner',
        questType: 'scripture_reading',
        spiritualFocus: 'Hope',
        isAutoTracked: true,
        difficulty: 'Easy',
        targetCount: 1,
        xpReward: 25,
        possibleRewardGearIds: const [
          'charm_anchor_of_hope',
          'charm_olive_branch',
          'hand_censer_of_incense',
        ],
        rewards: const [
          Reward(type: RewardTypes.xp, amount: 25, label: '25 XP', rarity: RewardRarities.common),
        ],
        startDate: now,
        createdAt: now,
        updatedAt: now,
      ),
      TaskModel(
        id: _uuid.v4(),
        title: 'Read Hebrews 11',
        description: 'Read Hebrews 11 and ponder the faith of our forebears.',
        scriptureReference: 'Hebrews 11',
        type: 'challenge',
        category: 'beginner',
        questType: 'scripture_reading',
        spiritualFocus: 'Faith',
        isAutoTracked: true,
        difficulty: 'Easy',
        targetCount: 1,
        xpReward: 20,
        possibleRewardGearIds: const [
          'charm_mustard_seed_pendant',
          'charm_five_smooth_stones',
          'legs_pilgrims_garments',
        ],
        rewards: const [
          Reward(type: RewardTypes.xp, amount: 20, label: '20 XP', rarity: RewardRarities.common),
        ],
        startDate: now,
        createdAt: now,
        updatedAt: now,
      ),
      TaskModel(
        id: _uuid.v4(),
        title: 'Memorize 1 Verse This Week',
        description: 'Choose any verse and memorize it by week’s end',
        scriptureReference: null,
        type: 'challenge',
        category: 'beginner',
        questType: 'reflection',
        spiritualFocus: 'Obedience',
        reflectionPrompt: 'How can this verse guide your week?',
        isAutoTracked: false,
        difficulty: 'Medium',
        targetCount: 1,
        xpReward: 30,
        possibleRewardGearIds: const [
          'hand_lantern_of_the_word',
          'head_priestly_turban',
          'charm_little_scroll',
        ],
        rewards: const [
          Reward(type: RewardTypes.xp, amount: 30, label: '30 XP', rarity: RewardRarities.common),
        ],
        startDate: now,
        createdAt: now,
        updatedAt: now,
      ),
      // Prayer
      TaskModel(
        id: _uuid.v4(),
        title: 'Pray for a Friend by Name',
        description: 'Take a moment to pray for someone specific by name',
        type: 'challenge',
        category: 'beginner',
        questType: 'prayer',
        spiritualFocus: 'Love',
        isWithOthers: true,
        reflectionPrompt: 'How did praying for them change how you feel toward them?',
        isAutoTracked: false,
        difficulty: 'Easy',
        targetCount: 1,
        xpReward: 20,
        possibleRewardGearIds: const [
          'hand_censer_of_incense',
          'charm_widows_mite',
          'charm_olive_branch',
        ],
        rewards: const [
          Reward(type: RewardTypes.xp, amount: 20, label: '20 XP', rarity: RewardRarities.common),
        ],
        startDate: now,
        createdAt: now,
        updatedAt: now,
      ),
      // Reflection / Journaling
      TaskModel(
        id: _uuid.v4(),
        title: 'Gratitude List – 3 Things',
        description: 'Write down 3 things you’re thankful to God for today',
        type: 'challenge',
        category: 'beginner',
        questType: 'reflection',
        spiritualFocus: 'Thankfulness',
        reflectionPrompt: 'When you have done this, tap “Mark Complete.”',
        isAutoTracked: false,
        difficulty: 'Easy',
        targetCount: 1,
        xpReward: 15,
        possibleRewardGearIds: const [
          'charm_small_flask_of_oil',
          'hand_alabaster_jar',
          'charm_rainbow_token',
        ],
        rewards: const [
          Reward(type: RewardTypes.xp, amount: 15, label: '15 XP', rarity: RewardRarities.common),
        ],
        startDate: now,
        createdAt: now,
        updatedAt: now,
      ),
      // Service
      TaskModel(
        id: _uuid.v4(),
        title: 'Encourage Someone',
        description: 'Send a text, DM, or call someone and encourage them',
        type: 'challenge',
        category: 'beginner',
        questType: 'service',
        spiritualFocus: 'Encouragement',
        isWithOthers: true,
        reflectionPrompt: 'When you have done this, tap “Mark Complete.”',
        isAutoTracked: false,
        difficulty: 'Easy',
        targetCount: 1,
        xpReward: 20,
        possibleRewardGearIds: const [
          'hand_loaves_basket',
          'hand_water_jars_of_cana',
          'hand_fishers_net',
        ],
        rewards: const [
          Reward(type: RewardTypes.xp, amount: 20, label: '20 XP', rarity: RewardRarities.common),
        ],
        startDate: now,
        createdAt: now,
        updatedAt: now,
      ),
      // Community
      TaskModel(
        id: _uuid.v4(),
        title: 'Share a Verse with Someone',
        description: 'Share a meaningful verse with a friend or community',
        type: 'challenge',
        category: 'beginner',
        questType: 'community',
        spiritualFocus: 'Community',
        isWithOthers: true,
        isAutoTracked: false,
        difficulty: 'Easy',
        targetCount: 1,
        xpReward: 20,
        possibleRewardGearIds: const [
          'hand_fishers_net',
          'feet_sandals_of_peace',
          'charm_keys_of_the_kingdom',
        ],
        rewards: const [
          Reward(type: RewardTypes.xp, amount: 20, label: '20 XP', rarity: RewardRarities.common),
        ],
        startDate: now,
        createdAt: now,
        updatedAt: now,
      ),
      // Event quests: seasonal or church-event themed
      TaskModel(
        id: _uuid.v4(),
        title: 'Christmas: Read Luke 2',
        description: 'Celebrate Christmas by reading the Nativity in Luke 2',
        scriptureReference: 'Luke 2',
        type: 'challenge',
        category: 'event',
        questType: 'scripture_reading',
        spiritualFocus: 'Joy',
        isAutoTracked: true,
        difficulty: 'Easy',
        targetCount: 1,
        xpReward: 40,
        possibleRewardGearIds: const [
          'charm_bethlehem_star',
          'charm_pearl_of_great_price',
          'hand_water_jars_of_cana',
        ],
        rewards: const [
          Reward(type: RewardTypes.xp, amount: 40, label: '40 XP', rarity: RewardRarities.common),
        ],
        startDate: now,
        createdAt: now,
        updatedAt: now,
      ),
      TaskModel(
        id: _uuid.v4(),
        title: 'Easter: Read John 20',
        description: 'Read about the Resurrection in John 20',
        scriptureReference: 'John 20',
        type: 'challenge',
        category: 'event',
        questType: 'scripture_reading',
        spiritualFocus: 'Hope',
        isAutoTracked: true,
        difficulty: 'Medium',
        targetCount: 1,
        xpReward: 50,
        possibleRewardGearIds: const [
          'artifact_empty_tomb_stone',
          'hand_lantern_of_the_word',
          'charm_anchor_of_hope',
        ],
        rewards: const [
          Reward(type: RewardTypes.xp, amount: 50, label: '50 XP', rarity: RewardRarities.common),
        ],
        startDate: now,
        createdAt: now,
        updatedAt: now,
      ),
      TaskModel(
        id: _uuid.v4(),
        title: 'New Year: Create 1 Faith Goal',
        description: 'Start the year by creating one new faith goal',
        scriptureReference: null,
        type: 'challenge',
        category: 'event',
        questType: 'reflection',
        spiritualFocus: 'Obedience',
        reflectionPrompt: 'Commit your plans to the Lord in prayer. When done, tap “Mark Complete.”',
        isAutoTracked: false,
        difficulty: 'Easy',
        targetCount: 1,
        xpReward: 35,
        possibleRewardGearIds: const [
          'charm_rainbow_token',
          'charm_olive_branch',
          'head_priestly_turban',
        ],
        rewards: const [
          Reward(type: RewardTypes.xp, amount: 35, label: '35 XP', rarity: RewardRarities.common),
        ],
        startDate: now,
        createdAt: now,
        updatedAt: now,
      ),
      TaskModel(
        id: _uuid.v4(),
        title: 'Community Night: Share a Verse',
        description: 'At your next gathering, share a verse that encouraged you',
        type: 'challenge',
        category: 'event',
        questType: 'community',
        spiritualFocus: 'Community',
        isWithOthers: true,
        isAutoTracked: false,
        difficulty: 'Easy',
        targetCount: 1,
        xpReward: 30,
        possibleRewardGearIds: const [
          'hand_shofar_of_jubilee',
          'hand_fishers_net',
          'feet_sandals_of_peace',
        ],
        rewards: const [
          Reward(type: RewardTypes.xp, amount: 30, label: '30 XP', rarity: RewardRarities.common),
        ],
        startDate: now,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}

// Note: QuestBoardService moved to lib/services/quest_board_service.dart for clarity.


// ===== Helper pools and seeding for Tasks v2.0 content expansion =====
extension _TaskGenerationHelpers on TaskService {
  List<T> _pickRandom<T>(List<T> pool, {required int min, required int max}) {
    if (pool.isEmpty) return <T>[];
    final today = DateTime.now();
    // Seed by Y-M-D so the selection is stable for the day but changes tomorrow
    final seed = today.year + today.month * 37 + today.day * 101;
    final rng = Random(seed);
    final count = min + (rng.nextInt((max - min + 1).clamp(0, 100000)));
    final list = List<T>.from(pool);
    list.shuffle(rng);
    return list.take(count.clamp(0, list.length)).toList();
  }

  List<TaskModel> _dailyTaskPool(DateTime now, DateTime endOfDay) {
    // Gentle, short, spiritually uplifting prompts (>= 15 entries)
    TaskModel d({
      required String title,
      required String description,
      String questType = 'scripture_reading',
      String? scriptureRef,
      String spiritualFocus = 'Peace',
      int xp = 20,
      String difficulty = 'Easy',
    }) => TaskModel(
          id: _uuid.v4(),
          title: title,
          description: description,
          type: 'daily',
          category: 'daily',
          taskCategory: TaskCategory.daily,
          questFrequency: 'daily',
          questType: questType,
          spiritualFocus: spiritualFocus,
          scriptureReference: scriptureRef,
          isDaily: true,
          isAutoTracked: questType == 'scripture_reading' || questType == 'routine',
          difficulty: difficulty,
          targetCount: 1,
          xpReward: xp,
          rewards: [Reward(type: RewardTypes.xp, amount: xp, label: '$xp XP', rarity: RewardRarities.common)],
          startDate: now,
          endDate: endOfDay,
          createdAt: now,
          updatedAt: now,
        );

    return [
      d(title: 'Read 1 chapter today', description: 'A gentle step in Scripture today. Any book you’re drawn to is wonderful.'),
      d(title: 'Open the Bible tab', description: 'Simply open the Bible and breathe. No rush.', questType: 'routine', spiritualFocus: 'Stillness', xp: 10),
      d(title: 'Complete any 1 quest', description: 'Finish any small quest today—celebrate the step you take.', questType: 'meta', spiritualFocus: 'Perseverance'),
      d(title: 'Reflect on a verse', description: 'Write a short reflection or prayer in your journal.', questType: 'reflection', spiritualFocus: 'Reflection'),
      d(title: 'Read from your current focus', description: 'Open a chapter in a book you’re focusing on (or any book).'),
      // New daily prompts (12+)
      d(title: 'Read a verse that gives you strength today.', description: 'Choose any verse that encourages you.', questType: 'scripture_reading', spiritualFocus: 'Strength', xp: 15),
      d(title: 'Thank God for something small but meaningful.', description: 'Whisper a short prayer of thanks.', questType: 'prayer', spiritualFocus: 'Thankfulness', xp: 15),
      d(title: 'Choose one person to bless with kindness.', description: 'Send a kind message or help someone today.', questType: 'service', spiritualFocus: 'Kindness', xp: 20),
      d(title: 'Read a Psalm and notice one comforting line.', description: 'Let one phrase rest in your heart.', questType: 'scripture_reading', spiritualFocus: 'Comfort', xp: 20),
      d(title: 'Pick a Proverb and think about its wisdom.', description: 'Ask: how can I live this today?', questType: 'scripture_reading', spiritualFocus: 'Wisdom', xp: 20),
      d(title: 'Say a short prayer for peace over your day.', description: 'Invite God’s peace into what’s ahead.', questType: 'prayer', spiritualFocus: 'Peace', xp: 15),
      d(title: 'Reflect on something God has helped you overcome.', description: 'Remember His faithfulness.', questType: 'reflection', spiritualFocus: 'Remembering', xp: 20),
      d(title: 'Read a verse about courage.', description: 'Let God’s word make you brave.', questType: 'scripture_reading', spiritualFocus: 'Courage', xp: 15),
      d(title: 'Take a moment of stillness and breathe deeply.', description: 'Slow down for a minute with God.', questType: 'prayer', spiritualFocus: 'Stillness', xp: 10),
      d(title: 'Write down one blessing from today.', description: 'Capture it in your Journal.', questType: 'reflection', spiritualFocus: 'Gratitude', xp: 20),
      d(title: 'Read a teaching of Jesus and reflect for a moment.', description: 'Choose any passage in the Gospels.', questType: 'scripture_reading', spiritualFocus: 'Discipleship', xp: 20),
      d(title: 'Pray for someone who might be struggling.', description: 'Ask God to bring comfort and help.', questType: 'prayer', spiritualFocus: 'Compassion', xp: 20),
      d(title: 'Share one encouraging verse with a friend.', description: 'A gentle nudge of hope today.', questType: 'community', spiritualFocus: 'Encouragement', xp: 20),
      d(title: 'Revisit a bookmarked verse.', description: 'Read it again slowly and notice new things.', questType: 'scripture_reading', spiritualFocus: 'Meditation', xp: 15),
      d(title: 'Read one parable of Jesus.', description: 'Let the story speak to your heart.', questType: 'scripture_reading', spiritualFocus: 'Learning', xp: 20),
    ];
  }

  List<TaskModel> _nightlyTaskPool(DateTime now, DateTime endOfNight) {
    // Nightly quest template builder.
    // questType determines auto-progress behavior:
    // - 'scripture_reading': auto-tracked via chapter completion (onChapterComplete)
    // - 'reflection', 'prayer': manual completion only
    // targetBook: optional book name for Start navigation and matching
    TaskModel n({
      required String title,
      required String description,
      String questType = 'reflection',
      String spiritualFocus = 'Peace',
      String? targetBook,
      int xp = 20,
    }) => TaskModel(
          id: _uuid.v4(),
          title: title,
          description: description,
          type: 'nightly',
          category: 'nightly',
          taskCategory: TaskCategory.nightly,
          questFrequency: 'daily',
          questType: questType,
          spiritualFocus: spiritualFocus,
          targetBook: targetBook,
          isAutoTracked: questType == 'scripture_reading',
          isDaily: true,
          targetCount: 1,
          xpReward: xp,
          rewards: [Reward(type: RewardTypes.xp, amount: xp, label: '$xp XP')],
          difficulty: 'Easy',
          startDate: now,
          endDate: endOfNight,
          createdAt: now,
          updatedAt: now,
        );

    return [
      n(title: 'Nightly Reading', description: 'Read any chapter tonight for a gentle check-in.', questType: 'scripture_reading', spiritualFocus: 'Faithfulness', xp: 20),
      n(title: 'Reflect on one good moment from today.', description: 'Thank God for that gift.', questType: 'reflection', spiritualFocus: 'Gratitude', xp: 20),
      n(title: 'Thank God for carrying you through the day.', description: 'Offer a short prayer of thanks.', questType: 'prayer', spiritualFocus: 'Thankfulness', xp: 15),
      n(title: 'Ask God for rest and peace tonight.', description: 'Release worries into His hands.', questType: 'prayer', spiritualFocus: 'Peace', xp: 15),
      // Psalms reading quest: targetBook = 'Psalms' for Start navigation and matching
      n(title: 'Read a calming Psalm before bed.', description: 'Let Scripture settle your heart.', questType: 'scripture_reading', targetBook: 'Psalms', spiritualFocus: 'Comfort', xp: 20),
      n(title: 'Release any stress or frustration to God.', description: 'Breathe and let go.', questType: 'reflection', spiritualFocus: 'Surrender', xp: 20),
      n(title: 'Think of one way you grew today.', description: 'Notice progress, however small.', questType: 'reflection', spiritualFocus: 'Growth', xp: 20),
      n(title: 'Pray for tomorrow’s challenges.', description: 'Ask for wisdom and courage.', questType: 'prayer', spiritualFocus: 'Courage', xp: 15),
      n(title: 'Journal a short gratitude note.', description: 'Write one line of thanks.', questType: 'reflection', spiritualFocus: 'Gratitude', xp: 20),
      n(title: 'Read a verse about God’s protection.', description: 'Rest in His care.', questType: 'scripture_reading', targetBook: 'Psalms', spiritualFocus: 'Trust', xp: 20),
      n(title: 'Ask God to renew your mind tonight.', description: 'Invite Him to bring peace.', questType: 'prayer', spiritualFocus: 'Renewal', xp: 15),
      n(title: 'Reflect on someone you want to forgive.', description: 'Pray for grace to release it.', questType: 'reflection', spiritualFocus: 'Forgiveness', xp: 20),
      n(title: 'Think about a moment you felt God near today.', description: 'Hold that memory with gratitude.', questType: 'reflection', spiritualFocus: 'Awareness', xp: 20),
    ];
  }

  Future<List<TaskModel>> _ensureReflectionSeeds(List<TaskModel> existing) async {
    try {
      final now = DateTime.now();
      bool existsByTitle(String t) => existing.any((q) => q.title.trim().toLowerCase() == t.trim().toLowerCase());
      TaskModel r({required String title, required String description, String questType = 'reflection', String focus = 'Reflection', int xp = 20}) => TaskModel(
            id: _uuid.v4(),
            title: title,
            description: description,
            type: 'challenge',
            category: 'reflection',
            taskCategory: TaskCategory.reflection,
            questFrequency: 'once',
            questType: questType,
            spiritualFocus: focus,
            isAutoTracked: false,
            isDaily: false,
            targetCount: 1,
            xpReward: xp,
            rewards: [Reward(type: RewardTypes.xp, amount: xp, label: '$xp XP')],
            startDate: now,
            endDate: null,
            createdAt: now,
            updatedAt: now,
            autoResetDaily: false,
          );

      final seeds = <TaskModel>[
        r(title: 'Journal what God is teaching you this week.', description: 'Write a few simple thoughts. ✍️'),
        r(title: 'Write down one verse that stands out to you.', description: 'Copy it into your Journal.'),
        r(title: 'Reflect on a prayer God has answered.', description: 'Remember His faithfulness.', focus: 'Thankfulness'),
        r(title: 'Think about how you’ve grown spiritually.', description: 'Notice even small steps.', focus: 'Growth'),
        r(title: 'Write a short prayer in your journal.', description: 'Keep it simple and true.', questType: 'prayer', focus: 'Prayer', xp: 15),
        r(title: 'Reflect on a recent challenge and how God met you there.', description: 'Name His help.', focus: 'Hope'),
        r(title: 'Pick a verse and rewrite it in your own words.', description: 'Let it speak in your voice.', focus: 'Meditation'),
        r(title: 'Write a gratitude list of three things.', description: 'Thank Him for each gift.', focus: 'Gratitude'),
        r(title: 'Reflect on a step of obedience you want to take.', description: 'What is one gentle next step?', focus: 'Obedience'),
        r(title: 'Journal your thoughts on a psalm.', description: 'Choose any Psalm you like.', focus: 'Psalms'),
        r(title: 'Write a reflection about someone God put on your heart.', description: 'Pray and bless them.', focus: 'Love'),
        r(title: 'Reflect on today’s Scripture reading.', description: 'Capture one takeaway.', focus: 'Reflection'),
      ];

      bool added = false;
      for (final seed in seeds) {
        if (!existsByTitle(seed.title)) {
          existing.add(seed);
          added = true;
        }
      }
      if (added) {
        await _saveQuests(existing);
      }
    } catch (e, st) {
      debugPrint('_ensureReflectionSeeds error: $e\n$st');
    }
    return existing;
  }
  
  // ================== History-Aware Quest Generation ==================
  
  /// Generate daily quests with history filtering to prevent repetition
  List<TaskModel> _generateDailyQuestsWithHistory() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    // Get full pool and recent history
    final pool = _dailyTaskPool(now, endOfDay);
    final recentTitles = _getRecentDailyQuestTitles(lookbackDays: 7);
    
    // Filter out recently used quests
    var availablePool = pool.where((q) => !recentTitles.contains(q.title)).toList();
    
    // If pool is too small, relax to 2-day history
    if (availablePool.length < 3) {
      if (kDebugMode) {
        debugPrint('[TaskService] Daily pool too small (${availablePool.length}), relaxing to 2-day history');
      }
      final relaxedRecent = _getRecentDailyQuestTitles(lookbackDays: 2);
      availablePool = pool.where((q) => !relaxedRecent.contains(q.title)).toList();
    }
    
    // If still too small, use full pool (edge case)
    if (availablePool.isEmpty) {
      if (kDebugMode) {
        debugPrint('[TaskService] Daily pool empty after filtering, using full pool');
      }
      availablePool = pool;
    }
    
    // Pick 2-3 quests from available pool using deterministic seed
    final picked = _pickRandom(availablePool, min: 2, max: 3);
    
    if (kDebugMode) {
      debugPrint('[TaskService] _generateDailyQuestsWithHistory: pool=${pool.length}, available=${availablePool.length}, picked=${picked.length}');
      debugPrint('[TaskService] Recent daily titles (7 days): ${recentTitles.length}');
    }
    
    return picked;
  }
  
  /// Generate nightly quests with history filtering to prevent repetition
  List<TaskModel> _generateNightlyQuestsWithHistory(DateTime now) {
    final endOfNight = DateTime(now.year, now.month, now.day + 1, 5, 59, 59);
    
    // Get full pool and recent history
    final pool = _nightlyTaskPool(now, endOfNight);
    final recentTitles = _getRecentDailyQuestTitles(lookbackDays: 7);
    
    // Filter out recently used quests
    var availablePool = pool.where((q) => !recentTitles.contains(q.title)).toList();
    
    // If pool is too small, relax to 2-day history
    if (availablePool.length < 2) {
      if (kDebugMode) {
        debugPrint('[TaskService] Nightly pool too small (${availablePool.length}), relaxing to 2-day history');
      }
      final relaxedRecent = _getRecentDailyQuestTitles(lookbackDays: 2);
      availablePool = pool.where((q) => !relaxedRecent.contains(q.title)).toList();
    }
    
    // If still too small, use full pool
    if (availablePool.isEmpty) {
      if (kDebugMode) {
        debugPrint('[TaskService] Nightly pool empty after filtering, using full pool');
      }
      availablePool = pool;
    }
    
    // Pick 1-2 quests from available pool
    final picked = _pickRandom(availablePool, min: 1, max: 2);
    
    if (kDebugMode) {
      debugPrint('[TaskService] _generateNightlyQuestsWithHistory: pool=${pool.length}, available=${availablePool.length}, picked=${picked.length}');
    }
    
    return picked;
  }
  
  /// Generate weekly quests with history filtering to prevent repetition
  List<TaskModel> _generateWeeklyQuestsWithHistory(DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
    final now = DateTime.now();
    
    // Get full pool and recent weekly history
    final pool = _weeklyTaskPool(weekStart, end, now);
    final recentTitles = _getRecentWeeklyQuestTitles(lookbackWeeks: 1);
    
    // Filter out quests used last week
    var availablePool = pool.where((q) => !recentTitles.contains(q.title)).toList();
    
    // If pool is too small after filtering, use full pool
    if (availablePool.length < 3) {
      if (kDebugMode) {
        debugPrint('[TaskService] Weekly pool too small (${availablePool.length}), using full pool');
      }
      availablePool = pool;
    }
    
    // Pick 3-4 weekly quests from available pool
    final picked = _pickRandom(availablePool, min: 3, max: 4);
    
    if (kDebugMode) {
      debugPrint('[TaskService] _generateWeeklyQuestsWithHistory: pool=${pool.length}, available=${availablePool.length}, picked=${picked.length}');
      debugPrint('[TaskService] Recent weekly titles (1 week): ${recentTitles.length}');
    }
    
    return picked;
  }
  
  /// Pool of weekly quest templates for varied selection
  List<TaskModel> _weeklyTaskPool(DateTime weekStart, DateTime end, DateTime now) {
    TaskModel w({
      required String title,
      required String description,
      String questType = 'scripture_reading',
      int targetCount = 5,
      int xp = 100,
      String difficulty = 'Medium',
    }) => TaskModel(
          id: _uuid.v4(),
          title: title,
          description: description,
          type: 'weekly',
          category: 'weekly',
          questFrequency: 'weekly',
          questType: questType,
          isAutoTracked: true,
          targetCount: targetCount,
          xpReward: xp,
          rewards: [Reward(type: RewardTypes.xp, amount: xp, label: '$xp XP')],
          isWeekly: true,
          difficulty: difficulty,
          startDate: weekStart,
          endDate: end,
          createdAt: now,
          updatedAt: now,
        );
    
    return [
      // Core weekly quests
      w(title: 'Read on 3 different days', description: 'Return on three separate days this week. Gentle rhythm.', questType: 'days_active', targetCount: 3, difficulty: 'Easy'),
      w(title: 'Complete 5 quests', description: 'Finish any five quests across the week—keep it kind.', questType: 'meta', targetCount: 5, xp: 150),
      w(title: 'Read 5 chapters this week', description: 'Steady pace: complete 5 chapters this week.', questType: 'scripture_reading', targetCount: 5, xp: 120),
      w(title: 'Complete 3 reflection moments', description: 'Pause with three short reflections this week.', questType: 'reflection', targetCount: 3, xp: 90, difficulty: 'Easy'),
      // Additional weekly variety
      w(title: 'Read 3 Psalms this week', description: 'Let the Psalms guide your week with comfort and praise.', questType: 'scripture_reading', targetCount: 3, xp: 80, difficulty: 'Easy'),
      w(title: 'Journal twice this week', description: 'Capture two moments of reflection in your journal.', questType: 'reflection', targetCount: 2, xp: 70, difficulty: 'Easy'),
      w(title: 'Read 7 chapters this week', description: 'A chapter a day keeps the Word near.', questType: 'scripture_reading', targetCount: 7, xp: 150),
      w(title: 'Pray for 3 different people', description: 'Lift up three people in prayer this week.', questType: 'prayer', targetCount: 3, xp: 75, difficulty: 'Easy'),
      w(title: 'Complete 3 quests in one day', description: 'Have a focused day of spiritual growth.', questType: 'meta', targetCount: 3, xp: 100),
      w(title: 'Read from 2 different books', description: 'Explore two different books of the Bible this week.', questType: 'scripture_reading', targetCount: 2, xp: 80, difficulty: 'Easy'),
    ];
  }
}

