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
  final StorageService _storage;
  final _uuid = const Uuid();

  TaskService(this._storage);

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
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    final lastGen = _storage.getString(_lastDailyGenerationKey);
    
    if (lastGen == todayString) return;
    
    final quests = await getAllQuests();
    // Remove old daily quests that are not completed
    quests.removeWhere((q) => (q.category == 'daily' || q.isDaily || q.type == 'daily') && q.status != 'completed');
    
    final newDailyQuests = _generateDailyQuests();
    // Add Nightly tasks (v2.0)
    final nightly = _generateNightlyQuests(today);
    quests.addAll([...newDailyQuests, ...nightly]);
    
    await _saveQuests(quests);
    await _storage.save(_lastDailyGenerationKey, todayString);
  }

  Future<void> createWeeklyQuests() async {
    final now = DateTime.now();
    // Use Monday as week key
    final monday = now.subtract(Duration(days: (now.weekday - DateTime.monday))).copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    final key = 'W${monday.year}-${monday.month}-${monday.day}';
    final last = _storage.getString(_lastWeeklyGenerationKey);
    if (last == key) return;

    final quests = await getAllQuests();
    // Remove old weekly quests that are not completed
    quests.removeWhere((q) => (q.category == 'weekly' || q.isWeekly || q.type == 'weekly') && q.status != 'completed');

    final weekly = _generateWeeklyQuests(monday);
    quests.addAll(weekly);

    await _saveQuests(quests);
    await _storage.save(_lastWeeklyGenerationKey, key);
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
}

