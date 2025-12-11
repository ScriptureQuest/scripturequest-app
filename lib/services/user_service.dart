import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:level_up_your_faith/models/user_model.dart';
import 'package:level_up_your_faith/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class UserService {
  static const String _storageKey = 'current_user';
  static const String _lastStreakCheckKey = 'last_streak_check';
  final StorageService _storage;
  final _uuid = const Uuid();

  UserService(this._storage);

  Future<UserModel> getCurrentUser() async {
    try {
      final jsonString = _storage.getString(_storageKey);
      if (jsonString == null) {
        final newUser = await _createDefaultUser();
        return newUser;
      }
      return UserModel.fromJson(jsonDecode(jsonString));
    } catch (e) {
      debugPrint('Error loading user: $e');
      return await _createDefaultUser();
    }
  }

  Future<UserModel> _createDefaultUser() async {
    final now = DateTime.now();
    final user = UserModel(
      id: _uuid.v4(),
      username: 'Warrior',
      email: 'warrior@faith.com',
      avatarUrl: '',
      createdAt: now,
      updatedAt: now,
    );
    await _saveUser(user);
    return user;
  }

  Future<void> updateUser(UserModel user) async {
    await _saveUser(user.copyWith(updatedAt: DateTime.now()));
  }

  // Unified Reward System helpers
  Future<UserModel> addCurrency(int amount) async {
    final user = await getCurrentUser();
    final updated = user.copyWith(
      currency: (user.currency + amount).clamp(0, 1 << 31),
      updatedAt: DateTime.now(),
    );
    await _saveUser(updated);
    return updated;
  }

  Future<UserModel> addStreakTokens(int amount) async {
    final user = await getCurrentUser();
    final updated = user.copyWith(
      streakTokens: (user.streakTokens + amount).clamp(0, 1 << 31),
      updatedAt: DateTime.now(),
    );
    await _saveUser(updated);
    return updated;
  }

  Future<UserModel> addXP(int amount) async {
    final user = await getCurrentUser();
    final newXP = user.currentXP + amount;
    final newTotalXP = user.totalXP + amount;
    
    if (newXP >= user.xpToNextLevel) {
      return await levelUp(newXP, newTotalXP);
    }
    
    final updatedUser = user.copyWith(
      currentXP: newXP,
      totalXP: newTotalXP,
      updatedAt: DateTime.now(),
    );
    await _saveUser(updatedUser);
    return updatedUser;
  }

  Future<UserModel> levelUp(int currentXP, int totalXP) async {
    final user = await getCurrentUser();
    final newLevel = user.currentLevel + 1;
    final remainingXP = currentXP - user.xpToNextLevel;
    
    final updatedUser = user.copyWith(
      currentLevel: newLevel,
      currentXP: remainingXP,
      totalXP: totalXP,
      updatedAt: DateTime.now(),
    );
    await _saveUser(updatedUser);
    return updatedUser;
  }

  Future<UserModel> updateStreak() async {
    final user = await getCurrentUser();
    final lastCheck = _storage.getString(_lastStreakCheckKey);
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    
    if (lastCheck == todayString) {
      return user;
    }
    
    DateTime? lastCheckDate;
    if (lastCheck != null) {
      final parts = lastCheck.split('-');
      lastCheckDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    }
    
    int newStreak = user.streakDays;
    if (lastCheckDate == null) {
      newStreak = 1;
    } else {
      final diff = today.difference(lastCheckDate).inDays;
      if (diff == 1) {
        newStreak++;
      } else if (diff > 1) {
        newStreak = 1;
      }
    }
    
    final newLongestStreak = newStreak > user.longestStreak ? newStreak : user.longestStreak;
    
    await _storage.save(_lastStreakCheckKey, todayString);
    
    final updatedUser = user.copyWith(
      streakDays: newStreak,
      longestStreak: newLongestStreak,
      updatedAt: DateTime.now(),
    );
    await _saveUser(updatedUser);
    return updatedUser;
  }

  Future<UserModel> checkStreakStatus() async {
    final user = await getCurrentUser();
    final lastCheck = _storage.getString(_lastStreakCheckKey);
    
    if (lastCheck == null) return user;
    
    final parts = lastCheck.split('-');
    final lastCheckDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final today = DateTime.now();
    final diff = today.difference(lastCheckDate).inDays;
    
    if (diff > 1) {
      final updatedUser = user.copyWith(
        streakDays: 0,
        updatedAt: DateTime.now(),
      );
      await _saveUser(updatedUser);
      return updatedUser;
    }
    
    return user;
  }

  Future<UserModel> unlockAchievement(String achievementId) async {
    final user = await getCurrentUser();
    if (user.achievements.contains(achievementId)) return user;
    
    final achievements = List<String>.from(user.achievements)..add(achievementId);
    final updatedUser = user.copyWith(
      achievements: achievements,
      updatedAt: DateTime.now(),
    );
    await _saveUser(updatedUser);
    return updatedUser;
  }

  Future<UserModel> completeVerse(String verseId) async {
    final user = await getCurrentUser();
    if (user.completedVerses.contains(verseId)) return user;
    
    final verses = List<String>.from(user.completedVerses)..add(verseId);
    final updatedUser = user.copyWith(
      completedVerses: verses,
      updatedAt: DateTime.now(),
    );
    await _saveUser(updatedUser);
    return updatedUser;
  }

  Future<UserModel> completeQuest(String questId) async {
    final user = await getCurrentUser();
    if (user.completedQuests.contains(questId)) return user;
    
    final quests = List<String>.from(user.completedQuests)..add(questId);
    final updatedUser = user.copyWith(
      completedQuests: quests,
      updatedAt: DateTime.now(),
    );
    await _saveUser(updatedUser);
    return updatedUser;
  }

  Future<void> _saveUser(UserModel user) async {
    await _storage.save(_storageKey, jsonEncode(user.toJson()));
  }
}
