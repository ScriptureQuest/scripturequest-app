import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:level_up_your_faith/services/storage_service.dart';

/// Local-only user stats for the Unified Progress Engine.
/// Tracks simple counters; no networking; resilient to partial/corrupt data.
class UserStatsService {
  final StorageService _storage;
  UserStatsService(this._storage);

  String _key(String uid) => 'user_stats_$uid';

  Future<Map<String, int>> _load(String uid) async {
    try {
      final raw = _storage.getString(_key(uid));
      if (raw == null || raw.trim().isEmpty) return <String, int>{};
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final out = <String, int>{};
        decoded.forEach((k, v) {
          try {
            final key = (k as String).trim();
            final val = int.tryParse('$v') ?? 0;
            if (key.isNotEmpty) out[key] = val;
          } catch (_) {}
        });
        return out;
      }
      throw const FormatException('Invalid saved statistics');
    } catch (e) {
      debugPrint('UserStatsService._load error: $e');
      rethrow;
    }
  }

  Future<void> _save(String uid, Map<String, int> stats) async {
    try {
      await _storage.save(_key(uid), jsonEncode(stats));
    } catch (e) {
      debugPrint('UserStatsService._save error: $e');
      rethrow;
    }
  }

  Future<int> _inc(String uid, String key, {int by = 1}) async {
    final stats = await _load(uid);
    final prev = stats[key] ?? 0;
    final next = prev + by;
    stats[key] = next;
    await _save(uid, stats);
    return next;
  }

  /// Counter and receipt share one persisted record. Retrying an event heals
  /// partially completed XP/stat writes without incrementing the counter twice.
  Future<int> incrementOnce(String uid, String counter, String receipt) async {
    final stats = await _load(uid);
    final key = 'receipt:$counter:$receipt';
    if (stats[key] == 1) return stats[counter] ?? 0;
    stats[counter] = (stats[counter] ?? 0) + 1;
    stats[key] = 1;
    await _save(uid, stats);
    return stats[counter]!;
  }

  // Public counter APIs
  Future<int> incChaptersCompleted(String uid) =>
      _inc(uid, 'totalChaptersCompleted');
  Future<int> incQuizzesCompleted(String uid) =>
      _inc(uid, 'totalQuizzesCompleted');
  Future<int> incQuizzesPassed(String uid) => _inc(uid, 'totalQuizzesPassed');
  Future<int> incTasksCompleted(String uid) => _inc(uid, 'tasksCompleted');
  Future<int> incReflectionsCompleted(String uid) =>
      _inc(uid, 'reflectionsCompleted');
  Future<int> incQuestStepsCompleted(String uid) =>
      _inc(uid, 'questStepsCompleted');
  Future<int> incReadingPlanDaysCompleted(String uid) =>
      _inc(uid, 'readingPlanDaysCompleted');
  Future<int> incStreakDaysKept(String uid) => _inc(uid, 'streakDaysKept');
  Future<int> incStreakBreaks(String uid) => _inc(uid, 'streakBreaks');

  Future<Map<String, int>> getAll(String uid) => _load(uid);
}
