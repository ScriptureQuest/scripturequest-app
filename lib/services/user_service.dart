import '../utils/integrity/serial_queue.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:level_up_your_faith/models/user_model.dart';
import 'package:level_up_your_faith/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class UserService {
  static const String _storageKey = 'current_user';
  static const String _lastStreakCheckKey = 'last_streak_check';
  final StorageService _storage;
  static final _balanceQueue = SerialQueue();
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
      // Keep the original bytes and identity for recovery. Never overwrite a corrupt profile.
      rethrow;
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
    await _balanceQueue.run(() async {
      final saved = await getCurrentUser();
      await _saveUser(user.copyWith(
          currentXP: saved.currentXP,
          totalXP: saved.totalXP,
          currentLevel: saved.currentLevel,
          currency: saved.currency,
          streakTokens: saved.streakTokens,
          rewardReceipts: saved.rewardReceipts,
          updatedAt: DateTime.now()));
    });
  }

  // Unified Reward System helpers
  Future<UserModel> addCurrency(int amount, {String? receiptId}) =>
      _changeBalance(currency: amount, receiptId: receiptId);

  Future<UserModel> addStreakTokens(int amount, {String? receiptId}) =>
      _changeBalance(streakTokens: amount, receiptId: receiptId);

  Future<UserModel> addXP(int amount, {String? receiptId}) =>
      _changeBalance(xp: amount, receiptId: receiptId);

  Future<UserModel> _changeBalance(
          {int xp = 0,
          int currency = 0,
          int streakTokens = 0,
          String? receiptId}) =>
      _balanceQueue.run(() async {
        final user = await getCurrentUser();
        if (receiptId != null && user.rewardReceipts.contains(receiptId))
          return user;
        if (xp < 0)
          throw ArgumentError.value(xp, 'xp', 'XP grants cannot be negative');
        var level = user.currentLevel;
        if (level < 1)
          throw StateError(
              'Invalid saved level; preserve profile for recovery');
        var remaining = user.currentXP + xp;
        while (remaining >= level * 100) {
          remaining -= level * 100;
          level++;
        }
        final updated = user.copyWith(
          currentLevel: level,
          currentXP: remaining,
          totalXP: user.totalXP + xp,
          currency: (user.currency + currency).clamp(0, 1 << 31),
          streakTokens: (user.streakTokens + streakTokens).clamp(0, 1 << 31),
          rewardReceipts: [
            ...user.rewardReceipts,
            if (receiptId != null) receiptId
          ],
          updatedAt: DateTime.now(),
        );
        // Receipt and balance are one persisted profile, so a retry cannot pay twice.
        await _saveUser(updated);
        return updated;
      });

  Future<UserModel> levelUp(int currentXP, int totalXP) async {
    final user = await getCurrentUser();
    return addXP(totalXP - user.totalXP);
  }

  Future<UserModel> updateStreak() => _balanceQueue.run(() async {
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
          lastCheckDate = DateTime(
              int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
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

        final newLongestStreak =
            newStreak > user.longestStreak ? newStreak : user.longestStreak;

        await _storage.save(_lastStreakCheckKey, todayString);

        final updatedUser = user.copyWith(
          streakDays: newStreak,
          longestStreak: newLongestStreak,
          updatedAt: DateTime.now(),
        );
        await _saveUser(updatedUser);
        return updatedUser;
      });

  Future<UserModel> checkStreakStatus() => _balanceQueue.run(() async {
        final user = await getCurrentUser();
        final lastCheck = _storage.getString(_lastStreakCheckKey);

        if (lastCheck == null) return user;

        final parts = lastCheck.split('-');
        final lastCheckDate = DateTime(
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
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
      });

  Future<UserModel> unlockAchievement(String achievementId) =>
      _balanceQueue.run(() async {
        final user = await getCurrentUser();
        if (user.achievements.contains(achievementId)) return user;

        final achievements = List<String>.from(user.achievements)
          ..add(achievementId);
        final updatedUser = user.copyWith(
          achievements: achievements,
          updatedAt: DateTime.now(),
        );
        await _saveUser(updatedUser);
        return updatedUser;
      });

  Future<UserModel> completeVerse(String verseId) =>
      _balanceQueue.run(() async {
        final user = await getCurrentUser();
        if (user.completedVerses.contains(verseId)) return user;

        final verses = List<String>.from(user.completedVerses)..add(verseId);
        final updatedUser = user.copyWith(
          completedVerses: verses,
          updatedAt: DateTime.now(),
        );
        await _saveUser(updatedUser);
        return updatedUser;
      });

  Future<UserModel> completeQuest(String questId) =>
      _balanceQueue.run(() async {
        final user = await getCurrentUser();
        if (user.completedQuests.contains(questId)) return user;

        final quests = List<String>.from(user.completedQuests)..add(questId);
        final updatedUser = user.copyWith(
          completedQuests: quests,
          updatedAt: DateTime.now(),
        );
        await _saveUser(updatedUser);
        return updatedUser;
      });

  Future<void> _saveUser(UserModel user) async {
    await _storage.save(_storageKey, jsonEncode(user.toJson()));
  }
}
