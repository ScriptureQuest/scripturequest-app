import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:level_up_your_faith/models/achievement_model.dart';
import 'package:level_up_your_faith/models/reward.dart';
import 'package:level_up_your_faith/services/storage_service.dart';
import 'package:level_up_your_faith/data/achievement_seeds.dart';

class AchievementService {
  final StorageService _storage;
  AchievementService(this._storage);

  // Storage key factory per user
  String _keyForUser(String userId) => 'achievements_user_$userId';

  // Static definitions: stable IDs + metadata
  static List<AchievementModel> get definitions {
    final now = DateTime.now();
    final base = [
      // Quests
      AchievementModel(
        id: 'first_quest',
        name: 'First Quest Completed',
        description: 'Complete 1 quest.',
        category: 'Quests',
        rarity: 'common',
        requirement: 1,
        xpReward: 50,
        rewards: const [Reward(type: RewardTypes.xp, amount: 50, label: '50 XP', rarity: RewardRarities.common)],
        createdAt: now,
        updatedAt: now,
      ),
      AchievementModel(
        id: 'ten_quests',
        name: 'Quest Hunter',
        description: 'Complete 10 quests.',
        category: 'Quests',
        rarity: 'rare',
        requirement: 10,
        xpReward: 100,
        rewards: const [Reward(type: RewardTypes.xp, amount: 100, label: '100 XP', rarity: RewardRarities.rare)],
        createdAt: now,
        updatedAt: now,
      ),
      AchievementModel(
        id: 'fifty_quests',
        name: 'Quest Master',
        description: 'Complete 50 quests.',
        category: 'Quests',
        rarity: 'epic',
        requirement: 50,
        xpReward: 250,
        rewards: const [Reward(type: RewardTypes.xp, amount: 250, label: '250 XP', rarity: RewardRarities.epic)],
        createdAt: now,
        updatedAt: now,
      ),

      // Bible
      AchievementModel(
        id: 'first_scripture_open',
        name: 'First Scripture Opened',
        description: 'Open any scripture in the Bible tab.',
        category: 'Bible',
        rarity: 'common',
        requirement: 1,
        xpReward: 25,
        rewards: const [Reward(type: RewardTypes.xp, amount: 25, label: '25 XP', rarity: RewardRarities.common)],
        createdAt: now,
        updatedAt: now,
      ),
      AchievementModel(
        id: 'ten_scriptures_opened',
        name: 'Explorer',
        description: 'Open 10 unique references.',
        category: 'Bible',
        rarity: 'rare',
        requirement: 10,
        xpReward: 75,
        rewards: const [Reward(type: RewardTypes.xp, amount: 75, label: '75 XP', rarity: RewardRarities.rare)],
        createdAt: now,
        updatedAt: now,
      ),

      // Journal
      AchievementModel(
        id: 'first_reflection',
        name: 'First Reflection',
        description: 'Save 1 journal reflection.',
        category: 'Journal',
        rarity: 'common',
        requirement: 1,
        xpReward: 25,
        rewards: const [Reward(type: RewardTypes.xp, amount: 25, label: '25 XP', rarity: RewardRarities.common)],
        createdAt: now,
        updatedAt: now,
      ),
      AchievementModel(
        id: 'ten_reflections',
        name: 'Thoughtful',
        description: 'Save 10 reflections.',
        category: 'Journal',
        rarity: 'rare',
        requirement: 10,
        xpReward: 100,
        rewards: const [Reward(type: RewardTypes.xp, amount: 100, label: '100 XP', rarity: RewardRarities.rare)],
        createdAt: now,
        updatedAt: now,
      ),

      // Level
      AchievementModel(
        id: 'level_5',
        name: 'Level 5',
        description: 'Reach Level 5.',
        category: 'XP',
        rarity: 'rare',
        requirement: 5,
        xpReward: 0,
        rewards: const [],
        createdAt: now,
        updatedAt: now,
      ),
      AchievementModel(
        id: 'level_10',
        name: 'Level 10',
        description: 'Reach Level 10.',
        category: 'XP',
        rarity: 'epic',
        requirement: 10,
        xpReward: 0,
        rewards: const [],
        createdAt: now,
        updatedAt: now,
      ),
    ];
    // Merge v1.0 seeds without duplicating IDs
    final extras = AchievementSeedsV1.list();
    final byId = {for (final a in base) a.id: a};
    for (final e in extras) {
      byId.putIfAbsent(e.id, () => e);
    }
    return byId.values.toList();
  }

  // Initialize per-user achievements from definitions
  Future<List<AchievementModel>> getAchievementsForUser(String userId) async {
    try {
      final key = _keyForUser(userId);
      final jsonString = _storage.getString(key);
      if (jsonString == null) {
        final seed = definitions
            .map((d) => d.copyWith(isUnlocked: false, unlockedAt: null, progress: 0, createdAt: DateTime.now(), updatedAt: DateTime.now()))
            .toList();
        await saveAchievementsForUser(userId, seed);
        return seed;
      }
      final list = (jsonDecode(jsonString) as List<dynamic>)
          .map((e) => AchievementModel.fromJson(e as Map<String, dynamic>))
          .toList();
      // Ensure any new definitions are added
      final byId = {for (final a in list) a.id: a};
      for (final def in definitions) {
        if (!byId.containsKey(def.id)) {
          byId[def.id] = def.copyWith(isUnlocked: false, unlockedAt: null, progress: 0);
        }
      }
      final merged = byId.values.toList();
      await saveAchievementsForUser(userId, merged);
      return merged;
    } catch (e) {
      debugPrint('getAchievementsForUser error: $e');
      return definitions
          .map((d) => d.copyWith(isUnlocked: false, unlockedAt: null, progress: 0))
          .toList();
    }
  }

  Future<void> saveAchievementsForUser(String userId, List<AchievementModel> achievements) async {
    try {
      final key = _keyForUser(userId);
      final jsonList = achievements.map((a) => a.toJson()).toList();
      await _storage.save(key, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('saveAchievementsForUser error: $e');
    }
  }

  // Unlock helper: returns newly unlocked items (0 or 1 item by id)
  List<AchievementModel> unlockIfNeeded(List<AchievementModel> current, String achievementId, {DateTime? when}) {
    final idx = current.indexWhere((a) => a.id == achievementId);
    if (idx == -1) return const [];
    final a = current[idx];
    if (a.isUnlocked) return const [];
    final updated = a.copyWith(isUnlocked: true, unlockedAt: when ?? DateTime.now(), updatedAt: DateTime.now(), progress: a.requirement);
    current[idx] = updated;
    return [updated];
  }

  // Convenience: unlock many ids if they exist in the user's set, return newly unlocked
  Future<List<AchievementModel>> unlockManyForUser(String userId, List<String> ids) async {
    try {
      if (ids.isEmpty) return const <AchievementModel>[];
      final list = await getAchievementsForUser(userId);
      final newly = <AchievementModel>[];
      for (final id in ids) {
        final res = unlockIfNeeded(list, id);
        if (res.isNotEmpty) newly.addAll(res);
      }
      if (newly.isNotEmpty) {
        await saveAchievementsForUser(userId, list);
      }
      return newly;
    } catch (e) {
      debugPrint('unlockManyForUser error: $e');
      return const <AchievementModel>[];
    }
  }
}
