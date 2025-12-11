import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../models/book_mastery.dart';
import '../services/storage_service.dart';
import '../services/bible_service.dart';
import '../models/quest_model.dart';
import '../data/book_reward_map.dart';

/// Tracks and persists lifetime Book Mastery per Bible book.
/// Gentle thresholds; never resets on prestige. Designed to be called from AppProvider hooks.
class BookMasteryService {
  final StorageService _storage;
  final BibleService _bible;

  String? _userId;
  // Canonical mastery map keyed by display book (e.g., 'Genesis')
  final Map<String, BookMastery> _map = <String, BookMastery>{};

  // Seeds used to count book-linked quest rewards
  List<TaskModel> _questSeeds = const <TaskModel>[];

  BookMasteryService(this._storage, this._bible);

  // Caller should set user id after login
  Future<void> setUser(String? userId) async {
    _userId = (userId ?? '').trim().isEmpty ? null : userId!.trim();
    await _load();
  }

  void setQuestSeeds(List<TaskModel> seeds) {
    _questSeeds = List<TaskModel>.from(seeds);
  }

  List<BookMastery> getAll() => _map.values.toList()..sort((a, b) => a.bookId.compareTo(b.bookId));

  BookMastery getOrCreate(String bookId) {
    final key = _displayName(bookId);
    if (_map.containsKey(key)) return _map[key]!;
    final total = _totalChapters(key);
    final created = BookMastery(
      bookId: key,
      chaptersRead: 0,
      totalChapters: total,
      timesCompleted: 0,
      artifactsOwned: 0,
      questsCompleted: 0,
      masteryTier: 'none',
    );
    _map[key] = created;
    _save();
    return created;
  }

  void recordChapterRead(String bookId) {
    try {
      final key = _displayName(bookId);
      final total = _totalChapters(key);
      final current = getOrCreate(key);
      final updated = current.copyWith(
        totalChapters: total,
        chaptersRead: (current.chaptersRead + 1).clamp(0, total),
        masteryTier: _calculateTier(current.copyWith(chaptersRead: (current.chaptersRead + 1).clamp(0, total))),
      );
      _map[key] = updated;
      _save();
    } catch (e) {
      debugPrint('BookMasteryService.recordChapterRead error: $e');
    }
  }

  void recordBookCompleted(String bookId) {
    try {
      final key = _displayName(bookId);
      final total = _totalChapters(key);
      final current = getOrCreate(key);
      final updated = current.copyWith(
        totalChapters: total,
        chaptersRead: total,
        timesCompleted: current.timesCompleted + 1,
        masteryTier: _calculateTier(current.copyWith(
          totalChapters: total,
          chaptersRead: total,
          timesCompleted: current.timesCompleted + 1,
        )),
      );
      _map[key] = updated;
      _save();
    } catch (e) {
      debugPrint('BookMasteryService.recordBookCompleted error: $e');
    }
  }

  void recordQuestCompletedForBook(String bookId) {
    try {
      final key = _displayName(bookId);
      final current = getOrCreate(key);
      final updated = current.copyWith(
        questsCompleted: current.questsCompleted + 1,
        masteryTier: _calculateTier(current.copyWith(questsCompleted: current.questsCompleted + 1)),
      );
      _map[key] = updated;
      _save();
    } catch (e) {
      debugPrint('BookMasteryService.recordQuestCompletedForBook error: $e');
    }
  }

  // Sync artifacts owned count for a book using the provided list of owned ids for that book
  void syncArtifactsForBook(String bookId, List<String> ownedArtifactIds) {
    try {
      final key = _displayName(bookId);
      final current = getOrCreate(key);
      final count = ownedArtifactIds.toSet().length;
      final updated = current.copyWith(
        artifactsOwned: count,
        masteryTier: _calculateTier(current.copyWith(artifactsOwned: count)),
      );
      _map[key] = updated;
      _save();
    } catch (e) {
      debugPrint('BookMasteryService.syncArtifactsForBook error: $e');
    }
  }

  // ================== Tier Calculation ==================
  /// Thresholds (gentle):
  /// none:  chaptersRead == 0
  /// lamp:  chaptersRead > 0
  /// olive: chaptersRead == totalChapters OR timesCompleted >= 1
  /// dove:  timesCompleted >= 2 OR (olive-tier AND questsCompleted >= 1)
  /// scroll: (timesCompleted >= 1 AND artifactsOwned >= 1)
  /// crown: (timesCompleted >= 2 AND artifactsOwned == totalArtifactsForBook)
  String _calculateTier(BookMastery m) {
    try {
      final totalArtifacts = _totalArtifactsForBook(m.bookId);
      if (m.chaptersRead <= 0) return 'none';
      // Any chapter read
      if (m.chaptersRead > 0 && (m.chaptersRead < m.totalChapters) && m.timesCompleted <= 0) return 'lamp';
      final olive = (m.chaptersRead >= m.totalChapters && m.totalChapters > 0) || (m.timesCompleted >= 1);
      if (!olive) return 'lamp';
      // Olive baseline
      if (m.timesCompleted >= 2 || (olive && m.questsCompleted >= 1)) {
        // Could be dove or higher
        if (m.timesCompleted >= 2 && m.artifactsOwned >= 1) {
          // Check for crown path
          if (m.timesCompleted >= 2 && totalArtifacts > 0 && m.artifactsOwned >= totalArtifacts) {
            return 'crown';
          }
          // At least dove if two completions
          return 'dove';
        }
        // Dove from olive + quest
        if (m.questsCompleted >= 1) {
          // Scroll condition can supersede if artifacts discovered as well
          if (m.timesCompleted >= 1 && m.artifactsOwned >= 1) return 'scroll';
          return 'dove';
        }
      }
      // Scroll condition independent: completion + at least one artifact discovered
      if (m.timesCompleted >= 1 && m.artifactsOwned >= 1) return 'scroll';
      return 'olive';
    } catch (e) {
      debugPrint('BookMasteryService._calculateTier error: $e');
      return m.masteryTier;
    }
  }

  // ================== Persistence ==================
  String _storageKey() => 'book_mastery_${_userId ?? 'guest'}';

  Future<void> _load() async {
    try {
      _map.clear();
      final raw = _storage.getString(_storageKey());
      if (raw == null || raw.trim().isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        decoded.forEach((k, v) {
          try {
            final bm = BookMastery.fromJson(Map<String, dynamic>.from(v as Map));
            if (bm.bookId.trim().isNotEmpty) {
              _map[_displayName(bm.bookId)] = bm;
            }
          } catch (e) {
            debugPrint('Skipping malformed mastery entry: $e');
          }
        });
      }
      // Sanitize by writing back
      _save();
    } catch (e) {
      debugPrint('BookMasteryService._load error: $e');
    }
  }

  Future<void> _save() async {
    try {
      final serial = <String, Map<String, dynamic>>{};
      _map.forEach((key, value) => serial[key] = value.toJson());
      await _storage.save<String>(_storageKey(), jsonEncode(serial));
    } catch (e) {
      debugPrint('BookMasteryService._save error: $e');
    }
  }

  // ================== Helpers ==================
  String _displayName(String anyBook) {
    try {
      final disp = _bible.refToDisplay(anyBook);
      return disp.trim();
    } catch (_) {
      return anyBook.trim();
    }
  }

  int _totalChapters(String displayBook) {
    try {
      // bible service knows chapter counts for standard canon
      return _bible.getChapterCount(displayBook);
    } catch (_) {
      return 0;
    }
  }

  // Union of known artifacts linked to this book: book reward map + quest seeds with scriptureReference in this book
  int _totalArtifactsForBook(String displayBook) {
    try {
      final key = displayBook.trim();
      final fromBookMap = List<String>.from(kBookRewardMap[key] ?? const <String>[]);
      final fromQuests = <String>{};
      for (final q in _questSeeds) {
        try {
          final ref = (q.scriptureReference ?? '').trim();
          if (ref.isEmpty) continue;
          // Crude startsWith or contains check on display name
          if (ref.toLowerCase().startsWith(key.toLowerCase()) || ref.toLowerCase().contains('$key '.toLowerCase())) {
            for (final id in q.possibleRewardGearIds) {
              if (id.trim().isNotEmpty) fromQuests.add(id.trim());
            }
            if ((q.guaranteedFirstClearGearId ?? '').trim().isNotEmpty) {
              fromQuests.add(q.guaranteedFirstClearGearId!.trim());
            }
          }
        } catch (_) {}
      }
      final all = {...fromBookMap, ...fromQuests};
      return all.length;
    } catch (e) {
      debugPrint('BookMasteryService._totalArtifactsForBook error: $e');
      return 0;
    }
  }
}
