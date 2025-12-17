import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:io' show Platform;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:level_up_your_faith/models/user_model.dart';
import 'package:level_up_your_faith/models/verse_model.dart';
import 'package:level_up_your_faith/models/quest_model.dart';
import 'package:level_up_your_faith/models/achievement_model.dart';
import 'package:level_up_your_faith/models/quest.dart' as board;
import 'package:level_up_your_faith/models/completed_board_quest.dart';
import 'package:level_up_your_faith/services/storage_service.dart';
import 'package:level_up_your_faith/services/user_service.dart';
import 'package:level_up_your_faith/services/verse_service.dart';
import 'package:level_up_your_faith/services/quest_service.dart';
  import 'package:level_up_your_faith/services/quest_board_service.dart';
  import 'package:level_up_your_faith/services/quest_progress_service.dart';
import 'package:level_up_your_faith/services/achievement_service.dart';
import 'package:level_up_your_faith/services/reflection_service.dart';
import 'package:level_up_your_faith/services/journal_service.dart';
import 'package:level_up_your_faith/models/journal_entry.dart';
import 'package:level_up_your_faith/models/leaderboard_player.dart';
import 'package:level_up_your_faith/services/leaderboard_service.dart';
import 'package:level_up_your_faith/models/friend_model.dart';
import 'package:level_up_your_faith/services/friend_service.dart';
import 'package:level_up_your_faith/services/bible_service.dart';
import 'package:level_up_your_faith/services/kjv_bible_service.dart';
import 'package:level_up_your_faith/models/verse_bookmark.dart';
import 'package:level_up_your_faith/services/bookmark_service.dart';
import 'package:uuid/uuid.dart';
import 'package:level_up_your_faith/services/reward_service.dart';
import 'package:level_up_your_faith/services/titles_service.dart';
import 'package:level_up_your_faith/services/inventory_service.dart';
import 'package:level_up_your_faith/services/gear_inventory_service.dart';
import 'package:level_up_your_faith/services/loot_service.dart';
import 'package:level_up_your_faith/services/book_reward_service.dart';
import 'package:level_up_your_faith/services/book_mastery_service.dart';
  import 'package:level_up_your_faith/services/equipment_service.dart';
  import 'package:level_up_your_faith/services/faith_power_service.dart';
import 'package:level_up_your_faith/data/book_reward_map.dart';
import 'package:level_up_your_faith/models/reward.dart';
import 'package:level_up_your_faith/models/player_inventory.dart';
import 'package:level_up_your_faith/services/progress/progress_engine.dart';
import 'package:level_up_your_faith/services/progress/progress_event.dart';
import 'package:level_up_your_faith/models/inventory_item.dart';
import 'package:level_up_your_faith/models/questline.dart';
import 'package:level_up_your_faith/services/questline_service.dart';
  import 'package:level_up_your_faith/models/reward_event.dart';
import 'package:level_up_your_faith/models/book_mastery.dart';
  import 'package:level_up_your_faith/models/gear_item.dart';
  import 'package:level_up_your_faith/models/reading_plan.dart';
  import 'package:level_up_your_faith/services/reading_plan_service.dart';
import 'package:level_up_your_faith/services/chapter_quiz_service.dart';
  import 'package:level_up_your_faith/data/title_seeds.dart';
  import 'package:level_up_your_faith/services/user_stats_service.dart';

// Memorization status for favorite verses
enum MemorizationStatus { newItem, practicing, learned }

// ================== App Theme Packs v2.0 ==================
/// App visual theme packs (all dark-safe), saved per user.
enum AppThemeMode {
  sacredDark,
  bedtimeCalm,
  oliveDawn,
  oceanDeep,
}

// Internal DTO for verse highlighting entries (v1.0.1)
class _HighlightEntry {
  final String colorKey; // 'sun' | 'mint' | 'violet'
  final DateTime updatedAt;
  const _HighlightEntry({required this.colorKey, required this.updatedAt});

  Map<String, dynamic> toJson() => {
        'c': colorKey,
        't': updatedAt.toIso8601String(),
      };

  static _HighlightEntry? fromJson(Map data) {
    try {
      final c = (data['c'] ?? '').toString().trim();
      const allowed = {'sun', 'mint', 'violet'};
      if (!allowed.contains(c)) return null;
      final tRaw = (data['t'] ?? '').toString().trim();
      final t = DateTime.tryParse(tRaw) ?? DateTime.now();
      return _HighlightEntry(colorKey: c, updatedAt: t);
    } catch (e) {
      debugPrint('HighlightEntry.fromJson error: $e');
      return null;
    }
  }
}

class AppProvider extends ChangeNotifier {
  late final StorageService _storageService;
  late final UserService _userService;
  late final VerseService _verseService;
  late final TaskService _questService;
  late final QuestProgressService _questProgressService;
  late final QuestBoardService _questBoardService;
  late final AchievementService _achievementService;
  late final ReflectionService _reflectionService;
  late final JournalService _journalService;
  final BibleService _bibleService = BibleService.instance;
  final KJVBibleService _kjvBibleService = KJVBibleService();
  late final BookmarkService _bookmarkService;
  late final FriendService _friendService;
  final _uuid = const Uuid();
  final LeaderboardService _leaderboardService = LeaderboardService();
  // Unified reward system services
  late final RewardService _rewardService;
  late final TitlesService _titlesService;
  late final InventoryService _inventoryService;
  late final QuestlineService _questlineService;

  UserModel? _currentUser;
  List<VerseModel> _verses = [];
  List<TaskModel> _quests = [];
  // Quest Board (in-memory) active quests
  List<board.Quest> _activeQuests = [];
  // Quest Board (in-memory) completed quests archive (lightweight metadata)
  List<CompletedBoardQuestEntry> _completedBoardQuests = [];
  List<AchievementModel> _achievements = [];
  List<JournalEntry> _journalEntries = [];
  List<VerseBookmark> _bookmarks = [];
  List<FriendModel> _friends = [];
  bool _isLoading = true;
  bool _initialized = false;
  // XP burst animation trigger state
  int _xpBurstEvent = 0;
  int _xpBurstAmount = 0;
  // UI feedback for Auto-Quest hooks
  int _questProgressEvent = 0; // increment to signal a toast
  String _questProgressMessage = '+Quest Progress';
  int _questTabNudgeEvent = 0; // optional subtle nudge for Quest tab icon
  // Achievement unlock UI signals
  int _achievementUnlockEvent = 0;
  AchievementModel? _latestAchievementUnlock;
  String? _latestAchievementSummary;
  // Last-read Bible reference (in-memory for now)
  String? _lastBibleReference;
  // Optional: last book/chapter remembered for dropdowns
  String? _lastBibleBook;
  int? _lastBibleChapter;
  // Quests for which the scripture was opened at least once (session-only)
  final Set<String> _questsWhereScriptureOpened = <String>{};

  // ================== Questlines ==================
  List<QuestlineProgressView> _activeQuestlines = [];
  int _questlineCompletionEvent = 0;
  String? _latestQuestlineCompletionTitle;
  String? _latestQuestlineRewardsSummary;

  // Questlines v0.6 — Step interaction tracking (ephemeral session-only)
  // Key: "<questlineId>|<stepId>", Value: set of interaction flags
  // e.g., {"readOpened", "journalSaved", "memorizeOpened"}
  final Map<String, Set<String>> _questStepInteractions = <String, Set<String>>{};

  String _questStepKey(String questlineId, String stepId) => '$questlineId|$stepId';

  bool hasQuestStepInteraction(String questlineId, String stepId, String interaction) {
    try {
      final key = _questStepKey(questlineId, stepId);
      final set = _questStepInteractions[key];
      return set != null && set.contains(interaction);
    } catch (e) {
      debugPrint('hasQuestStepInteraction error: $e');
      return false;
    }
  }

  void recordQuestStepInteraction(String questlineId, String stepId, String interaction) {
    try {
      final key = _questStepKey(questlineId, stepId);
      final set = _questStepInteractions.putIfAbsent(key, () => <String>{});
      set.add(interaction);
      notifyListeners();
    } catch (e) {
      debugPrint('recordQuestStepInteraction error: $e');
    }
  }

  // ================== Loot / New Artifact UI signals ==================
  int _newArtifactEvent = 0;
  dynamic _latestNewArtifact;
  // Book Reward Reveal queue
  int _bookRewardQueueEvent = 0; // increment when queue changes
  final List<RewardEvent> _bookRewardQueue = <RewardEvent>[];

  // ================== Inventory & Equip ==================
  PlayerInventory _playerInventory = PlayerInventory.empty();
  GearInventoryService? _gearService; // Injected via ProxyProvider
  LootService? _lootService;
  // Book-specific reward strategy
  BookRewardService? _bookRewardService;
  // Lifetime Book Mastery
  late final BookMasteryService _bookMasteryService;
  // Equipment (soul avatar) — read equipped ids for Faith Power
  EquipmentService? _equipmentService;
  // Faith Power calculator (pure)
  final FaithPowerService _faithPowerService = const FaithPowerService();

  PlayerInventory get playerInventory => _playerInventory;
  Map<String, String?> get equippedGearSlots => _playerInventory.equipped.gearSlots;
  Map<String, String?> get equippedCosmetics => _playerInventory.equipped.cosmetics;
  String? get equippedTitleId => _playerInventory.equipped.titleId;

  // ================== Bible reading progress ==================
  // Map of Canonical Display Book -> set of chapter numbers read
  Map<String, Set<int>> _readChaptersPerBook = <String, Set<int>>{};
  // Storage key: read chapters per user
  String _readChaptersKey(String uid) => 'read_chapters_$uid';

  // ================== Daily Reading Activity (v1.0) ==================
  // Map of yyyy-MM-dd (local) -> chapters read count for that day
  Map<String, int> _dailyChapterReads = <String, int>{};
  String _dailyReadsKey(String uid) => 'daily_reads_$uid';

  // ================== Chapter Quiz (v1.0) ==================
  // Set of keys like 'John:3' for completed quizzes
  Set<String> _completedChapterQuizzes = <String>{};
  String _quizCompletedKey(String uid) => 'completed_chapter_quizzes_$uid';

  // ================== Learning Games (v1.0) ==================
  // Simple counter to track completed learning mini-games (Matching, Scramble, etc.)
  int _learningGamesCompleted = 0;
  String _learningGamesCompletedKey(String uid) => 'learning_games_completed_$uid';
  int get learningGamesCompleted => _learningGamesCompleted;
  Future<void> incrementLearningGamesCompleted() async {
    try {
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return;
      _learningGamesCompleted = (_learningGamesCompleted <= 0) ? 1 : _learningGamesCompleted + 1;
      await _storageService.save<int>(_learningGamesCompletedKey(uid), _learningGamesCompleted);
      // Unlock thresholds
      try {
        if (_learningGamesCompleted >= 1) {
          await unlockAchievementPublic('learning_games_1');
        }
        if (_learningGamesCompleted >= 5) {
          await unlockAchievementPublic('learning_games_5');
        }
        if (_learningGamesCompleted >= 15) {
          await unlockAchievementPublic('learning_games_15');
        }
      } catch (e) {
        debugPrint('learning games unlock check error: $e');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('incrementLearningGamesCompleted error: $e');
    }
  }

  // ================== First-Run Guided Start (v1.0) ==================
  bool _hasSeenGuidedStart = false;
  bool _hasCompletedFirstReading = false;
  bool _hasCompletedFirstJournal = false;
  bool _hasVisitedQuestlines = false;

  bool get hasSeenGuidedStart => _hasSeenGuidedStart;
  bool get hasCompletedFirstReading => _hasCompletedFirstReading;
  bool get hasCompletedFirstJournal => _hasCompletedFirstJournal;
  bool get hasVisitedQuestlines => _hasVisitedQuestlines;

  String _guidedStartSeenKey(String uid) => 'guided_start_seen_$uid';
  String _firstReadingDoneKey(String uid) => 'first_reading_done_$uid';
  String _firstJournalDoneKey(String uid) => 'first_journal_done_$uid';
  String _questlinesVisitedKey(String uid) => 'visited_questlines_$uid';

  // ================== Welcome Back (v1.0) ==================
  DateTime? _lastOpenedAt; // full timestamp
  DateTime? _lastWelcomeShownForDay; // date-only

  DateTime? get lastOpenedAt => _lastOpenedAt;
  DateTime? get lastWelcomeShownForDay => _lastWelcomeShownForDay;

  String _lastOpenedAtKey(String uid) => 'last_opened_at_$uid';
  String _welcomeShownDayKey(String uid) => 'welcome_shown_day_$uid';

  // ================== Verse of the Day (VOTD) ==================
  DateTime? _votdDate; // date-only: when was current VOTD chosen
  String? _votdVerseId; // the verse ID for today's verse

  String _votdDateKey(String uid) => 'votd_date_$uid';
  String _votdVerseIdKey(String uid) => 'votd_verse_id_$uid';

  // Pool of verse references for daily rotation (deterministic, minimal repeats)
  static const List<String> _verseOfDayPool = [
    'John 3:16',
    'Philippians 4:13',
    'Proverbs 3:5-6',
    'Romans 8:28',
    'Psalm 23:1',
    'Isaiah 40:31',
    'Jeremiah 29:11',
    'Matthew 28:20',
    '1 Corinthians 13:4-5',
    'Ephesians 2:8-9',
    'Joshua 1:9',
    'Proverbs 16:3',
    'Matthew 6:33',
    'Psalm 46:1',
    'Romans 12:2',
    'Philippians 4:6-7',
    'Psalm 118:24',
    'James 1:2-3',
    'Isaiah 41:10',
    'Matthew 11:28',
    '2 Corinthians 12:9',
    'Colossians 3:23',
    'Hebrews 11:1',
    'Proverbs 4:23',
    'Psalm 27:1',
    'Romans 15:13',
    'Galatians 5:22-23',
    'John 14:6',
    'Psalm 34:18',
    'Isaiah 43:2',
  ];

  // ================== Onboarding v2.0 ==================
  bool _hasCompletedOnboarding = false;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get shouldShowOnboarding => !_hasCompletedOnboarding;
  // one-time flag to show Home banner right after finishing onboarding
  bool _onboardingWelcomeOnce = false; // ephemeral (not persisted)
  String _onboardingCompletedKey(String uid) => 'has_completed_onboarding_$uid';
  // Consume one-time welcome flag without triggering rebuild loops
  bool consumeOnboardingWelcomeFlag() {
    if (_onboardingWelcomeOnce) {
      _onboardingWelcomeOnce = false;
      return true;
    }
    return false;
  }

  // ================== Cosmetics (local-only helpers for v1.0) ==================
  /// Update the equipped aura id locally without persistence (used by preview/apply of owned cosmetics).
  void setCosmeticAuraLocal(String? auraId) {
    try {
      final cos = {..._playerInventory.equipped.cosmetics};
      cos['aura'] = (auraId == null || auraId.trim().isEmpty) ? null : auraId.trim();
      _playerInventory = _playerInventory.copyWith(equipped: _playerInventory.equipped.copyWith(cosmetics: cos));
      notifyListeners();
    } catch (e) {
      debugPrint('setCosmeticAuraLocal error: $e');
    }
  }

  /// Update the equipped frame id locally without persistence.
  void setCosmeticFrameLocal(String? frameId) {
    try {
      final cos = {..._playerInventory.equipped.cosmetics};
      cos['frame'] = (frameId == null || frameId.trim().isEmpty) ? null : frameId.trim();
      _playerInventory = _playerInventory.copyWith(equipped: _playerInventory.equipped.copyWith(cosmetics: cos));
      notifyListeners();
    } catch (e) {
      debugPrint('setCosmeticFrameLocal error: $e');
    }
  }

  // ================== Titles & Achievements v1.0 flags ==================
  bool _hasCompletedAnyQuestline = false;
  bool get hasCompletedAnyQuestline => _hasCompletedAnyQuestline;
  String _anyQuestlineCompletedKey(String uid) => 'has_completed_any_questline_$uid';

  // ================== Favorite Verses (v1.0) ==================
  // Keys like 'John:3:16' where book is display name
  Set<String> _favoriteVerses = <String>{};
  String _favoriteVersesKey(String uid) => 'favorite_verses_$uid';

  List<String> get favoriteVerseKeys {
    try {
      final list = _favoriteVerses.toList();
      list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return list;
    } catch (e) {
      debugPrint('favoriteVerseKeys error: $e');
      return const <String>[];
    }
  }

  // ================== Verse Highlighting (v1.0.1) ==================

  // Map of verseKey -> entry, using keys like 'John:3:16'
  Map<String, _HighlightEntry> _verseHighlights = <String, _HighlightEntry>{};
  String _verseHighlightsKey(String uid) => 'verse_highlights$uid';

  static bool _isValidHighlightColorKey(String key) {
    switch (key) {
      case 'sun':
      case 'mint':
      case 'violet':
        return true;
      default:
        return false;
    }
  }

  // Utility to format a verse key
  String verseKeyFor(String displayBook, int chapter, int verse) =>
      '${displayBook.trim()}:$chapter:$verse';

  bool hasHighlight(String verseKey) {
    try {
      final k = verseKey.trim();
      if (k.isEmpty) return false;
      return _verseHighlights.containsKey(k);
    } catch (e) {
      debugPrint('hasHighlight error: $e');
      return false;
    }
  }

  // ================== Bookmarks (v1.0) — lightweight keys ==================
  // Format mirrors Favorites/Highlights:
  //  - verse:  "Book:Chapter:Verse"  (e.g., "John:3:16")
  //  - chapter:"Book:Chapter"       (e.g., "John:3")
  // Note: We already have a legacy VerseBookmark list for notes; this is a new,
  // lightweight set used by the v1.0 bookmarks feature and the "Last Reading" entry.
  final Set<String> _bookmarksV1 = <String>{};
  String _bookmarksKeyV1(String uid) => 'bookmarks$uid';

  // Last reading reference (compact key using same format as bookmarks)
  String? _lastReadingKey;
  String _lastReadingStorageKey(String uid) => 'last_reading$uid';

  // Public API
  bool isBookmarked(String key) {
    try {
      final k = _normalizeBookmarkKey(key);
      if (k.isEmpty) return false;
      return _bookmarksV1.contains(k);
    } catch (e) {
      debugPrint('isBookmarked error: $e');
      return false;
    }
  }

  // Toggle bookmark presence. Maintains recency by removing and re-adding to end.
  Future<void> toggleBookmark(String key) async {
    try {
      final k = _normalizeBookmarkKey(key);
      if (k.isEmpty || !_isValidBookmarkKey(k)) {
        debugPrint('toggleBookmark: invalid key "$key" -> "$k"');
        return;
      }
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return;

      if (_bookmarksV1.contains(k)) {
        _bookmarksV1.remove(k);
      } else {
        // Move to most-recent position (LinkedHashSet preserves insertion order)
        _bookmarksV1.remove(k);
        _bookmarksV1.add(k);
      }
      await _persistBookmarksV1(uid);
      notifyListeners();
    } catch (e) {
      debugPrint('toggleBookmark error: $e');
    }
  }

  // Returns bookmark keys ordered by most recent first
  List<String> get bookmarkKeys {
    try {
      final ordered = _bookmarksV1.toList(); // insertion order (oldest -> newest)
      return ordered.reversed.toList(); // newest first
    } catch (e) {
      debugPrint('bookmarkKeys error: $e');
      return const <String>[];
    }
  }

  // Last reading public API
  void recordLastReading(String verseOrChapterKey) {
    try {
      final k = _normalizeBookmarkKey(verseOrChapterKey);
      if (k.isEmpty || !_isValidBookmarkKey(k)) return;
      _lastReadingKey = k;
      // Persist best-effort; no await required in UI path
      final uid = _currentUser?.id ?? '';
      if (uid.isNotEmpty) {
        _storageService.save<String>(_lastReadingStorageKey(uid), k);
      }
      // No notify: UI can poll via getter when needed; avoid rebuilds on navigate
    } catch (e) {
      debugPrint('recordLastReading error: $e');
    }
  }

  String? get lastReadingKey => _lastReadingKey;

  // Helpers
  String _normalizeBookmarkKey(String raw) {
    try {
      final s = raw.trim();
      if (s.isEmpty) return '';
      final parts = s.split(':');
      if (parts.length < 2 || parts.length > 3) {
        return '';
      }
      final bookAny = parts[0].trim();
      final bookDisplay = bibleService.refToDisplay(bookAny).trim();
      final ch = int.tryParse(parts[1].trim());
      if (bookDisplay.isEmpty || ch == null || ch <= 0) return '';
      if (parts.length == 2) return '$bookDisplay:$ch';
      final v = int.tryParse(parts[2].trim());
      if (v == null || v <= 0) return '';
      return '$bookDisplay:$ch:$v';
    } catch (e) {
      debugPrint('_normalizeBookmarkKey error: $e');
      return '';
    }
  }

  bool _isValidBookmarkKey(String key) {
    try {
      final parts = key.split(':');
      if (parts.length == 2) {
        return parts[0].trim().isNotEmpty && (int.tryParse(parts[1].trim()) ?? 0) > 0;
      }
      if (parts.length == 3) {
        return parts[0].trim().isNotEmpty &&
            (int.tryParse(parts[1].trim()) ?? 0) > 0 &&
            (int.tryParse(parts[2].trim()) ?? 0) > 0;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void _loadBookmarksV1(String uid) {
    try {
      _bookmarksV1.clear();
      final raw = _storageService.getString(_bookmarksKeyV1(uid));
      if (raw == null || raw.trim().isEmpty) return;
      List list;
      try {
        final d = jsonDecode(raw);
        if (d is List) {
          list = d;
        } else {
          return;
        }
      } catch (e) {
        debugPrint('bookmarks v1 decode error: $e');
        return;
      }
      for (final e in list) {
        try {
          final s = (e ?? '').toString().trim();
          if (s.isEmpty) continue;
          final normalized = _normalizeBookmarkKey(s);
          if (_isValidBookmarkKey(normalized)) {
            // Preserve list order by adding in sequence
            _bookmarksV1.add(normalized);
          } else {
            debugPrint('Skipping malformed bookmark key: "$s"');
          }
        } catch (err) {
          debugPrint('Skipping malformed bookmark entry: $err');
        }
      }
      // Optional: sanitize by writing back a clean, normalized list
      _persistBookmarksV1(uid);
    } catch (e) {
      debugPrint('_loadBookmarksV1 error: $e');
    }
  }

  Future<void> _persistBookmarksV1(String uid) async {
    try {
      // Save in insertion order; newest should be last
      await _storageService.save<String>(_bookmarksKeyV1(uid), jsonEncode(_bookmarksV1.toList()));
    } catch (e) {
      debugPrint('_persistBookmarksV1 error: $e');
    }
  }

  void _loadLastReadingKey(String uid) {
    try {
      final raw = _storageService.getString(_lastReadingStorageKey(uid));
      final s = (raw == null || raw.trim().isEmpty) ? null : _normalizeBookmarkKey(raw.trim());
      _lastReadingKey = (s != null && _isValidBookmarkKey(s)) ? s : null;
      if (raw != null && s == null) {
        debugPrint('lastReadingKey stored value was malformed; ignoring');
      }
    } catch (e) {
      debugPrint('_loadLastReadingKey error: $e');
      _lastReadingKey = null;
    }
  }

  String? getHighlightColorKey(String verseKey) {
    try {
      final k = verseKey.trim();
      if (k.isEmpty) return null;
      return _verseHighlights[k]?.colorKey;
    } catch (e) {
      debugPrint('getHighlightColorKey error: $e');
      return null;
    }
  }

  Future<void> setHighlight(String verseKey, String colorKey) async {
    try {
      final k = verseKey.trim();
      if (k.isEmpty) return;
      if (!_isValidHighlightColorKey(colorKey)) {
        debugPrint('setHighlight: invalid color "$colorKey"');
        return;
      }
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return;
      _verseHighlights[k] = _HighlightEntry(colorKey: colorKey, updatedAt: DateTime.now());
      await _persistVerseHighlights(uid);
      notifyListeners();
    } catch (e) {
      debugPrint('setHighlight error: $e');
    }
  }

  Future<void> clearHighlight(String verseKey) async {
    try {
      final k = verseKey.trim();
      if (k.isEmpty) return;
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return;
      _verseHighlights.remove(k);
      await _persistVerseHighlights(uid);
      notifyListeners();
    } catch (e) {
      debugPrint('clearHighlight error: $e');
    }
  }

  List<String> get highlightedVerseKeysRecent {
    try {
      final entries = _verseHighlights.entries.toList();
      entries.sort((a, b) => b.value.updatedAt.compareTo(a.value.updatedAt));
      return entries.map((e) => e.key).toList();
    } catch (e) {
      debugPrint('highlightedVerseKeysRecent error: $e');
      return const <String>[];
    }
  }

  Map<String, List<String>> get highlightedByBook {
    final map = <String, List<String>>{};
    try {
      final entries = _verseHighlights.entries.toList();
      entries.sort((a, b) => b.value.updatedAt.compareTo(a.value.updatedAt));
      for (final e in entries) {
        final parts = e.key.split(':');
        if (parts.length != 3) continue;
        final book = parts[0];
        map.putIfAbsent(book, () => <String>[]).add(e.key);
      }
    } catch (e) {
      debugPrint('highlightedByBook error: $e');
    }
    return map;
  }

  Future<void> _persistVerseHighlights(String uid) async {
    try {
      final map = _verseHighlights.map((k, v) => MapEntry(k, v.toJson()));
      await _storageService.save<String>(_verseHighlightsKey(uid), jsonEncode(map));
    } catch (e) {
      debugPrint('_persistVerseHighlights error: $e');
    }
  }

  void _loadVerseHighlights(String uid) {
    try {
      _verseHighlights.clear();
      final raw = _storageService.getString(_verseHighlightsKey(uid));
      if (raw == null || raw.trim().isEmpty) return;
      Map decoded;
      try {
        final d = jsonDecode(raw);
        if (d is Map<String, dynamic>) {
          decoded = d;
        } else if (d is Map) {
          decoded = d.cast<String, dynamic>();
        } else {
          return;
        }
      } catch (e) {
        debugPrint('verse highlights decode error: $e');
        return;
      }
      decoded.forEach((k, v) {
        try {
          final key = (k as String).trim();
          if (key.isEmpty) return;
          if (v is Map<String, dynamic>) {
            final entry = _HighlightEntry.fromJson(v);
            if (entry != null) _verseHighlights[key] = entry;
          } else if (v is Map) {
            final entry = _HighlightEntry.fromJson(v.cast<String, dynamic>());
            if (entry != null) _verseHighlights[key] = entry;
          }
        } catch (e) {
          debugPrint('Skipping malformed highlight entry: $e');
        }
      });
    } catch (e) {
      debugPrint('_loadVerseHighlights error: $e');
    }
  }

  bool isFavoriteVerse(String verseKey) {
    try {
      final k = verseKey.trim();
      if (k.isEmpty) return false;
      return _favoriteVerses.contains(k);
    } catch (e) {
      debugPrint('isFavoriteVerse error: $e');
      return false;
    }
  }

  Future<void> toggleFavoriteVerse(String verseKey) async {
    try {
      final key = verseKey.trim();
      if (key.isEmpty) return;
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return;
      if (_favoriteVerses.contains(key)) {
        _favoriteVerses.remove(key);
      } else {
        _favoriteVerses.add(key);
      }
      await _persistFavoriteVerses(uid);
      notifyListeners();
    } catch (e) {
      debugPrint('toggleFavoriteVerse error: $e');
    }
  }

  Future<void> _persistFavoriteVerses(String uid) async {
    try {
      await _storageService.save<String>(_favoriteVersesKey(uid), jsonEncode(_favoriteVerses.toList()));
    } catch (e) {
      debugPrint('_persistFavoriteVerses error: $e');
    }
  }

  Set<String> _loadFavoriteVerses(String uid) {
    final raw = _storageService.getString(_favoriteVersesKey(uid));
    final set = <String>{};
    if (raw == null) return set;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final e in decoded) {
          final s = (e ?? '').toString().trim();
          if (s.isNotEmpty && s.contains(':')) set.add(s);
        }
      }
    } catch (e) {
      debugPrint('favorite verses decode error: $e');
    }
    return set;
  }

  // ================== Memorization (v1.0) ==================
  final Map<String, MemorizationStatus> _memorizationStatus = <String, MemorizationStatus>{};
  final Map<String, int> _memorizationPracticeCount = <String, int>{};
  String _memStatusKey(String uid) => 'memorization_status_$uid';
  String _memPracticeKey(String uid) => 'memorization_practice_$uid';
  // v1.0 additions: last success day per verse (yyyy-MM-dd), and total successes
  final Map<String, String> _memorizationLastSuccessDay = <String, String>{};
  int _memorizationSuccessTotal = 0;
  String _memLastSuccessDayKey(String uid) => 'memorization_last_success_day_$uid';
  String _memSuccessTotalKey(String uid) => 'memorization_success_total_$uid';

  MemorizationStatus getMemorizationStatus(String verseKey) {
    try {
      final key = verseKey.trim();
      if (key.isEmpty) return MemorizationStatus.newItem;
      return _memorizationStatus[key] ?? MemorizationStatus.newItem;
    } catch (e) {
      debugPrint('getMemorizationStatus error: $e');
      return MemorizationStatus.newItem;
    }
  }

  int getMemorizationPracticeCount(String verseKey) {
    try {
      final key = verseKey.trim();
      if (key.isEmpty) return 0;
      return _memorizationPracticeCount[key] ?? 0;
    } catch (e) {
      debugPrint('getMemorizationPracticeCount error: $e');
      return 0;
    }
  }

  Future<void> recordMemorizationPractice(String verseKey, {int learnedThreshold = 3}) async {
    try {
      final key = verseKey.trim();
      if (key.isEmpty) return;
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return;

      final prev = _memorizationPracticeCount[key] ?? 0;
      final next = prev + 1;
      _memorizationPracticeCount[key] = next;

      // Promote status based on count
      final current = _memorizationStatus[key] ?? MemorizationStatus.newItem;
      if (next >= learnedThreshold) {
        _memorizationStatus[key] = MemorizationStatus.learned;
      } else if (current == MemorizationStatus.newItem && next > 0) {
        _memorizationStatus[key] = MemorizationStatus.practicing;
      }

      await _persistMemorizationState(uid);
      notifyListeners();
    } catch (e) {
      debugPrint('recordMemorizationPractice error: $e');
    }
  }

  Future<void> _persistMemorizationState(String uid) async {
    try {
      // status -> store as map string->string
      final statusMap = <String, String>{};
      _memorizationStatus.forEach((k, v) {
        statusMap[k] = v.name; // enum to string
      });
      await _storageService.save<String>(_memStatusKey(uid), jsonEncode(statusMap));
      await _storageService.save<String>(_memPracticeKey(uid), jsonEncode(_memorizationPracticeCount));
      // v1.0 additions
      await _storageService.save<String>(_memLastSuccessDayKey(uid), jsonEncode(_memorizationLastSuccessDay));
      await _storageService.save<int>(_memSuccessTotalKey(uid), _memorizationSuccessTotal);
    } catch (e) {
      debugPrint('_persistMemorizationState error: $e');
    }
  }

  void _loadMemorizationState(String uid) {
    try {
      // status
      _memorizationStatus.clear();
      final rawStatus = _storageService.getString(_memStatusKey(uid));
      if (rawStatus != null && rawStatus.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawStatus);
          if (decoded is Map) {
            decoded.forEach((k, v) {
              final key = (k as String).trim();
              final val = (v ?? '').toString();
              if (key.isEmpty) return;
              switch (val) {
                case 'learned':
                  _memorizationStatus[key] = MemorizationStatus.learned;
                  break;
                case 'practicing':
                  _memorizationStatus[key] = MemorizationStatus.practicing;
                  break;
                default:
                  _memorizationStatus[key] = MemorizationStatus.newItem;
              }
            });
          }
        } catch (e) {
          debugPrint('memorization status decode error: $e');
        }
      }

      // counts
      _memorizationPracticeCount.clear();
      final rawCount = _storageService.getString(_memPracticeKey(uid));
      if (rawCount != null && rawCount.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawCount);
          if (decoded is Map) {
            decoded.forEach((k, v) {
              final key = (k as String).trim();
              final count = int.tryParse('$v') ?? 0;
              if (key.isEmpty) return;
              if (count > 0) _memorizationPracticeCount[key] = count;
            });
          }
        } catch (e) {
          debugPrint('memorization counts decode error: $e');
        }
      }

      // v1.0 additions: last success day map
      _memorizationLastSuccessDay.clear();
      final rawLast = _storageService.getString(_memLastSuccessDayKey(uid));
      if (rawLast != null && rawLast.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawLast);
          if (decoded is Map) {
            decoded.forEach((k, v) {
              final key = (k as String).trim();
              final day = (v ?? '').toString().trim();
              if (key.isEmpty || day.isEmpty) return;
              // very light validation yyyy-MM-dd
              if (RegExp(r'^\d{4}-\d{2}-\d{2} ?$').hasMatch(day) || RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day)) {
                _memorizationLastSuccessDay[key] = day.substring(0, 10);
              } else {
                _memorizationLastSuccessDay[key] = day;
              }
            });
          }
        } catch (e) {
          debugPrint('memorization lastSuccess decode error: $e');
        }
      }

      // total successes
      try {
        _memorizationSuccessTotal = _storageService.getInt(_memSuccessTotalKey(uid)) ?? 0;
      } catch (_) {
        _memorizationSuccessTotal = 0;
      }
    } catch (e) {
      debugPrint('_loadMemorizationState error: $e');
    }
  }

  // Public aggregates for Achievements hooks
  int get totalVersesMastered {
    try {
      final favs = favoriteVerseKeys.toSet();
      return _memorizationStatus.entries
          .where((e) => favs.contains(e.key) && e.value == MemorizationStatus.learned)
          .length;
    } catch (_) {
      return 0;
    }
  }

  int get totalMemorizationSuccesses => _memorizationSuccessTotal;

  int get totalVersesInTraining {
    try {
      final favs = favoriteVerseKeys.toSet();
      return _memorizationStatus.entries
          .where((e) => favs.contains(e.key) && e.value != MemorizationStatus.learned)
          .length;
    } catch (_) {
      return 0;
    }
  }

  /// v1.0 training outcome: success increments streak, promotes to learned at threshold.
  /// Returns XP awarded (0 if none). Awards XP only first success per verse per day.
  Future<int> recordMemorizationSuccess(String verseKey, {int learnedThreshold = 3, int dailyXp = 10}) async {
    try {
      final key = verseKey.trim();
      if (key.isEmpty) return 0;
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return 0;

      // Increment success streak (reuse practiceCount as streak)
      final prev = _memorizationPracticeCount[key] ?? 0;
      final next = prev + 1;
      _memorizationPracticeCount[key] = next;

      // Promote status based on streak
      final current = _memorizationStatus[key] ?? MemorizationStatus.newItem;
      if (next >= learnedThreshold) {
        _memorizationStatus[key] = MemorizationStatus.learned;
      } else if (current == MemorizationStatus.newItem || current == MemorizationStatus.practicing) {
        _memorizationStatus[key] = MemorizationStatus.practicing;
      }

      // Count total successful sessions
      _memorizationSuccessTotal = (_memorizationSuccessTotal <= 0) ? 1 : _memorizationSuccessTotal + 1;

      // Award XP once per day per verse
      int xpAwarded = 0;
      try {
        final today = _formatYmd(DateTime.now());
        final last = _memorizationLastSuccessDay[key];
        if (last == null || last != today) {
          final base = dailyXp;
          final award = _applyStreakBonusToXp(base);
          if (award > 0) {
            _currentUser = await _rewardService.applyReward(Reward(type: RewardTypes.xp, amount: award, label: '$award XP'), xpOverride: award);
            _triggerXpBurst(award);
            xpAwarded = award;
          }
          _memorizationLastSuccessDay[key] = today;
        }
      } catch (e) {
        debugPrint('memorization success xp award error: $e');
      }

      await _persistMemorizationState(uid);
      notifyListeners();
      // Unlock memorization achievements by aggregate counts
      try {
        final mastered = totalVersesMastered;
        if (mastered >= 1) {
          await unlockAchievementPublic('memory_beginner_1');
        }
        if (mastered >= 3) {
          await unlockAchievementPublic('memory_builder_3');
        }
        if (mastered >= 5) {
          await unlockAchievementPublic('memory_keeper_5');
        }
      } catch (e) {
        debugPrint('memorization achievements unlock error: $e');
      }
      return xpAwarded;
    } catch (e) {
      debugPrint('recordMemorizationSuccess error: $e');
      return 0;
    }
  }

  /// v1.0 training outcome: failure resets streak to 0, keeps status practicing (or new).
  Future<void> recordMemorizationFailure(String verseKey) async {
    try {
      final key = verseKey.trim();
      if (key.isEmpty) return;
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return;

      _memorizationPracticeCount[key] = 0;
      final current = _memorizationStatus[key] ?? MemorizationStatus.newItem;
      _memorizationStatus[key] = (current == MemorizationStatus.newItem) ? MemorizationStatus.newItem : MemorizationStatus.practicing;
      await _persistMemorizationState(uid);
      notifyListeners();
    } catch (e) {
      debugPrint('recordMemorizationFailure error: $e');
    }
  }

  // Display-only aggregate: total completed chapter quizzes
  int get totalCompletedQuizzes {
    try {
      return _completedChapterQuizzes.length;
    } catch (e) {
      debugPrint('totalCompletedQuizzes error: $e');
      return 0;
    }
  }

  bool hasCompletedQuiz(String bookId, int chapter) {
    try {
      if (bookId.trim().isEmpty || chapter <= 0) return false;
      final b = _normalizeDisplayBook(bookId);
      return _completedChapterQuizzes.contains('$b:$chapter');
    } catch (e) {
      debugPrint('hasCompletedQuiz error: $e');
      return false;
    }
  }

  bool isQuizAvailable(String bookId, int chapter) {
    try {
      if (bookId.trim().isEmpty || chapter <= 0) return false;
      final b = _normalizeDisplayBook(bookId);
      return ChapterQuizService.getQuizForChapter(b, chapter) != null;
    } catch (e) {
      debugPrint('isQuizAvailable error: $e');
      return false;
    }
  }

  bool shouldOfferQuiz(String bookId, int chapter) {
    try {
      return isQuizAvailable(bookId, chapter) && !hasCompletedQuiz(bookId, chapter);
    } catch (_) {
      return false;
    }
  }

  Future<void> markQuizCompleted(String bookId, int chapter, {bool awardXp = true}) async {
    try {
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return;
      final b = _normalizeDisplayBook(bookId);
      final key = '$b:$chapter';
      if (_completedChapterQuizzes.contains(key)) return; // first-time only

      _completedChapterQuizzes.add(key);
      await _persistCompletedQuizzes(uid);
      notifyListeners();

      // Optional Book Mastery nudge: treat as a small quest-like event
      try {
        _bookMasteryService.recordQuestCompletedForBook(b);
      } catch (e) {
        debugPrint('quiz mastery bonus error: $e');
      }

      if (awardXp) {
        try {
          const base = 15; // gentle XP, slightly less than reading a chapter
          final award = _applyStreakBonusToXp(base);
          if (award > 0) {
            _currentUser = await _userService.addXP(award);
            _triggerXpBurst(award);
          }
        } catch (e) {
          debugPrint('quiz xp award error: $e');
        }
      }
    } catch (e) {
      debugPrint('markQuizCompleted error: $e');
    }
  }

  // ================== Bible reading streak ==================
  int _currentBibleStreak = 0;
  int _longestBibleStreak = 0;
  DateTime? _lastBibleReadDate; // date-only (local)
  
  // Streak celebration animation event (increment to trigger animation)
  int _streakCelebrationEvent = 0;
  int _streakCelebrationValue = 0;

  int get currentBibleStreak => _currentBibleStreak;
  int get longestBibleStreak => _longestBibleStreak;
  DateTime? get lastBibleReadDate => _lastBibleReadDate;
  int get streakCelebrationEvent => _streakCelebrationEvent;
  int get streakCelebrationValue => _streakCelebrationValue;

  // Streak XP bonus is derived: active when current Bible streak >= 7 days
  bool get hasStreakBonus => _currentBibleStreak >= 7;
  // Public alias per spec
  bool get hasStreakXpBonus => hasStreakBonus;

  // ================== Quest Board public getters ==================
  List<CompletedBoardQuestEntry> get completedBoardQuests {
    final copy = [..._completedBoardQuests];
    copy.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return copy;
  }

  String _completedBoardQuestsKey(String uid) => 'completed_board_quests_$uid';

  String _streakCurrentKey(String uid) => 'bible_streak_current_$uid';
  String _streakLongestKey(String uid) => 'bible_streak_longest_$uid';
  String _streakLastDateKey(String uid) => 'bible_streak_last_date_$uid';

  // ================== Streak Recovery (Quest) ==================
  int? _previousBibleStreakBeforeBreak;
  String? _activeStreakRecoveryQuestId;
  DateTime? _streakRecoveryExpiresAt;

  // Keys per user
  String _streakRecoveryPrevKey(String uid) => 'streak_recovery_prev_$uid';
  String _streakRecoveryQuestIdKey(String uid) => 'streak_recovery_quest_id_$uid';
  String _streakRecoveryExpiresKey(String uid) => 'streak_recovery_expires_$uid';

  // Public accessors
  bool get hasActiveStreakRecoveryQuest =>
      _activeStreakRecoveryQuestId != null &&
      _streakRecoveryExpiresAt != null &&
      DateTime.now().isBefore(_streakRecoveryExpiresAt!);
  DateTime? get streakRecoveryExpiresAt => _streakRecoveryExpiresAt;
  int? get previousBibleStreakBeforeBreak => _previousBibleStreakBeforeBreak;
  String? get activeStreakRecoveryQuestId => _activeStreakRecoveryQuestId;

  // ================== Reading Plans (v1.0) ==================
  String? _activeReadingPlanId; // only one active at a time
  DateTime? _activeReadingPlanStartDate;
  // planId -> completed step indices (0-based)
  Map<String, Set<int>> _planProgress = <String, Set<int>>{};

  String _planActiveIdKey(String uid) => 'reading_plan_active_$uid';
  String _planActiveStartKey(String uid) => 'reading_plan_active_start_$uid';
  String _planProgressKey(String uid) => 'reading_plan_progress_$uid';

  List<ReadingPlan> get availableReadingPlans => ReadingPlanService.getSeeds();
  String? get activeReadingPlanId => _activeReadingPlanId;
  DateTime? get activeReadingPlanStartDate => _activeReadingPlanStartDate;
  ReadingPlan? get activeReadingPlan =>
      (_activeReadingPlanId == null || _activeReadingPlanId!.isEmpty) ? null : ReadingPlanService.getById(_activeReadingPlanId!);

  Set<int> _completedStepsForPlan(String planId) => _planProgress[planId] ?? <int>{};

  bool isPlanStepCompleted(ReadingPlan plan, int stepIndex) {
    try {
      return _completedStepsForPlan(plan.planId).contains(stepIndex);
    } catch (_) {
      return false;
    }
  }

  double getPlanProgressPercent() {
    try {
      final plan = activeReadingPlan;
      if (plan == null || plan.totalDays == 0) return 0.0;
      final done = _completedStepsForPlan(plan.planId).length;
      return (done / plan.totalDays).clamp(0.0, 1.0);
    } catch (e) {
      debugPrint('getPlanProgressPercent error: $e');
      return 0.0;
    }
  }

  ReadingPlanStep? getCurrentPlanStep() {
    try {
      final plan = activeReadingPlan;
      if (plan == null) return null;
      final completed = _completedStepsForPlan(plan.planId);
      for (int i = 0; i < plan.days.length; i++) {
        if (!completed.contains(i)) return plan.days[i];
      }
      return null; // all done
    } catch (e) {
      debugPrint('getCurrentPlanStep error: $e');
      return null;
    }
  }

  String? getFirstUnreadReferenceForCurrentStep() {
    try {
      final plan = activeReadingPlan;
      final step = getCurrentPlanStep();
      if (plan == null || step == null) return null;
      for (final ref in step.referenceList) {
        final parsed = bibleService.parseReference(ref);
        final book = (parsed['bookDisplay'] as String? ?? '').trim();
        final ch = parsed['chapter'] as int?;
        if (book.isEmpty || ch == null || ch <= 0) continue;
        if (!isChapterRead(book, ch)) return '$book $ch';
      }
      // fallback to first
      return step.referenceList.isNotEmpty ? step.referenceList.first : null;
    } catch (e) {
      debugPrint('getFirstUnreadReferenceForCurrentStep error: $e');
      return null;
    }
  }

  Future<void> activatePlan(String planId) async {
    try {
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return;
      _activeReadingPlanId = planId;
      _activeReadingPlanStartDate = DateTime.now();
      // Ensure progress map exists
      _planProgress.putIfAbsent(planId, () => <int>{});
      await _persistReadingPlanState(uid);
      notifyListeners();
    } catch (e) {
      debugPrint('activatePlan error: $e');
    }
  }

  Future<void> clearActivePlan() async {
    try {
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return;
      _activeReadingPlanId = null;
      _activeReadingPlanStartDate = null;
      await _persistReadingPlanState(uid);
      notifyListeners();
    } catch (e) {
      debugPrint('clearActivePlan error: $e');
    }
  }

  Future<void> completePlanStep(int stepIndex, {bool awardXp = true}) async {
    try {
      final plan = activeReadingPlan;
      if (plan == null) return;
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return;
      final set = _planProgress.putIfAbsent(plan.planId, () => <int>{});
      if (set.contains(stepIndex)) return; // already done
      set.add(stepIndex);
      await _persistReadingPlanState(uid);
      notifyListeners();

      // Gentle synergy: progress Daily quest once for step completion
      try {
        incrementQuestProgressForType('daily', amount: 1);
        completeQuestByType('daily');
      } catch (e) {
        debugPrint('plan step daily quest progress error: $e');
      }

      // Unified Progress Engine: emit reading plan day completed (XP/Stats/Achievements handled there)
      try {
        await ProgressEngine.instance.emit(
          ProgressEvent.readingPlanDayCompleted(plan.planId, stepIndex),
        );
      } catch (e) {
        debugPrint('emit readingPlanDayCompleted error: $e');
      }
    } catch (e) {
      debugPrint('completePlanStep error: $e');
    }
  }

  Future<void> _persistReadingPlanState(String uid) async {
    try {
      await _storageService.save<String>(_planActiveIdKey(uid), _activeReadingPlanId ?? '');
      if (_activeReadingPlanStartDate != null) {
        await _storageService.save<String>(_planActiveStartKey(uid), _activeReadingPlanStartDate!.toIso8601String());
      } else {
        await _storageService.delete(_planActiveStartKey(uid));
      }
      final serializable = <String, List<int>>{};
      _planProgress.forEach((k, v) => serializable[k] = v.toList()..sort());
      await _storageService.save<String>(_planProgressKey(uid), jsonEncode(serializable));
    } catch (e) {
      debugPrint('_persistReadingPlanState error: $e');
    }
  }

  void _loadReadingPlanState(String uid) {
    try {
      final id = _storageService.getString(_planActiveIdKey(uid)) ?? '';
      _activeReadingPlanId = id.trim().isEmpty ? null : id.trim();
      final startStr = _storageService.getString(_planActiveStartKey(uid));
      _activeReadingPlanStartDate = (startStr == null || startStr.trim().isEmpty) ? null : DateTime.tryParse(startStr.trim());
      final raw = _storageService.getString(_planProgressKey(uid));
      _planProgress = <String, Set<int>>{};
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            decoded.forEach((k, v) {
              final pid = (k as String).trim();
              if (pid.isEmpty) return;
              final list = (v as List<dynamic>? ?? const <dynamic>[])// ignore: avoid_dynamic_calls
                  .map((e) => int.tryParse('$e') ?? -1)
                  .where((n) => n >= 0)
                  .toSet();
              _planProgress[pid] = list;
            });
          }
        } catch (e) {
          debugPrint('reading plan progress decode error: $e');
        }
      }
    } catch (e) {
      debugPrint('_loadReadingPlanState error: $e');
    }
  }

  // Canonical total chapters per book using BibleService display names
  static const Map<String, int> bookTotalChapters = {
    // Old Testament
    'Genesis': 50,
    'Exodus': 40,
    'Leviticus': 27,
    'Numbers': 36,
    'Deuteronomy': 34,
    'Joshua': 24,
    'Judges': 21,
    'Ruth': 4,
    '1 Samuel': 31,
    '2 Samuel': 24,
    '1 Kings': 22,
    '2 Kings': 25,
    '1 Chronicles': 29,
    '2 Chronicles': 36,
    'Ezra': 10,
    'Nehemiah': 13,
    'Esther': 10,
    'Job': 42,
    'Psalms': 150,
    'Proverbs': 31,
    'Ecclesiastes': 12,
    'Song of Solomon': 8,
    'Isaiah': 66,
    'Jeremiah': 52,
    'Lamentations': 5,
    'Ezekiel': 48,
    'Daniel': 12,
    'Hosea': 14,
    'Joel': 3,
    'Amos': 9,
    'Obadiah': 1,
    'Jonah': 4,
    'Micah': 7,
    'Nahum': 3,
    'Habakkuk': 3,
    'Zephaniah': 3,
    'Haggai': 2,
    'Zechariah': 14,
    'Malachi': 4,
    // New Testament
    'Matthew': 28,
    'Mark': 16,
    'Luke': 24,
    'John': 21,
    'Acts': 28,
    'Romans': 16,
    '1 Corinthians': 16,
    '2 Corinthians': 13,
    'Galatians': 6,
    'Ephesians': 6,
    'Philippians': 4,
    'Colossians': 4,
    '1 Thessalonians': 5,
    '2 Thessalonians': 3,
    '1 Timothy': 6,
    '2 Timothy': 4,
    'Titus': 3,
    'Philemon': 1,
    'Hebrews': 13,
    'James': 5,
    '1 Peter': 5,
    '2 Peter': 3,
    '1 John': 5,
    '2 John': 1,
    '3 John': 1,
    'Jude': 1,
    'Revelation': 22,
  };

  UserModel? get currentUser => _currentUser;
  // Convenience getters for leaderboard and UI bindings
  int get currentLevel => _currentUser?.currentLevel ?? 1;
  int get currentXp => _currentUser?.currentXP ?? 0;
  bool get isProfilePublic => _currentUser?.isProfilePublic ?? true;
  String? get profileTagline => _currentUser?.tagline;
  List<VerseModel> get verses => _verses;
  List<TaskModel> get quests => _quests;
  List<AchievementModel> get achievements => _achievements;
  List<board.Quest> get activeQuests => _activeQuests;
  List<AchievementModel> get unlockedAchievements => _achievements.where((a) => a.isUnlocked).toList();
  List<AchievementModel> get lockedAchievements => _achievements.where((a) => !a.isUnlocked).toList();
  bool get isLoading => _isLoading;
  int get xpBurstEvent => _xpBurstEvent;
  int get xpBurstAmount => _xpBurstAmount;
  int get questProgressEvent => _questProgressEvent;
  String get questProgressMessage => _questProgressMessage;
  int get questTabNudgeEvent => _questTabNudgeEvent;
  int get achievementUnlockEvent => _achievementUnlockEvent;
  AchievementModel? get latestAchievementUnlock => _latestAchievementUnlock;
  String? get latestAchievementSummary => _latestAchievementSummary;
  List<QuestlineProgressView> get activeQuestlines => _activeQuestlines;
  int get questlineCompletionEvent => _questlineCompletionEvent;
  String? get latestQuestlineCompletionTitle => _latestQuestlineCompletionTitle;
  String? get latestQuestlineRewardsSummary => _latestQuestlineRewardsSummary;
  int get newArtifactEvent => _newArtifactEvent;
  dynamic get latestNewArtifact => _latestNewArtifact;
  int get bookRewardQueueEvent => _bookRewardQueueEvent;
  int get pendingBookRewardsCount => _bookRewardQueue.length;
  List<JournalEntry> get journalEntries => _journalEntries;
  List<VerseBookmark> get bookmarks => _bookmarks;
  List<FriendModel> get friends => _friends;
  String? get lastBibleReference => _lastBibleReference;
  String? get lastBibleBook => _lastBibleBook;
  int? get lastBibleChapter => _lastBibleChapter;
  Set<String> get questsWhereScriptureOpened => _questsWhereScriptureOpened;

  // ================== Guided Start public helpers ==================
  Future<void> markGuidedStartSeen() async {
    try {
      if (_hasSeenGuidedStart) return;
      _hasSeenGuidedStart = true;
      final uid = _currentUser?.id ?? '';
      if (uid.isNotEmpty) {
        await _storageService.save<bool>(_guidedStartSeenKey(uid), true);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('markGuidedStartSeen error: $e');
    }
  }

  Future<void> markFirstReadingDone() async {
    try {
      if (_hasCompletedFirstReading) return;
      _hasCompletedFirstReading = true;
      final uid = _currentUser?.id ?? '';
      if (uid.isNotEmpty) {
        await _storageService.save<bool>(_firstReadingDoneKey(uid), true);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('markFirstReadingDone error: $e');
    }
  }

  Future<void> markFirstJournalDone() async {
    try {
      if (_hasCompletedFirstJournal) return;
      _hasCompletedFirstJournal = true;
      final uid = _currentUser?.id ?? '';
      if (uid.isNotEmpty) {
        await _storageService.save<bool>(_firstJournalDoneKey(uid), true);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('markFirstJournalDone error: $e');
    }
  }

  Future<void> markQuestlinesVisited() async {
    try {
      if (_hasVisitedQuestlines) return;
      _hasVisitedQuestlines = true;
      final uid = _currentUser?.id ?? '';
      if (uid.isNotEmpty) {
        await _storageService.save<bool>(_questlinesVisitedKey(uid), true);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('markQuestlinesVisited error: $e');
    }
  }

  UserService get userService => _userService;
  VerseService get verseService => _verseService;
  TaskService get questService => _questService;
  QuestBoardService get questBoardService => _questBoardService;
  AchievementService get achievementService => _achievementService;
  ReflectionService get reflectionService => _reflectionService;
  JournalService get journalService => _journalService;
  BibleService get bibleService => _bibleService;
  LeaderboardService get leaderboardService => _leaderboardService;
  FriendService get friendService => _friendService;
  BookMasteryService get bookMasteryService => _bookMasteryService;
  // Coerce to KJV-only for now
  String get preferredBibleVersionCode {
    final code = _currentUser?.preferredBibleVersionCode ?? 'KJV';
    if (code.toUpperCase() != 'KJV') return 'KJV';
    return code;
  }

  // ================== User Stats (Unified Progress Engine) ==================
  /// Lightweight accessor for local-only lifetime stats written by ProgressEngine.
  /// Returns a map like {
  ///   'totalChaptersCompleted': 24,
  ///   'totalQuizzesCompleted': 7,
  ///   'totalQuizzesPassed': 5,
  ///   'tasksCompleted': 12,
  ///   'reflectionsCompleted': 5,
  ///   'questStepsCompleted': 8,
  ///   'readingPlanDaysCompleted': 9,
  ///   'streakDaysKept': 14,
  ///   'streakBreaks': 1,
  /// }
  Future<Map<String, int>> getUserStats() async {
    try {
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return <String, int>{};
      final svc = UserStatsService(_storageService);
      return await svc.getAll(uid);
    } catch (e) {
      debugPrint('getUserStats error: $e');
      return <String, int>{};
    }
  }

  // ================== Computed Faith Stats ==================
  /// Faith Power reflects Scripture Quest progress (level, mastery, equipped artifacts).
  /// Read-only derived value (no side effects).
  int get faithPower {
    try {
      final lvl = currentLevel;
      final masteredBooks = totalBooksCompleted; // gentle proxy; v1.1: wire mastery tiers if needed
      final equippedItems = _getEquippedGearItems();
      return _faithPowerService.calculateFaithPower(
        soulLevel: lvl,
        booksMasteredCount: masteredBooks,
        equippedArtifacts: equippedItems,
      );
    } catch (e) {
      debugPrint('faithPower getter error: $e');
      return 0;
    }
  }

  List<GearItem> _getEquippedGearItems() {
    try {
      final eq = _equipmentService?.equipped ?? const {
        SlotType.head: null,
        SlotType.chest: null,
        SlotType.hand: null,
        SlotType.relic1: null,
        SlotType.relic2: null,
        SlotType.aura: null,
      };
      final list = <GearItem>[];
      GearItem? resolve(String? id) => (id == null || id.trim().isEmpty) ? null : _lootService?.getById(id);
      for (final s in [
        SlotType.head,
        SlotType.chest,
        SlotType.hand,
        SlotType.relic1,
        SlotType.relic2,
        SlotType.aura,
      ]) {
        final item = resolve(eq[s]);
        if (item != null) list.add(item);
      }
      return list;
    } catch (e) {
      debugPrint('_getEquippedGearItems error: $e');
      return const <GearItem>[];
    }
  }

  // ================== Theme Packs (v1.0) ==================
  AppThemeMode _themeMode = AppThemeMode.sacredDark;
  AppThemeMode get themeMode => _themeMode;
  String _themeModeKey(String uid) => 'theme_mode$uid';

  Future<void> setThemeMode(AppThemeMode mode) async {
    try {
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      final uid = _currentUser?.id ?? '';
      _themeMode = mode;
      if (uid.isNotEmpty) {
        await _storageService.save<String>(_themeModeKey(uid), mode.name);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('setThemeMode error: $e');
    }
  }

  AppThemeMode _loadThemeModeInternal(String uid) {
    try {
      final raw = (_storageService.getString(_themeModeKey(uid)) ?? '').trim();
      switch (raw) {
        case 'bedtimeCalm':
          return AppThemeMode.bedtimeCalm;
        case 'oliveDawn':
          return AppThemeMode.oliveDawn;
        case 'oceanDeep':
          return AppThemeMode.oceanDeep;
        case 'sacredDark':
          return AppThemeMode.sacredDark;
        default:
          return AppThemeMode.sacredDark;
      }
    } catch (e) {
      debugPrint('_loadThemeModeInternal error: $e');
      return AppThemeMode.sacredDark;
    }
  }
  int get totalQuestsCompleted {
    try {
      return _quests.where((q) => q.isCompleted).length;
    } catch (e) {
      debugPrint('totalQuestsCompleted error: $e');
      return 0;
    }
  }

  int get totalScripturesOpened {
    try {
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return 0;
      final key = 'bible_opened_refs_$uid';
      final raw = _storageService.getString(key);
      if (raw == null) return 0;
      final set = (jsonDecode(raw) as List<dynamic>).map((e) => e.toString()).toSet();
      return set.length;
    } catch (e) {
      debugPrint('totalScripturesOpened decode error: $e');
      return 0;
    }
  }

  int get totalJournalEntries {
    try {
      return _journalEntries.length;
    } catch (e) {
      debugPrint('totalJournalEntries error: $e');
      return 0;
    }
  }

  int get totalAchievementsUnlocked {
    try {
      return unlockedAchievements.length;
    } catch (e) {
      debugPrint('totalAchievementsUnlocked error: $e');
      return 0;
    }
  }

  // ================== Leaderboard Helper ==================
  LeaderboardPlayer get currentLeaderboardPlayer {
    final user = _currentUser;
    return LeaderboardPlayer(
      id: user?.id ?? 'local_me',
      displayName: user?.username.isNotEmpty == true ? user!.username : 'You',
      tagline: user?.tagline,
      level: currentLevel,
      xp: currentXp,
      currentStreak: currentBibleStreak,
      longestStreak: longestBibleStreak,
      booksCompleted: totalBooksCompleted,
      achievementsUnlocked: totalAchievementsUnlocked,
      isCurrentUser: true,
    );
  }

  /// Look up a leaderboard player by id, returning the current user if the id matches,
  /// or one of the local bot players; null if not found.
  LeaderboardPlayer? getLeaderboardPlayerById(String id) {
    try {
      final trimmed = id.trim();
      if (trimmed.isEmpty) return null;
      final me = currentLeaderboardPlayer;
      if (trimmed == me.id) return me;
      return _leaderboardService.findPlayerById(
        id: trimmed,
        currentUserPlayer: me,
      );
    } catch (e) {
      debugPrint('getLeaderboardPlayerById error: $e');
      return null;
    }
  }

  AchievementModel? get highestTierAchievement {
    try {
      if (unlockedAchievements.isEmpty) return null;
      const rank = {
        'Legendary': 4,
        'Epic': 3,
        'Rare': 2,
        'Common': 1,
      };
      final list = [...unlockedAchievements];
      list.sort((a, b) {
        final ra = rank[a.tier] ?? 0;
        final rb = rank[b.tier] ?? 0;
        if (rb != ra) return rb.compareTo(ra); // higher tier first
        // tie-breaker: most recent unlocked first
        final at = a.unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      return list.first;
    } catch (e) {
      debugPrint('highestTierAchievement error: $e');
      return null;
    }
  }

  // ================== Bible completion stats ==================
  int get totalChaptersRead {
    try {
      return _readChaptersPerBook.values.fold<int>(0, (sum, s) => sum + s.length);
    } catch (e) {
      debugPrint('totalChaptersRead error: $e');
      return 0;
    }
  }

  // Count of distinct books with at least one chapter read
  int get distinctBooksRead {
    try {
      return _readChaptersPerBook.entries.where((e) => e.value.isNotEmpty).length;
    } catch (e) {
      debugPrint('distinctBooksRead error: $e');
      return 0;
    }
  }

  int chaptersReadForBook(String book) {
    try {
      final key = _normalizeDisplayBook(book);
      return _readChaptersPerBook[key]?.length ?? 0;
    } catch (e) {
      debugPrint('chaptersReadForBook error: $e');
      return 0;
    }
  }

  bool isChapterRead(String book, int chapter) {
    try {
      final key = _normalizeDisplayBook(book);
      final result = _readChaptersPerBook[key]?.contains(chapter) ?? false;
      if (kDebugMode && result) {
        debugPrint('[CompletionState] isChapterCompleted book=$book chapter=$chapter result=$result');
      }
      return result;
    } catch (e) {
      debugPrint('isChapterRead error: $e');
      return false;
    }
  }

  bool isBookCompleted(String book) {
    try {
      final key = _normalizeDisplayBook(book);
      final total = bookTotalChapters[key] ?? bibleService.getChapterCount(key);
      if (total <= 0) return false;
      final read = _readChaptersPerBook[key]?.length ?? 0;
      return read >= total;
    } catch (e) {
      debugPrint('isBookCompleted error: $e');
      return false;
    }
  }

  int get totalBooksCompleted {
    try {
      int count = 0;
      for (final entry in bookTotalChapters.entries) {
        final read = _readChaptersPerBook[_normalizeDisplayBook(entry.key)]?.length ?? 0;
        if (read >= entry.value) count++;
      }
      return count;
    } catch (e) {
      debugPrint('totalBooksCompleted error: $e');
      return 0;
    }
  }

  String? get mostRecentCompletedBook {
    try {
      if (_achievements.isEmpty) return null;
      final comps = _achievements
          .where((a) => a.id.startsWith('book_completed_') && a.isUnlocked)
          .toList();
      if (comps.isEmpty) return null;
      comps.sort((a, b) => (b.unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
      // Title format: "Completed {Book}"
      final t = comps.first.title;
      if (t.startsWith('Completed ')) {
        return t.substring('Completed '.length);
      }
      return t;
    } catch (e) {
      debugPrint('mostRecentCompletedBook error: $e');
      return null;
    }
  }

  // ================== Faith Title ==================
  String get faithTitle {
    try {
      final lvl = _currentUser?.currentLevel ?? 1;
      if (lvl >= 10) return 'Faith Champion';
      if (lvl >= 5) return 'Scripture Seeker';
      if (totalQuestsCompleted >= 10) return 'Quest Disciple';
      if (totalScripturesOpened >= 10) return 'Bible Explorer';
      return 'New Disciple';
    } catch (e) {
      debugPrint('faithTitle error: $e');
      return 'New Disciple';
    }
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _storageService = await StorageService.getInstance();
    _userService = UserService(_storageService);
    _verseService = VerseService(_storageService);
    _questService = TaskService(_storageService);
    _questProgressService = QuestProgressService(questService: _questService, verseService: _verseService);
    _questBoardService = QuestBoardService();
    _achievementService = AchievementService(_storageService);
    _reflectionService = ReflectionService(_storageService);
    _journalService = JournalService(_storageService);
    // Initialize Book Mastery service (depends on storage + bible)
    _bookMasteryService = BookMasteryService(_storageService, _bibleService);
    _bookmarkService = BookmarkService(_storageService);
    _friendService = FriendService(_storageService);
    // Soul Avatar equipment (for Faith Power): safe to load with current user
    _equipmentService = EquipmentService(_storageService);
    // Unified reward services
    _titlesService = TitlesService(_storageService);
    _inventoryService = InventoryService(_storageService);
    _rewardService = RewardService(_userService, _titlesService, _inventoryService);
    _questlineService = QuestlineService(_storageService, _questService);

    await loadData();
    // Set user for equipment persistence after user is loaded
    try {
      await _equipmentService?.setUser(_currentUser?.id);
    } catch (e) {
      debugPrint('initialize equipmentService.setUser error: $e');
    }
    // Wire mastery to the current user and seeds
    await _bookMasteryService.setUser(_currentUser?.id);
    try {
      _bookMasteryService.setQuestSeeds(_quests);
    } catch (e) {
      debugPrint('initialize mastery setQuestSeeds error: $e');
    }
    await _loadInventoryState();
    await checkDailyTasks();
    // Initialize Quest Board (in-memory) on app load
    ensureQuestsInitialized();

    // Journal entries are loaded on demand by the Journal screen.

    _isLoading = false;
    _initialized = true;
    notifyListeners();
  }

  bool get isInitialized => _initialized;

  // Attach Gear service for LootService wiring
  void attachGearInventory(GearInventoryService gear) {
    try {
      _gearService = gear;
      _lootService = LootService(gear);
      _bookRewardService = BookRewardService(gear, _lootService!);
    } catch (e) {
      debugPrint('attachGearInventory error: $e');
    }
  }

  Future<void> _loadInventoryState() async {
    try {
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) {
        _playerInventory = PlayerInventory.empty();
        return;
      }
      var inv = await _inventoryService.getInventoryForUser(uid);
      // Sync equipped title from TitlesService for canonical source
      final titleRaw = await _titlesService.getEquippedTitle(uid: uid);
      final title = (titleRaw == null || titleRaw.trim().isEmpty) ? null : titleRaw.trim();
      if (inv.equipped.titleId != title) {
        inv = inv.copyWith(equipped: inv.equipped.copyWith(titleId: title));
      }
      _playerInventory = inv;
      notifyListeners();
    } catch (e) {
      debugPrint('_loadInventoryState error: $e');
    }
  }

  // ================== Public Profile updates ==================
  Future<void> updateProfileVisibility(bool isPublic) async {
    try {
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      final updated = _currentUser!.copyWith(isProfilePublic: isPublic);
      await _userService.updateUser(updated);
      _currentUser = updated;
      notifyListeners();
    } catch (e) {
      debugPrint('updateProfileVisibility error: $e');
    }
  }

  Future<void> updateProfileTagline(String? tagline) async {
    try {
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      final t = (tagline == null || tagline.trim().isEmpty) ? null : tagline.trim();
      final updated = _currentUser!.copyWith(tagline: t);
      await _userService.updateUser(updated);
      _currentUser = updated;
      notifyListeners();
    } catch (e) {
      debugPrint('updateProfileTagline error: $e');
    }
  }

  // ================== Bible ==================
  void markQuestScriptureOpened(String questId) {
    try {
      final id = questId.trim();
      if (id.isEmpty) return;
      _questsWhereScriptureOpened.add(id);
      notifyListeners();
    } catch (e) {
      debugPrint('markQuestScriptureOpened error: $e');
    }
  }

  bool hasOpenedScriptureForQuest(String questId) {
    try {
      final id = questId.trim();
      if (id.isEmpty) return false;
      return _questsWhereScriptureOpened.contains(id);
    } catch (e) {
      debugPrint('hasOpenedScriptureForQuest error: $e');
      return false;
    }
  }

  void setLastBibleReference(String reference) {
    final ref = reference.trim();
    if (ref.isEmpty) return;
    try {
      _lastBibleReference = ref;
      notifyListeners();
    } catch (e) {
      debugPrint('setLastBibleReference error: $e');
    }
  }

  void setLastBibleSelection({required String bookDisplay, required int chapter}) {
    final book = bookDisplay.trim();
    if (book.isEmpty || chapter <= 0) return;
    try {
      _lastBibleBook = book;
      _lastBibleChapter = chapter;
      notifyListeners();
    } catch (e) {
      debugPrint('setLastBibleSelection error: $e');
    }
  }

  Future<void> setPreferredBibleVersionCode(String code) async {
    try {
      final coerced = (code.toUpperCase() == 'KJV') ? 'KJV' : 'KJV';
      final user = _currentUser ?? await _userService.getCurrentUser();
      final updated = user.copyWith(preferredBibleVersionCode: coerced);
      await _userService.updateUser(updated);
      _currentUser = updated;
      notifyListeners();
    } catch (e) {
      debugPrint('setPreferredBibleVersionCode error: $e');
    }
  }

  // ================== KJV helpers ==================
  Future<String> loadKjvChapter(String book, int chapter) {
    return _kjvBibleService.getChapterText(book: book, chapter: chapter);
  }

  /// Load a passage using the KJV Bible service.
  /// Returns formatted text with reference + verse content.
  /// If the passage cannot be loaded, returns a user-friendly fallback message.
  Future<String> loadKjvPassage(String reference) async {
    try {
      final ref = reference.trim();
      if (ref.isEmpty) {
        debugPrint('loadKjvPassage: empty reference');
        return 'Verse unavailable';
      }
      debugPrint('loadKjvPassage: loading $ref');
      final text = await _kjvBibleService.getPassage(reference: ref);
      if (text.contains('not available') || text.contains('Error loading')) {
        debugPrint('loadKjvPassage: failed to load $ref - $text');
        return 'Verse unavailable';
      }
      return text;
    } catch (e) {
      debugPrint('loadKjvPassage error for $reference: $e');
      return 'Verse unavailable';
    }
  }

  Future<void> loadData() async {
    _currentUser = await _userService.getCurrentUser();
    _currentUser = await _userService.checkStreakStatus();
    _verses = await _verseService.getAllVerses();
    _quests = await _questService.getAllQuests();
    // Keep mastery quest seeds synced with the currently loaded quests
    try {
      _bookMasteryService.setQuestSeeds(_quests);
    } catch (e) {
      debugPrint('loadData mastery setQuestSeeds error: $e');
    }

    // Load per-user achievements; initialize if missing
    final uid = _currentUser?.id ?? '';
    if (uid.isNotEmpty) {
      _achievements = await _achievementService.getAchievementsForUser(uid);
    } else {
      _achievements = AchievementService.definitions
          .map((d) => d.copyWith(isUnlocked: false, unlockedAt: null, progress: 0))
          .toList();
    }

    // Load completed Quest Board archive per user
    try {
      if (uid.isNotEmpty) {
        await _loadCompletedBoardQuests(uid);
        _trimOldCompletedBoardQuests(days: 30);
      } else {
        _completedBoardQuests = [];
      }
    } catch (e) {
      debugPrint('loadData completed board quests error: $e');
      _completedBoardQuests = [];
    }

    // Load Theme Pack choice per user
    try {
      if (uid.isNotEmpty) {
        _themeMode = _loadThemeModeInternal(uid);
      } else {
        _themeMode = AppThemeMode.sacredDark;
      }
    } catch (e) {
      debugPrint('loadData theme mode error: $e');
      _themeMode = AppThemeMode.sacredDark;
    }

    // Load bookmarks per user (safe)
    try {
      if (uid.isNotEmpty) {
        _bookmarks = await _bookmarkService.getBookmarksForUser(uid);
        _bookmarks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        _bookmarks = [];
      }
    } catch (e) {
      debugPrint('loadData bookmarks error: $e');
    }
    // Load friends per user (safe)
    try {
      if (uid.isNotEmpty) {
        _friends = await _friendService.getFriendsForUser(uid);
      } else {
        _friends = [];
      }
    } catch (e) {
      debugPrint('loadData friends error: $e');
      _friends = [];
    }
    // Load read chapters map per user
    try {
      if (uid.isNotEmpty) {
        _readChaptersPerBook = _loadReadChapters(uid);
      } else {
        _readChaptersPerBook = <String, Set<int>>{};
      }
    } catch (e) {
      debugPrint('loadData readChapters error: $e');
      _readChaptersPerBook = <String, Set<int>>{};
    }

    // Load daily reading activity per user
    try {
      if (uid.isNotEmpty) {
        _dailyChapterReads = _loadDailyReads(uid);
      } else {
        _dailyChapterReads = <String, int>{};
      }
    } catch (e) {
      debugPrint('loadData daily reads error: $e');
      _dailyChapterReads = <String, int>{};
    }

    // Load chapter quiz completion per user
    try {
      if (uid.isNotEmpty) {
        _completedChapterQuizzes = _loadCompletedQuizzes(uid);
      } else {
        _completedChapterQuizzes = <String>{};
      }
    } catch (e) {
      debugPrint('loadData completed quizzes error: $e');
      _completedChapterQuizzes = <String>{};
    }

    // Load learning games completed counter per user
    try {
      if (uid.isNotEmpty) {
        _learningGamesCompleted = _storageService.getInt(_learningGamesCompletedKey(uid)) ?? 0;
      } else {
        _learningGamesCompleted = 0;
      }
    } catch (e) {
      debugPrint('loadData learning games counter error: $e');
      _learningGamesCompleted = 0;
    }

    // Load lightweight Bookmarks v1.0 and Last Reading reference per user
    try {
      if (uid.isNotEmpty) {
        _loadBookmarksV1(uid);
        _loadLastReadingKey(uid);
      } else {
        _bookmarksV1.clear();
        _lastReadingKey = null;
      }
    } catch (e) {
      debugPrint('loadData bookmarks v1/lastReading error: $e');
      _bookmarksV1.clear();
      _lastReadingKey = null;
    }

      // Load Guided Start first-run flags per user
      try {
        if (uid.isNotEmpty) {
          _hasSeenGuidedStart = _storageService.getBool(_guidedStartSeenKey(uid)) ?? false;
          _hasCompletedFirstReading = _storageService.getBool(_firstReadingDoneKey(uid)) ?? false;
          _hasCompletedFirstJournal = _storageService.getBool(_firstJournalDoneKey(uid)) ?? false;
          _hasVisitedQuestlines = _storageService.getBool(_questlinesVisitedKey(uid)) ?? false;
        } else {
          _hasSeenGuidedStart = false;
          _hasCompletedFirstReading = false;
          _hasCompletedFirstJournal = false;
          _hasVisitedQuestlines = false;
        }
      } catch (e) {
        debugPrint('loadData guided start flags error: $e');
        _hasSeenGuidedStart = false;
        _hasCompletedFirstReading = false;
        _hasCompletedFirstJournal = false;
        _hasVisitedQuestlines = false;
      }

      // Load Onboarding v2.0 completion flag per user
      try {
        if (uid.isNotEmpty) {
          _hasCompletedOnboarding = _storageService.getBool(_onboardingCompletedKey(uid)) ?? false;
        } else {
          _hasCompletedOnboarding = false;
        }
      } catch (e) {
        debugPrint('loadData onboarding flag error: $e');
        _hasCompletedOnboarding = false;
      }

    // Load Bible reading streak per user
    try {
      if (uid.isNotEmpty) {
        _currentBibleStreak = _storageService.getInt(_streakCurrentKey(uid)) ?? 0;
        _longestBibleStreak = _storageService.getInt(_streakLongestKey(uid)) ?? 0;
        final lastStr = _storageService.getString(_streakLastDateKey(uid));
        _lastBibleReadDate = (lastStr == null || lastStr.trim().isEmpty)
            ? null
            : _parseYmd(lastStr.trim());
      } else {
        _currentBibleStreak = 0;
        _longestBibleStreak = 0;
        _lastBibleReadDate = null;
      }
    } catch (e) {
      debugPrint('loadData bible streak error: $e');
      _currentBibleStreak = 0;
      _longestBibleStreak = 0;
      _lastBibleReadDate = null;
    }

    // Load Verse of the Day state per user
    try {
      if (uid.isNotEmpty) {
        final votdDateStr = _storageService.getString(_votdDateKey(uid));
        _votdDate = (votdDateStr == null || votdDateStr.trim().isEmpty)
            ? null
            : _parseYmd(votdDateStr.trim());
        _votdVerseId = _storageService.getString(_votdVerseIdKey(uid));
      } else {
        _votdDate = null;
        _votdVerseId = null;
      }
    } catch (e) {
      debugPrint('loadData votd error: $e');
      _votdDate = null;
      _votdVerseId = null;
    }

    // Load Reading Plans state
    try {
      if (uid.isNotEmpty) {
        _loadReadingPlanState(uid);
      } else {
        _activeReadingPlanId = null;
        _activeReadingPlanStartDate = null;
        _planProgress = <String, Set<int>>{};
      }
    } catch (e) {
      debugPrint('loadData reading plans error: $e');
      _activeReadingPlanId = null;
      _activeReadingPlanStartDate = null;
      _planProgress = <String, Set<int>>{};
    }

    // Load streak recovery metadata per user
    try {
      if (uid.isNotEmpty) {
        _previousBibleStreakBeforeBreak = _storageService.getInt(_streakRecoveryPrevKey(uid));
        _activeStreakRecoveryQuestId = _storageService.getString(_streakRecoveryQuestIdKey(uid));
        final expStr = _storageService.getString(_streakRecoveryExpiresKey(uid));
        _streakRecoveryExpiresAt = (expStr == null || expStr.trim().isEmpty) ? null : DateTime.tryParse(expStr.trim());
      } else {
        _previousBibleStreakBeforeBreak = null;
        _activeStreakRecoveryQuestId = null;
        _streakRecoveryExpiresAt = null;
      }
    } catch (e) {
      debugPrint('loadData streak recovery error: $e');
      _previousBibleStreakBeforeBreak = null;
      _activeStreakRecoveryQuestId = null;
      _streakRecoveryExpiresAt = null;
    }
    // Handle expiry if needed on load
    await _checkStreakRecoveryExpiry();

    // Load Favorite Verses and Memorization state
    try {
      if (uid.isNotEmpty) {
        _favoriteVerses = _loadFavoriteVerses(uid);
        _loadMemorizationState(uid);
        // Verse highlights (v1.0.1)
        _loadVerseHighlights(uid);
      } else {
        _favoriteVerses = <String>{};
        _memorizationStatus.clear();
        _memorizationPracticeCount.clear();
        _verseHighlights.clear();
      }
    } catch (e) {
      debugPrint('loadData favorites/memorization error: $e');
      _favoriteVerses = <String>{};
      _memorizationStatus.clear();
      _memorizationPracticeCount.clear();
      _verseHighlights.clear();
    }
    // Load Welcome Back meta per user
    try {
      if (uid.isNotEmpty) {
        final lastOpenedStr = _storageService.getString(_lastOpenedAtKey(uid));
        _lastOpenedAt = (lastOpenedStr == null || lastOpenedStr.trim().isEmpty) ? null : DateTime.tryParse(lastOpenedStr.trim());
        final welcomeDayStr = _storageService.getString(_welcomeShownDayKey(uid));
        _lastWelcomeShownForDay = (welcomeDayStr == null || welcomeDayStr.trim().isEmpty)
            ? null
            : _parseYmd(welcomeDayStr.trim());
      } else {
        _lastOpenedAt = null;
        _lastWelcomeShownForDay = null;
      }
    } catch (e) {
      debugPrint('loadData welcome back meta error: $e');
      _lastOpenedAt = null;
      _lastWelcomeShownForDay = null;
    }
    // Titles & Achievements v1.0 flags
    try {
      if (uid.isNotEmpty) {
        _hasCompletedAnyQuestline = _storageService.getBool(_anyQuestlineCompletedKey(uid)) ?? false;
      } else {
        _hasCompletedAnyQuestline = false;
      }
    } catch (e) {
      debugPrint('loadData titles/achievements flags error: $e');
      _hasCompletedAnyQuestline = false;
    }
    // Load questlines (definitions + active progress)
    try {
      final uid = _currentUser?.id ?? '';
      if (uid.isNotEmpty) {
        final defs = await _questlineService.getAvailableQuestlines(uid);
        final act = await _questlineService.getActiveQuestlines(uid);
        _activeQuestlines = act.map((p) {
          final def = defs.firstWhere((d) => d.id == p.questlineId, orElse: () => defs.first);
          return QuestlineProgressView(questline: def, progress: p);
        }).toList();
      } else {
        _activeQuestlines = [];
      }
    } catch (e) {
      debugPrint('loadData questlines error: $e');
      _activeQuestlines = [];
    }
    notifyListeners();
  }

  Future<void> _loadCompletedBoardQuests(String uid) async {
    try {
      final raw = _storageService.getString(_completedBoardQuestsKey(uid));
      if (raw == null || raw.trim().isEmpty) {
        _completedBoardQuests = [];
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _completedBoardQuests = [];
        return;
      }
      final list = <CompletedBoardQuestEntry>[];
      for (final item in decoded) {
        try {
          if (item is Map<String, dynamic>) {
            list.add(CompletedBoardQuestEntry.fromJson(item));
          } else if (item is Map) {
            list.add(CompletedBoardQuestEntry.fromJson(item.cast<String, dynamic>()));
          }
        } catch (e) {
          debugPrint('Skipping malformed completed quest: $e');
        }
      }
      _completedBoardQuests = list;
      // Sanitize by writing back a clean list
      await _saveCompletedBoardQuests(uid);
    } catch (e) {
      debugPrint('_loadCompletedBoardQuests error: $e');
      _completedBoardQuests = [];
    }
  }

  Future<void> _saveCompletedBoardQuests(String uid) async {
    try {
      final list = _completedBoardQuests.map((e) => e.toJson()).toList();
      await _storageService.save<String>(_completedBoardQuestsKey(uid), jsonEncode(list));
    } catch (e) {
      debugPrint('_saveCompletedBoardQuests error: $e');
    }
  }

  void _trimOldCompletedBoardQuests({int days = 30}) {
    try {
      if (days <= 0) return;
      final cutoff = DateTime.now().subtract(Duration(days: days));
      final before = _completedBoardQuests.length;
      _completedBoardQuests = _completedBoardQuests
          .where((e) => e.completedAt.isAfter(cutoff))
          .toList();
      if (before != _completedBoardQuests.length) {
        final uid = _currentUser?.id ?? '';
        if (uid.isNotEmpty) {
          _saveCompletedBoardQuests(uid);
        }
      }
    } catch (e) {
      debugPrint('_trimOldCompletedBoardQuests error: $e');
    }
  }

  Future<void> checkDailyTasks() async {
    await _questService.createDailyQuests();
    await _questService.createWeeklyQuests();
    await _questService.expireOldQuests();
    _quests = await _questService.getAllQuests();
    notifyListeners();
  }

  Future<void> completeVerse(String verseId) async {
    await _verseService.completeVerse(verseId);
    _currentUser = await _userService.completeVerse(verseId);
    _currentUser = await _userService.updateStreak();
    
    final verse = _verses.firstWhere((v) => v.id == verseId);
    final award = _applyStreakBonusToXp(verse.xpReward);
    _currentUser = await _userService.addXP(award);
    _triggerXpBurst(award);
    
    // Check level achievements after XP gains
    await _checkLevelMilestones();
    await loadData();
  }

  Future<List<AchievementModel>> completeQuest(String questId, {bool claimRewards = true}) async {
    // In-memory Quest Board completion path
    try {
      final index = _activeQuests.indexWhere((q) => q.id == questId);
      if (index != -1) {
        final q = _activeQuests[index];

        // Only complete if:
        // - not already completed
        // - not expired
        // - and progress has reached the goal
        if (!q.isCompleted && !q.isExpired && q.progress >= q.goal) {
          // Apply unified rewards if present; otherwise fallback to xpReward
          try {
            final rewards = (q.rewards.isNotEmpty)
                ? q.rewards
                : [Reward(type: RewardTypes.xp, amount: q.xpReward, label: '${q.xpReward} XP')];
            final labels = <String>[];
            for (final r in rewards) {
              if (r.type == RewardTypes.xp) {
                final amt = _applyStreakBonusToXp(r.amount ?? 0);
                if (amt > 0) {
                  _currentUser = await _rewardService.applyReward(r, xpOverride: amt);
                  _triggerXpBurst(amt);
                  labels.add('$amt XP');
                }
              } else {
                _currentUser = await _rewardService.applyReward(r);
                labels.add(RewardService.formatRewardLabel(r));
              }
            }
            if (labels.isNotEmpty) {
              _emitQuestCompletionToast(labels.join(' • '));
            }
          } catch (e) {
            debugPrint('completeQuest (board) reward award error: $e');
          }

          // Move to completed archive and remove from active board
          try {
            final entry = CompletedBoardQuestEntry(
              id: q.id,
              title: q.title,
              type: q.type,
              xpReward: q.xpReward,
              completedAt: DateTime.now(),
            );
            _completedBoardQuests.add(entry);
            _trimOldCompletedBoardQuests(days: 30);
            final uid = _currentUser?.id ?? '';
            if (uid.isNotEmpty) {
              await _saveCompletedBoardQuests(uid);
            }
          } catch (e) {
            debugPrint('completeQuest (board) archive save error: $e');
          }

          _activeQuests.removeAt(index);
          _nudgeQuestTab();
          notifyListeners();

          // Loot hook: standard quest reward attempt from unowned canonical items
          try {
            final rng = Random();
            final picked = _lootService?.pickRandomUnownedForStandardQuest(rng);
            if (picked != null) {
              final granted = _lootService!.grantItem(picked);
              if (granted != null) {
                emitNewArtifactAcquired(granted);
                // Mastery: if this item maps to a book, sync that book's artifacts
                try {
                  final book = _bookIdForGearId(granted.id);
                  if (book != null) {
                    final owned = _ownedArtifactIdsForBook(book);
                    _bookMasteryService.syncArtifactsForBook(book, owned);
                  }
                } catch (e) {
                  debugPrint('mastery sync after board loot grant error: $e');
                }
              }
            }
          } catch (e) {
            debugPrint('completeQuest (board) loot hook error: $e');
          }
        }

        return const <AchievementModel>[];
      }
    } catch (e) {
      debugPrint('completeQuest (board) error: $e');
    }

    await _questService.completeQuest(questId);
    _currentUser = await _userService.completeQuest(questId);
    
    final quest = _quests.firstWhere((q) => q.id == questId);
    // Mastery: record quest completed for the associated book if derivable
    try {
      final ref = (quest.scriptureReference ?? '').trim();
      if (ref.isNotEmpty) {
        final book = _extractDisplayBookFromRef(ref);
        if (book.isNotEmpty) {
          _bookMasteryService.recordQuestCompletedForBook(book);
        }
      }
    } catch (e) {
      debugPrint('mastery recordQuestCompleted hook error: $e');
    }
    if (claimRewards) {
      try {
        final rewards = (quest.rewards.isNotEmpty)
            ? quest.rewards
            : [Reward(type: RewardTypes.xp, amount: quest.xpReward, label: '${quest.xpReward} XP')];
        final labels = <String>[];
        for (final r in rewards) {
          if (r.type == RewardTypes.xp) {
            final amt = _applyStreakBonusToXp(r.amount ?? 0);
            if (amt > 0) {
              _currentUser = await _rewardService.applyReward(r, xpOverride: amt);
              _triggerXpBurst(amt);
              labels.add('$amt XP');
            }
          } else {
            _currentUser = await _rewardService.applyReward(r);
            labels.add(RewardService.formatRewardLabel(r));
          }
        }
        if (labels.isNotEmpty) {
          _emitQuestCompletionToast(labels.join(' • '));
        }
        // Mark claimed in persistent storage
        await _questService.markQuestClaimed(questId);
      } catch (e) {
        debugPrint('completeQuest reward award error: $e');
      }
    }

    // Quest-specific artifact rewards (metadata-driven): grant and enqueue modal
    try {
      final granted = _lootService?.grantRewardForQuest(quest);
      if (granted != null) {
        emitQuestRewardGranted(quest.id, granted.id);
        // Mastery: if this item maps to a specific book, sync artifact counts for that book
        try {
          final byMap = _bookIdForGearId(granted.id);
          String? bookId = byMap;
          if (bookId == null) {
            final ref = (quest.scriptureReference ?? '').trim();
            if (ref.isNotEmpty) {
              final b = _extractDisplayBookFromRef(ref);
              if (b.isNotEmpty) bookId = b;
            }
          }
          if (bookId != null) {
            final owned = _ownedArtifactIdsForBook(bookId);
            _bookMasteryService.syncArtifactsForBook(bookId, owned);
          }
        } catch (e) {
          debugPrint('mastery sync after quest grant error: $e');
        }
      }
    } catch (e) {
      debugPrint('completeQuest quest-reward grant error: $e');
    }

    final unlocked = <AchievementModel>[];
    // First quest
    final first = await _unlockAchievement('first_quest');
    unlocked.addAll(first);
    // Totals
    try {
      final total = (_currentUser?.completedQuests.length ?? 0);
      if (total >= 10) {
        unlocked.addAll(await _unlockAchievement('ten_quests'));
      }
      if (total >= 50) {
        unlocked.addAll(await _unlockAchievement('fifty_quests'));
      }
    } catch (e) {
      debugPrint('completeQuest milestone check error: $e');
    }

    await _checkLevelMilestones();
    await loadData();

    // Loot hooks (persistent quests)
    try {
      // 1) Standard rarity-weighted attempt
      final rng = Random();
      final picked = _lootService?.pickRandomUnownedForStandardQuest(rng);
      if (picked != null) {
        final granted = _lootService!.grantItem(picked);
        if (granted != null) {
          emitNewArtifactAcquired(granted);
          // Mastery: if this item maps to a book, sync that book's artifacts
          try {
            final book = _bookIdForGearId(granted.id);
            if (book != null) {
              final owned = _ownedArtifactIdsForBook(book);
              _bookMasteryService.syncArtifactsForBook(book, owned);
            }
          } catch (e) {
            debugPrint('mastery sync after standard loot grant error: $e');
          }
        }
      }

      // 2) First-ever quest milestone → Mustard Seed Pendant (alias supported)
      final total = (_currentUser?.completedQuests.length ?? 0);
      if (total == 1) {
        final granted = _lootService?.grantByIdIfUnowned('mustard_seed_pendant');
        if (granted != null) emitNewArtifactAcquired(granted);
      }
    } catch (e) {
      debugPrint('completeQuest loot hooks error: $e');
    }

    // ===== Questline integration: if this quest belongs to an active questline step, mark it complete and possibly advance/completion =====
    try {
      final uid = _currentUser?.id ?? '';
      if (uid.isNotEmpty) {
        final mapping = await _questlineService.questlineStepForQuestId(uid, questId);
        if (mapping != null) {
          final qlId = mapping['questlineId']!;
          final stepId = mapping['stepId']!;
          final updated = await _questlineService.markStepComplete(uid, qlId, stepId);
          if (updated != null) {
            // Refresh local questlines cache
            try {
              final defs = await _questlineService.getAvailableQuestlines(uid);
              _activeQuestlines = (await _questlineService.getActiveQuestlines(uid)).map((p) {
                final def = defs.firstWhere((d) => d.id == p.questlineId, orElse: () => defs.first);
                return QuestlineProgressView(questline: def, progress: p);
              }).toList();
            } catch (e) {
              debugPrint('refresh questlines after step complete error: $e');
            }

            // Any step completed → gentle achievement (idempotent)
            try {
              await unlockAchievementPublic('questline_step_1');
            } catch (e) {
              debugPrint('questline step unlock error: $e');
            }

            // If questline completed now, award final rewards and emit overlay
            if (updated.isCompleted) {
              try {
                final defs = await _questlineService.getAvailableQuestlines(uid);
                final def = defs.firstWhere((d) => d.id == updated.questlineId);
                final labels = <String>[];
                if (def.rewards.isNotEmpty) {
                  for (final r in def.rewards) {
                    if (r.type == RewardTypes.xp) {
                      final amt = _applyStreakBonusToXp(r.amount ?? 0);
                      if (amt > 0) {
                        _currentUser = await _rewardService.applyReward(r, xpOverride: amt);
                        _triggerXpBurst(amt);
                        labels.add('$amt XP');
                      }
                    } else {
                      _currentUser = await _rewardService.applyReward(r);
                      labels.add(RewardService.formatRewardLabel(r));
                    }
                  }
                }
                final summary = labels.where((e) => e.trim().isNotEmpty).join(' • ');
                emitQuestlineCompletion(def.title, summary.isEmpty ? null : summary);
                // Titles & Achievements v1.0 hooks on questline completion
                await _onQuestlineCompleted(def.id);
              } catch (e) {
                debugPrint('questline completion reward error: $e');
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('questline step completion hook error: $e');
    }

    // If this completed quest is the active streak recovery quest, restore streak (previous - 3, min 7)
    try {
      if (_activeStreakRecoveryQuestId != null && questId == _activeStreakRecoveryQuestId && _previousBibleStreakBeforeBreak != null) {
        final previous = _previousBibleStreakBeforeBreak!;
        final restored = previous - 3;
        final restoredStreak = restored < 7 ? 7 : restored;
        _currentBibleStreak = restoredStreak;
        if (restoredStreak > _longestBibleStreak) {
          _longestBibleStreak = restoredStreak;
        }
        // Clear metadata
        _previousBibleStreakBeforeBreak = null;
        _activeStreakRecoveryQuestId = null;
        _streakRecoveryExpiresAt = null;
        await _saveBibleStreakState();
        await _saveStreakRecoveryState();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('streak recovery restore hook error: $e');
    }
    // After any quest completes (persistent path), nudge meta quests that track completion counts
    try {
      await checkActiveQuests(event: 'onQuestCompleted');
    } catch (e) {
      debugPrint('onQuestCompleted hook error: $e');
    }
    return unlocked;
  }

  /// Claim rewards for a previously completed quest (v2.0 modal flow)
  Future<void> claimQuestRewards(String questId) async {
    try {
      final q = _quests.firstWhere((e) => e.id == questId, orElse: () =>
          TaskModel(id: '', title: '', description: '', targetCount: 1, xpReward: 0, startDate: DateTime.now(), createdAt: DateTime.now(), updatedAt: DateTime.now()));
      if (q.id.isEmpty) return;
      if (!q.isCompleted || q.isClaimed) return;
      // Award using existing path
      await completeQuest(questId, claimRewards: true);
      // Refresh local cache
      _quests = await _questService.getAllQuests();
      notifyListeners();
    } catch (e) {
      debugPrint('claimQuestRewards error: $e');
    }
  }

  // ================== Questlines public helpers ==================
  Future<QuestlineProgressView?> enrollInQuestline(String questlineId) async {
    try {
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return null;
      final progress = await _questlineService.enrollInQuestline(uid, questlineId);
      final defs = await _questlineService.getAvailableQuestlines(uid);
      final def = defs.firstWhere((d) => d.id == questlineId, orElse: () => defs.first);
      final view = QuestlineProgressView(questline: def, progress: progress);
      // Update cache
      final idx = _activeQuestlines.indexWhere((v) => v.questline.id == questlineId);
      if (idx == -1) {
        _activeQuestlines = [..._activeQuestlines, view];
      } else {
        _activeQuestlines[idx] = view;
      }
      notifyListeners();
      return view;
    } catch (e) {
      debugPrint('enrollInQuestline error: $e');
      return null;
    }
  }

  Future<List<Questline>> getAvailableQuestlines() async {
    try {
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return const <Questline>[];
      return await _questlineService.getAvailableQuestlines(uid);
    } catch (e) {
      debugPrint('getAvailableQuestlines error: $e');
      return const <Questline>[];
    }
  }

  QuestlineProgressView? getQuestlineProgressView(String questlineId) {
    try {
      return _activeQuestlines.firstWhere((v) => v.questline.id == questlineId);
    } catch (_) {
      return null;
    }
  }

  /// Determine the single "active" questline for the Tonight's Quest card.
  /// Prefers questlines that have at least one step completed and are not finished.
  /// If multiple match, pick the one with the highest completion ratio.
  /// If none have progress, pick the active questline with the highest completion ratio (likely 0%).
  QuestlineProgressView? getActiveQuestline() {
    try {
      if (_activeQuestlines.isEmpty) return null;
      final inProgress = _activeQuestlines
          .where((v) => !v.progress.isCompleted && v.completedSteps > 0)
          .toList();
      if (inProgress.isNotEmpty) {
        inProgress.sort((a, b) => b.completionRatio.compareTo(a.completionRatio));
        return inProgress.first;
      }
      final candidates = _activeQuestlines.where((v) => !v.progress.isCompleted).toList();
      if (candidates.isEmpty) return null;
      candidates.sort((a, b) => b.completionRatio.compareTo(a.completionRatio));
      return candidates.first;
    } catch (e) {
      debugPrint('getActiveQuestline error: $e');
      return null;
    }
  }

  // New aliases after rename: Questlines -> Quests
  QuestlineProgressView? getActiveQuest() {
    return getActiveQuestline();
  }

  /// For a given questline, find the first step (by order) that is not completed.
  QuestlineStep? getNextStepForQuestline(String questlineId) {
    try {
      final view = getQuestlineProgressView(questlineId);
      if (view == null) return null;
      final ordered = [...view.questline.steps]..sort((a, b) => a.order.compareTo(b.order));
      for (final s in ordered) {
        if (!view.progress.completedStepIds.contains(s.id)) return s;
      }
      return null;
    } catch (e) {
      debugPrint('getNextStepForQuestline error: $e');
      return null;
    }
  }

  QuestlineStep? getNextStepForQuest(String questId) {
    return getNextStepForQuestline(questId);
  }

  /// Lightweight sync check for whether a step is completed using cached state.
  bool isQuestStepCompleted(String questlineId, String stepId) {
    try {
      final v = _activeQuestlines.firstWhere((e) => e.questline.id == questlineId, orElse: () =>
          QuestlineProgressView(
            questline: Questline(
              id: questlineId,
              title: '',
              description: '',
              category: 'onboarding',
              steps: const [],
            ),
            progress: QuestlineProgress(questlineId: questlineId, activeStepIds: const [], completedStepIds: const [], stepQuestIds: const {}, dateStarted: DateTime.now()),
          ));
      return v.progress.completedStepIds.contains(stepId);
    } catch (_) {
      return false;
    }
  }

  /// Manually complete a questline step and grant a small XP reward.
  /// Also checks for questline completion and applies final rewards if defined.
  Future<void> markQuestlineStepDone(String questlineId, String stepId, {int stepXp = 25}) async {
    try {
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return;

      final updated = await _questlineService.markStepComplete(uid, questlineId, stepId);
      if (updated == null) return;

      // Refresh active questlines cache
      try {
        final defs = await _questlineService.getAvailableQuestlines(uid);
        _activeQuestlines = (await _questlineService.getActiveQuestlines(uid)).map((p) {
          final def = defs.firstWhere((d) => d.id == p.questlineId, orElse: () => defs.first);
          return QuestlineProgressView(questline: def, progress: p);
        }).toList();
      } catch (e) {
        debugPrint('refresh questlines after manual step complete error: $e');
      }
      // Any step completed → gentle achievement (idempotent)
      try {
        await unlockAchievementPublic('questline_step_1');
      } catch (e) {
        debugPrint('questline step unlock (manual) error: $e');
      }
      notifyListeners();

      // Award small XP for step completion (streak-aware)
      try {
        final award = _applyStreakBonusToXp(stepXp);
        if (award > 0) {
          _currentUser = await _rewardService.applyReward(Reward(type: RewardTypes.xp, amount: award, label: '$award XP'), xpOverride: award);
          _triggerXpBurst(award);
        }
      } catch (e) {
        debugPrint('questline step xp award error: $e');
      }

      // If the questline just completed, apply final rewards and emit overlay signal
      if (updated.isCompleted) {
        try {
          final defs = await _questlineService.getAvailableQuestlines(uid);
          final def = defs.firstWhere((d) => d.id == updated.questlineId);
          final labels = <String>[];
          if (def.rewards.isNotEmpty) {
            for (final r in def.rewards) {
              if (r.type == RewardTypes.xp) {
                final amt = _applyStreakBonusToXp(r.amount ?? 0);
                if (amt > 0) {
                  _currentUser = await _rewardService.applyReward(r, xpOverride: amt);
                  _triggerXpBurst(amt);
                  labels.add('$amt XP');
                }
              } else {
                _currentUser = await _rewardService.applyReward(r);
                labels.add(RewardService.formatRewardLabel(r));
              }
            }
          }
          final summary = labels.where((e) => e.trim().isNotEmpty).join(' • ');
          emitQuestlineCompletion(def.title, summary.isEmpty ? null : summary);
          // Titles & Achievements v1.0 hooks on questline completion
          await _onQuestlineCompleted(def.id);
        } catch (e) {
          debugPrint('questline completion (manual) reward error: $e');
        }
      }
    } catch (e) {
      debugPrint('markQuestlineStepDone error: $e');
    }
  }

  Future<void> markQuestStepDone(String questId, String stepId, {int stepXp = 25}) async {
    return markQuestlineStepDone(questId, stepId, stepXp: stepXp);
  }

  void emitQuestlineCompletion(String questlineTitle, [String? rewardSummary]) {
    try {
      _latestQuestlineCompletionTitle = questlineTitle;
      _latestQuestlineRewardsSummary = (rewardSummary == null || rewardSummary.trim().isEmpty) ? null : rewardSummary.trim();
      _questlineCompletionEvent++;
      notifyListeners();
    } catch (e) {
      debugPrint('emitQuestlineCompletion error: $e');
    }
  }

  void ackQuestlineCompletionSignal() {
    try {
      _questlineCompletionEvent = 0;
      _latestQuestlineCompletionTitle = null;
      _latestQuestlineRewardsSummary = null;
      notifyListeners();
    } catch (e) {
      debugPrint('ackQuestlineCompletionSignal error: $e');
    }
  }

  /// If a quest belongs to an active questline step, returns a short badge label
  String? getQuestlineTagForQuestId(String questId) {
    try {
      for (final v in _activeQuestlines) {
        final map = v.progress.stepQuestIds;
        if (map.values.contains(questId)) {
          final name = v.questline.title;
          if (name.length <= 16) return name;
          return 'Quest';
        }
      }
      return null;
    } catch (e) {
      debugPrint('getQuestlineTagForQuestId error: $e');
      return null;
    }
  }

  Future<void> startQuest(String questId) async {
    await _questService.startQuest(questId);
    await loadData();
  }

  /// Progress scripture reading quests when the user completes a chapter.
  /// This should only be called after confirming meaningful reading (time threshold met).
  Future<void> progressDailyReadingQuest({String? book, int? chapter}) async {
    try {
      // Call QuestProgressService with chapter completion event
      // Use TaskService methods for TaskModel quest progression (not Quest Board)
      await _questProgressService.handleEvent(
        event: 'onChapterComplete',
        payload: {
          'book': book ?? '',
          'chapter': chapter ?? 0,
          'hasMetReadingThreshold': true,
        },
        onApplyProgress: (questId, amount) async {
          // Use TaskService to update TaskModel quests
          await _questService.updateQuestProgress(questId, amount);
          // Also refresh the quests list in memory
          refreshQuests();
        },
        onMarkComplete: (questId) async {
          // Use TaskService to complete TaskModel quests
          await _questService.completeQuest(questId);
          // Also refresh the quests list in memory
          refreshQuests();
        },
      );
      if (kDebugMode) {
        debugPrint('[AppProvider] progressDailyReadingQuest: book=$book, chapter=$chapter');
      }
    } catch (e) {
      debugPrint('progressDailyReadingQuest error: $e');
    }
  }

  Future<void> incrementQuestProgress(String questId, {int amount = 1}) async {
    // First, try to update in-memory Quest Board quest
    final index = _activeQuests.indexWhere((q) => q.id == questId);

    if (index != -1) {
      final q = _activeQuests[index];

      // If it's already completed or expired, do nothing.
      if (q.isCompleted || q.isExpired) {
        return;
      }

      // Clamp progress so it never exceeds the goal.
      final newProgress = (q.progress + amount).clamp(0, q.goal);

      _activeQuests[index] = q.copyWith(
        progress: newProgress,
      );

      notifyListeners();
      return;
    }

    // Fallback to persistent quest system
    try {
      // Guard: only allow manual increments for quests explicitly marked non-auto
      final q = _quests.firstWhere((e) => e.id == questId, orElse: () =>
          TaskModel(id: '', title: '', description: '', targetCount: 1, xpReward: 0, startDate: DateTime.now(), createdAt: DateTime.now(), updatedAt: DateTime.now()));
      if (q.id.isEmpty) return;
      if (q.isAutoTracked) {
        debugPrint('incrementQuestProgress ignored for auto-tracked quest: $questId');
        return;
      }
      await _questService.updateQuestProgress(questId, amount);
      await loadData();
    } catch (e) {
      debugPrint('incrementQuestProgress persistent path error: $e');
    }
  }

  // ================== AUTO-QUEST HOOK SYSTEM (Phase 1) ==================
  // EVENTS: Public entry points to be called from UI/Services
  Future<void> onVerseRead(String verseId) async {
    try {
      await checkActiveQuests(event: 'onVerseRead', payload: {'verseId': verseId});
      // Quest Board auto: treat as a single unit for daily/weekly
      incrementQuestProgressForType('daily', amount: 1);
      incrementQuestProgressForType('weekly', amount: 1);
      completeQuestByType('daily');
      completeQuestByType('weekly');
    } catch (e) {
      debugPrint('onVerseRead error: $e');
    }
  }

  Future<void> onChapterComplete(String bookDisplay, int chapter) async {
    try {
      // Persist chapter read + achievements + streak in existing flow
      await recordChapterRead(bookDisplay, chapter);
      // Also drive auto-quests
      await checkActiveQuests(event: 'onChapterComplete', payload: {
        'book': bookDisplay,
        'chapter': chapter,
      });
      // Seed a gentle book quest based on the current reading context
      try {
        await _questService.ensureBookQuestsForBook(bookDisplay, chapter: chapter);
        _quests = await _questService.getAllQuests();
        notifyListeners();
      } catch (e) {
        debugPrint('ensureBookQuestsForBook hook error: $e');
      }
      // Quest Board auto is already handled inside recordChapterRead for daily/weekly
    } catch (e) {
      debugPrint('onChapterComplete error: $e');
    }
  }

  Future<void> onBookComplete(String bookDisplay) async {
    try {
      try {
        _bookMasteryService.recordBookCompleted(bookDisplay);
      } catch (e) {
        debugPrint('onBookComplete mastery hook error: $e');
      }
      await checkActiveQuests(event: 'onBookComplete', payload: {'book': bookDisplay});
      // A completed book likely implies weekly milestones; nudge the board subtly
      _nudgeQuestTab();
    } catch (e) {
      debugPrint('onBookComplete error: $e');
    }
  }

  Future<void> onStreakMaintained(int currentStreakDay) async {
    try {
      await checkActiveQuests(event: 'onStreakMaintained', payload: {
        'day': currentStreakDay,
      });
      _nudgeQuestTab();
    } catch (e) {
      debugPrint('onStreakMaintained error: $e');
    }
  }

  Future<void> onReflectionWritten(String reflectionId) async {
    try {
      await checkActiveQuests(event: 'onReflectionWritten', payload: {
        'reflectionId': reflectionId,
      });
      // Quest Board auto for reflections
      try {
        incrementQuestProgressForType('reflection', amount: 1);
        completeQuestByType('reflection');
      } catch (e) {
        debugPrint('reflection board auto-progress error: $e');
      }
    } catch (e) {
      debugPrint('onReflectionWritten error: $e');
    }
  }

  // HANDLER: Central dispatcher for evaluating and applying progress
  Future<void> checkActiveQuests({required String event, Map<String, dynamic>? payload}) async {
    try {
      final applied = await _questProgressService.handleEvent(
        event: event,
        payload: payload,
        onApplyProgress: (id, amount) async => await applyProgress(id, amount),
        onMarkComplete: (id) async => await completeQuest(id),
      );
      if (applied > 0) _emitQuestProgressToast(amount: applied);
    } catch (e) {
      debugPrint('checkActiveQuests error: $e');
    }
  }

  // applyProgress: increment progress and clamp to requirement; persist immediately
  Future<void> applyProgress(String questId, int amount) async {
    try {
      await _questService.updateQuestProgress(questId, amount);
      _quests = await _questService.getAllQuests();
      notifyListeners();
    } catch (e) {
      debugPrint('applyProgress error: $e');
    }
  }

  // markQuestComplete: set status to complete, schedule reward/achievements/toast via existing flow
  Future<void> markQuestComplete(String questId) async {
    try {
      await completeQuest(questId);
      _emitQuestCompletionToast();
      _nudgeQuestTab();
    } catch (e) {
      debugPrint('markQuestComplete error: $e');
    }
  }

  void _emitQuestProgressToast({int amount = 1}) {
    try {
      _questProgressMessage = amount > 1 ? '+$amount Quest Progress' : '+Quest Progress';
      _questProgressEvent++;
      notifyListeners();
    } catch (e) {
      debugPrint('_emitQuestProgressToast error: $e');
    }
  }

  void _nudgeQuestTab() {
    try {
      _questTabNudgeEvent++;
      notifyListeners();
    } catch (e) {
      debugPrint('_nudgeQuestTab error: $e');
    }
  }

  void _emitQuestCompletionToast([String? details]) {
    try {
      _questProgressMessage = details == null || details.isEmpty
          ? '+Quest Complete!'
          : '+Quest Complete!  ${details.trim()}';
      _questProgressEvent++;
      notifyListeners();
    } catch (e) {
      debugPrint('_emitQuestCompletionToast error: $e');
    }
  }

  // ================== Achievement Unlock UI signals ==================
  void emitAchievementUnlock(AchievementModel achievement, String? summary) {
    try {
      _latestAchievementUnlock = achievement;
      _latestAchievementSummary = (summary == null || summary.trim().isEmpty) ? null : summary.trim();
      _achievementUnlockEvent++;
      notifyListeners();
    } catch (e) {
      debugPrint('emitAchievementUnlock error: $e');
    }
  }

  void ackAchievementUnlockSignal() {
    try {
      _achievementUnlockEvent = 0;
      _latestAchievementUnlock = null;
      _latestAchievementSummary = null;
      notifyListeners();
    } catch (e) {
      debugPrint('ackAchievementUnlockSignal error: $e');
    }
  }

  // ================== New Artifact UI signals ==================
  void emitNewArtifactAcquired(dynamic gearItem) {
    try {
      _latestNewArtifact = gearItem;
      _newArtifactEvent++;
      notifyListeners();
    } catch (e) {
      debugPrint('emitNewArtifactAcquired error: $e');
    }
  }

  void ackNewArtifactSignal() {
    try {
      _newArtifactEvent = 0;
      _latestNewArtifact = null;
      notifyListeners();
    } catch (e) {
      debugPrint('ackNewArtifactSignal error: $e');
    }
  }

  // ================== Book Reward Reveal queue API ==================
  /// Enqueue a book-completion artifact reveal. Book id should be a display name.
  void emitBookRewardGranted(String bookId, String gearId) {
    try {
      // Determine rarity from canonical item if available
      String rarity = 'common';
      try {
        final item = _lootService?.getById(gearId);
        if (item != null) {
          rarity = item.rarity.name.toLowerCase();
        }
      } catch (_) {}

      _bookRewardQueue.add(RewardEvent(
        bookId: bookId.trim().isEmpty ? null : bookId.trim(),
        questId: null,
        gearId: gearId,
        rarity: rarity,
        timestamp: DateTime.now(),
      ));
      _bookRewardQueueEvent++;
      notifyListeners();
    } catch (e) {
      debugPrint('emitBookRewardGranted error: $e');
    }
  }

  /// Enqueue a quest-completion artifact reveal.
  void emitQuestRewardGranted(String questId, String gearId) {
    try {
      String rarity = 'common';
      try {
        final item = _lootService?.getById(gearId);
        if (item != null) {
          rarity = item.rarity.name.toLowerCase();
        }
      } catch (_) {}

      _bookRewardQueue.add(RewardEvent.forQuest(
        questId: questId,
        gearId: gearId,
        rarity: rarity,
      ));
      _bookRewardQueueEvent++;
      notifyListeners();
    } catch (e) {
      debugPrint('emitQuestRewardGranted error: $e');
    }
  }

  /// Returns and removes the next pending RewardEvent from the queue, or null.
  RewardEvent? dequeueNextBookRewardEvent() {
    try {
      if (_bookRewardQueue.isEmpty) return null;
      final ev = _bookRewardQueue.removeAt(0);
      // Signal queue mutation so listeners can re-check
      _bookRewardQueueEvent++;
      notifyListeners();
      return ev;
    } catch (e) {
      debugPrint('dequeueNextBookRewardEvent error: $e');
      return null;
    }
  }

  // ================== Public UI signal helpers ==================
  /// Emit a user-visible toast for quest progress. Optional custom message.
  void emitQuestProgress([String? message]) {
    try {
      final msg = (message == null || message.trim().isEmpty)
          ? '+Quest Progress'
          : message.trim();
      _questProgressMessage = msg;
      _questProgressEvent++;
      notifyListeners();
    } catch (e) {
      debugPrint('emitQuestProgress error: $e');
    }
  }

  /// Emit a subtle nudge signal for the Quest tab icon.
  void emitQuestTabNudge() {
    try {
      _questTabNudgeEvent++;
      notifyListeners();
    } catch (e) {
      debugPrint('emitQuestTabNudge error: $e');
    }
  }

  /// Acknowledge the quest progress signal to avoid re-trigger on rebuild.
  void ackQuestProgressSignal() {
    try {
      _questProgressEvent = 0;
      _questProgressMessage = '+Quest Progress';
      notifyListeners();
    } catch (e) {
      debugPrint('ackQuestProgressSignal error: $e');
    }
  }

  /// Acknowledge the quest tab nudge signal after animation completes.
  void ackQuestTabNudge() {
    try {
      _questTabNudgeEvent = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('ackQuestTabNudge error: $e');
    }
  }

  // ================== Inventory public helpers ==================
  Future<void> refreshInventory() async {
    try {
      await _loadInventoryState();
    } catch (e) {
      debugPrint('refreshInventory error: $e');
    }
  }

  Future<void> addItemToInventory(InventoryItem item, {bool autoEquip = false}) async {
    try {
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return;
      _playerInventory = await _inventoryService.addItemToInventory(uid, item.id, item, autoEquip: autoEquip);
      notifyListeners();
    } catch (e) {
      debugPrint('addItemToInventory error: $e');
    }
  }

  Future<void> equipItem({required String slotType, required String slotKey, required String itemId}) async {
    try {
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return;
      if (slotType == 'title') {
        await _titlesService.setEquippedTitle(itemId, uid: uid);
        _playerInventory = _playerInventory.copyWith(
          equipped: _playerInventory.equipped.copyWith(titleId: itemId),
        );
      } else {
        _playerInventory = await _inventoryService.equipItem(uid, slotType, slotKey, itemId);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('equipItem error: $e');
    }
  }

  Future<void> unequipItem({required String slotType, required String slotKey}) async {
    try {
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return;
      if (slotType == 'title') {
        await _titlesService.setEquippedTitle('', uid: uid);
        _playerInventory = _playerInventory.copyWith(
          equipped: _playerInventory.equipped.copyWith(titleId: null),
        );
      } else {
        _playerInventory = await _inventoryService.unequipItem(uid, slotType, slotKey);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('unequipItem error: $e');
    }
  }

  /// Equip a specific artifact id into a persistent EquipmentService slot
  /// so Faith Power recalculations reflect immediately. This does not modify
  /// the in-memory GearInventory equipped map used for grid highlights.
  Future<void> equipArtifactForSlot(SlotType slot, String artifactId) async {
    try {
      final svc = _equipmentService;
      if (svc == null) return;
      await svc.equip(slot, artifactId);
      notifyListeners();
    } catch (e) {
      debugPrint('equipArtifactForSlot error: $e');
    }
  }

  /// Unequip an artifact from a specific persistent slot (EquipmentService)
  Future<void> unequipArtifactSlot(SlotType slot) async {
    try {
      final svc = _equipmentService;
      if (svc == null) return;
      await svc.unequip(slot);
      notifyListeners();
    } catch (e) {
      debugPrint('unequipArtifactSlot error: $e');
    }
  }

  /// Equip a canonical Gear item by id using the in-memory GearInventoryService.
  /// Safely no-ops if service is missing or the id is invalid/not owned.
  void equipGear(String gearId) {
    try {
      final id = gearId.trim();
      if (id.isEmpty) return;
      final svc = _gearService;
      if (svc == null) return;
      svc.equipGear(id);
      // Broadcast so views depending on AppProvider can also react if needed.
      notifyListeners();
    } catch (e) {
      debugPrint('equipGear error: $e');
    }
  }

  Future<void> _checkLevelMilestones() async {
    if (_currentUser == null) return;
    final lvl = _currentUser!.currentLevel;
    if (lvl >= 5) {
      await _unlockAchievement('level_5');
    }
    if (lvl >= 10) {
      await _unlockAchievement('level_10');
    }
  }

  List<VerseModel> getVersesByCategory(String category) {
    if (category == 'all') return _verses;
    return _verses.where((v) => v.category == category).toList();
  }

  List<TaskModel> getQuestsByType(String type) {
    // Legacy support: active meant not completed/expired
    return _quests.where((q) => q.type == type && (q.status == 'not_started' || q.status == 'in_progress')).toList();
  }

  List<TaskModel> getQuestsByCategory(String category, {bool includeCompleted = false}) {
    return _quests.where((q) {
      try {
        // Defensive fallbacks in case of corrupted storage data
        final cat = (q.category.isNotEmpty ? q.category : (q.type.isNotEmpty ? q.type : ''));
        final inCategory = (cat == category);
        if (includeCompleted) return inCategory;
        return inCategory && (q.status == 'not_started' || q.status == 'in_progress');
      } catch (e) {
        debugPrint('getQuestsByCategory skipped a malformed quest: $e');
        return false;
      }
    }).toList();
  }

  // ================== Tasks v2.0 helpers ==================
  bool _isSameYmd(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  List<TaskModel> getDailyTasksForToday() {
    try {
      final today = DateTime.now();
      return _quests.where((q) {
        try {
          if (q.status == 'expired') return false;
          final cat = q.resolvedCategory;
          if (cat != TaskCategory.daily) return false;
          if (!q.autoResetDaily) return true; // always show when not auto-resetting
          final last = q.lastCompletedAt ?? q.completedAt;
          if (last == null) return true; // never completed
          return !_isSameYmd(today, last);
        } catch (e) {
          debugPrint('getDailyTasksForToday skip malformed quest: $e');
          return false;
        }
      }).toList();
    } catch (e) {
      debugPrint('getDailyTasksForToday error: $e');
      return const <TaskModel>[];
    }
  }

  List<TaskModel> getNightlyTasksForToday() {
    try {
      final today = DateTime.now();
      return _quests.where((q) {
        try {
          if (q.status == 'expired') return false;
          final cat = q.resolvedCategory;
          if (cat != TaskCategory.nightly) return false;
          if (!q.autoResetDaily) return true; // always show when not auto-resetting
          final last = q.lastCompletedAt ?? q.completedAt;
          if (last == null) return true;
          return !_isSameYmd(today, last);
        } catch (e) {
          debugPrint('getNightlyTasksForToday skip malformed quest: $e');
          return false;
        }
      }).toList();
    } catch (e) {
      debugPrint('getNightlyTasksForToday error: $e');
      return const <TaskModel>[];
    }
  }

  List<TaskModel> getReflectionTasks() {
    try {
      return _quests.where((q) {
        try {
          if (q.status == 'expired') return false;
          final cat = q.resolvedCategory;
          return cat == TaskCategory.reflection;
        } catch (e) {
          debugPrint('getReflectionTasks skip malformed quest: $e');
          return false;
        }
      }).toList();
    } catch (e) {
      debugPrint('getReflectionTasks error: $e');
      return const <TaskModel>[];
    }
  }

  void _triggerXpBurst(int amount) {
    _xpBurstAmount = amount;
    _xpBurstEvent++;
    notifyListeners();
  }

  // ===== Mini-game helper: award small XP once per completion =====
  Future<int> awardMiniGameXp(int baseXp, {String label = 'XP'}) async {
    try {
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return 0;
      final award = _applyStreakBonusToXp(baseXp);
      if (award > 0) {
        _currentUser = await _rewardService.applyReward(
          Reward(type: RewardTypes.xp, amount: award, label: '$award $label'),
          xpOverride: award,
        );
        _triggerXpBurst(award);
      }
      return award;
    } catch (e) {
      debugPrint('awardMiniGameXp error: $e');
      return 0;
    }
  }

  // ================== Quest Board (in-memory) ==================
  void ensureQuestsInitialized() {
    try {
      if (_activeQuests.isEmpty) {
        _activeQuests = _questBoardService.createInitialQuests(DateTime.now());
        notifyListeners();
      }
    } catch (e) {
      debugPrint('ensureQuestsInitialized error: $e');
    }
  }

  void refreshQuests() {
    try {
      final now = DateTime.now();
      if (_questBoardService.shouldRefreshQuests(now, _activeQuests)) {
        _activeQuests = _questBoardService.createInitialQuests(now);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('refreshQuests error: $e');
    }
  }

  // ================== Quest Board auto helpers ==================
  // Increment progress for all active, non-expired quests of the given type.
  // amount is clamped by the quest goal inside the copyWith update.
  void incrementQuestProgressForType(String type, {int amount = 1}) {
    if (_activeQuests.isEmpty) return;

    bool changed = false;

    for (var i = 0; i < _activeQuests.length; i++) {
      final q = _activeQuests[i];
      if (q.type == type && !q.isCompleted && !q.isExpired) {
        final newProgress = (q.progress + amount).clamp(0, q.goal);
        _activeQuests[i] = q.copyWith(
          progress: newProgress,
        );
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  // Complete all quests of a given type that have reached their goal and are valid.
  // Awards XP using the existing XP flow (streak-aware) asynchronously.
  void completeQuestByType(String type) {
    if (_activeQuests.isEmpty) return;

    bool changed = false;

    final toRemove = <int>[];
    for (var i = 0; i < _activeQuests.length; i++) {
      final q = _activeQuests[i];
      if (q.type == type && !q.isCompleted && !q.isExpired && q.progress >= q.goal) {
        // Award XP via existing flow (streak-aware) asynchronously
        () async {
          try {
            final award = _applyStreakBonusToXp(q.xpReward);
            if (award > 0) {
              _currentUser = await _userService.addXP(award);
              _triggerXpBurst(award);
            }
          } catch (e) {
            debugPrint('completeQuestByType xp award error: $e');
          }
        }();

        // Archive entry
        try {
          _completedBoardQuests.add(CompletedBoardQuestEntry(
            id: q.id,
            title: q.title,
            type: q.type,
            xpReward: q.xpReward,
            completedAt: DateTime.now(),
          ));
          _trimOldCompletedBoardQuests(days: 30);
          final uid = _currentUser?.id ?? '';
          if (uid.isNotEmpty) {
            _saveCompletedBoardQuests(uid);
          }
          // Nightly tasks helper achievement
          if (q.type == 'nightly') {
            () async {
              try {
                final count = _completedBoardQuests.where((e) => e.type == 'nightly').length;
                if (count >= 5) {
                  await unlockAchievementPublic('night_scholar_5');
                }
              } catch (e) {
                debugPrint('night_scholar unlock check error: $e');
              }
            }();
          }
        } catch (e) {
          debugPrint('completeQuestByType archive error: $e');
        }

        toRemove.add(i);
        changed = true;
      }
    }

    // Remove in reverse order to keep indices valid
    for (final i in toRemove.reversed) {
      _activeQuests.removeAt(i);
    }

    if (changed) {
      _emitQuestCompletionToast();
      _nudgeQuestTab();
      notifyListeners();
    }
  }

  // ================== Journal ==================
  Future<void> loadJournalEntries() async {
    try {
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) {
        debugPrint('loadJournalEntries: current user id is missing');
        _journalEntries = [];
        notifyListeners();
        return;
      }
      _journalEntries = await _journalService.getEntriesForUser(uid);
      _journalEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading journal entries: $e');
    }
  }

  /// Create a new manual journal entry (Journal v2.0 Phase 1)
  Future<void> createJournalEntry({String? title, String? body, List<String> tags = const <String>[], bool isPinned = false, String? linkedRef, String? linkedRefRoute}) async {
    try {
      final t = (title ?? '').trim();
      final b = (body ?? '').trim();
      if (t.isEmpty && b.isEmpty) return; // avoid empty entries
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return;

      final now = DateTime.now();
      final entry = JournalEntry(
        id: '',
        userId: uid,
        questId: null,
        questTitle: null,
        scriptureReference: null,
        reflectionText: b,
        title: t.isEmpty ? null : t,
        tags: tags,
        isPinned: isPinned,
        spiritualFocus: null,
        questType: null,
        linkedRef: (linkedRef?.trim().isNotEmpty ?? false) ? linkedRef!.trim() : null,
        linkedRefRoute: (linkedRefRoute?.trim().isNotEmpty ?? false) ? linkedRefRoute!.trim() : null,
        createdAt: now,
        updatedAt: now,
      );

      await _journalService.addEntry(entry);
      // Reload to ensure we have the generated id and correct ordering
      await loadJournalEntries();
      // Achievement: first journal entry
      try {
        if (totalJournalEntries >= 1) {
          await unlockAchievementPublic('journal_starter_1');
        }
      } catch (e) {
        debugPrint('journal_starter unlock check error: $e');
      }
      // Achievement: Journaler (5 entries)
      try {
        if (totalJournalEntries >= 5) {
          await unlockAchievementPublic('journaler');
        }
      } catch (e) {
        debugPrint('journaler unlock check error: $e');
      }

      // Unified Progress Engine: treat as a reflection task completion for stats/xp
      try {
        await ProgressEngine.instance.emit(
          ProgressEvent.taskCompleted('reflection_generic', 'reflection'),
        );
      } catch (e) {
        debugPrint('emit reflection taskCompleted error: $e');
      }
    } catch (e) {
      debugPrint('createJournalEntry error: $e');
    }
  }

  /// Update an existing journal entry (Journal v2.0 Phase 1)
  Future<void> updateJournalEntry({
    required JournalEntry original,
    String? title,
    String? body,
    List<String>? tags,
    bool? isPinned,
    String? linkedRef,
    String? linkedRefRoute,
  }) async {
    try {
      final t = (title ?? original.title)?.trim();
      final b = (body ?? original.reflectionText).trim();
      // If both empty, keep as is (no-op)
      if ((t == null || t.isEmpty) && b.isEmpty) return;
      final updated = original.copyWith(
        title: (t != null && t.trim().isNotEmpty) ? t : null,
        reflectionText: b,
        tags: tags ?? original.tags,
        isPinned: isPinned ?? original.isPinned,
        // Preserve existing link unless explicitly changed (v1.0 behavior)
        linkedRef: linkedRef ?? original.linkedRef,
        linkedRefRoute: linkedRefRoute ?? original.linkedRefRoute,
        updatedAt: DateTime.now(),
      );
      await _journalService.updateEntry(updated);
      // Update local list in-place if present
      final idx = _journalEntries.indexWhere((e) => e.id == updated.id);
      if (idx != -1) {
        _journalEntries[idx] = updated;
        // Keep newest first by createdAt
        _journalEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        notifyListeners();
      } else {
        // Fallback: reload cache
        await loadJournalEntries();
      }
    } catch (e) {
      debugPrint('updateJournalEntry error: $e');
    }
  }

  /// Quick toggle to pin/unpin an entry
  Future<void> setJournalEntryPinned(JournalEntry entry, bool value) async {
    try {
      final updated = entry.copyWith(isPinned: value, updatedAt: DateTime.now());
      await _journalService.updateEntry(updated);
      final idx = _journalEntries.indexWhere((e) => e.id == entry.id);
      if (idx != -1) {
        _journalEntries[idx] = updated;
        _journalEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        notifyListeners();
      } else {
        await loadJournalEntries();
      }
    } catch (e) {
      debugPrint('setJournalEntryPinned error: $e');
    }
  }

  Future<List<AchievementModel>> addJournalEntryFromReflection({
    required TaskModel quest,
    required String reflectionText,
  }) async {
    try {
      final text = reflectionText.trim();
      if (text.isEmpty) return const [];
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return const [];

      final now = DateTime.now();
      final entry = JournalEntry(
        id: '',
        userId: uid,
        questId: quest.id,
        questTitle: quest.title,
        scriptureReference: quest.scriptureReference,
        reflectionText: text,
        spiritualFocus: quest.spiritualFocus,
        questType: quest.questType,
        createdAt: now,
        updatedAt: now,
      );

      await _journalService.addEntry(entry);
      // Optimistically update local list
      _journalEntries.insert(0, entry.copyWith());
      notifyListeners();

      // Auto-progress Reflection quest on Quest Board and auto-complete if goal met
      try {
        incrementQuestProgressForType('reflection', amount: 1);
        completeQuestByType('reflection');
      } catch (e) {
        debugPrint('reflection quest auto-progress error: $e');
      }

      // Achievement checks: first reflection, ten reflections
      final unlocked = <AchievementModel>[];
      unlocked.addAll(await _unlockAchievement('first_reflection'));
      try {
        // Get full count to be accurate
        final list = await _journalService.getEntriesForUser(uid);
        // Reflection-only count (entries linked to a quest)
        final reflectionOnly = list.where((e) => (e.questId ?? '').isNotEmpty).length;
        if (reflectionOnly >= 5) {
          await unlockAchievementPublic('quiet_reflections_5');
        }
        if (list.length >= 5) {
          await unlockAchievementPublic('journaler');
        }
        if (list.length >= 10) {
          unlocked.addAll(await _unlockAchievement('ten_reflections'));
        }
      } catch (e) {
        debugPrint('journal reflection count error: $e');
      }
      // Hook into streak recovery quest: when two reads are done (2/3), set final tick to complete (3/3)
      try {
        await _checkStreakRecoveryExpiry();
        if (hasActiveStreakRecoveryQuest && _activeStreakRecoveryQuestId != null) {
          final recoveryId = _activeStreakRecoveryQuestId!;
          final q = _quests.firstWhere((e) => e.id == recoveryId, orElse: () =>
              TaskModel(
                id: '', title: '', description: '', targetCount: 3, xpReward: 0, startDate: DateTime.now(), createdAt: DateTime.now(), updatedAt: DateTime.now()));
          if (q.id.isNotEmpty && q.status != 'completed' && q.status != 'expired' && q.currentProgress >= 2 && q.currentProgress < q.targetCount) {
            await _questService.updateQuestProgress(recoveryId, 1);
            _quests = await _questService.getAllQuests();
            notifyListeners();
          }
        }
      } catch (e) {
        debugPrint('streak recovery quest reflection progress error: $e');
      }
      return unlocked;
    } catch (e) {
      debugPrint('Error adding journal entry: $e');
      return const [];
    }
  }

  // ================== Bible usage tracking ==================
  Future<List<AchievementModel>> recordBibleOpen(String reference) async {
    try {
      final ref = reference.trim();
      if (ref.isEmpty) return const [];
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return const [];

      final key = 'bible_opened_refs_$uid';
      final raw = _storageService.getString(key);
      final set = <String>{};
      if (raw != null) {
        try {
          final arr = (jsonDecode(raw) as List<dynamic>).map((e) => e.toString()).toList();
          set.addAll(arr);
        } catch (e) {
          debugPrint('recordBibleOpen decode error, resetting set: $e');
        }
      }
      set.add(ref);
      await _storageService.save(key, jsonEncode(set.toList()));

      // Daily routine: opening the Bible tab counts as a gentle check-in
      try {
        await checkActiveQuests(event: 'onBibleOpened');
      } catch (e) {
        debugPrint('onBibleOpened hook error: $e');
      }

      final unlocked = <AchievementModel>[];
      unlocked.addAll(await _unlockAchievement('first_scripture_open'));
      if (set.length >= 10) {
        unlocked.addAll(await _unlockAchievement('ten_scriptures_opened'));
      }
      return unlocked;
    } catch (e) {
      debugPrint('recordBibleOpen error: $e');
      return const [];
    }
  }

  // ================== Verse of the Day (VOTD) ==================
  /// Get or rotate the Verse of the Day based on the current calendar date.
  /// Returns a verse reference (e.g., "John 3:16") that stays consistent for the whole day.
  /// Rotates to a new verse on the next calendar day using deterministic selection from the pool.
  String getVerseOfTheDay([DateTime? nowLocal]) {
    try {
      final now = nowLocal ?? DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day); // date-only

      // If we already have a verse for today, return it
      if (_votdDate != null && _votdDate!.year == todayDate.year && _votdDate!.month == todayDate.month && _votdDate!.day == todayDate.day) {
        if (_votdVerseId != null && _votdVerseId!.isNotEmpty) {
          return _votdVerseId!;
        }
      }

      // Pick a new verse for today using deterministic rotation
      final anchorDate = DateTime(2025, 1, 1); // stable anchor for consistent rotation
      final daysSinceAnchor = todayDate.difference(anchorDate).inDays;
      final poolIndex = daysSinceAnchor % _verseOfDayPool.length;
      final newVerseId = _verseOfDayPool[poolIndex];

      // Update state
      _votdDate = todayDate;
      _votdVerseId = newVerseId;

      // Persist
      final uid = _currentUser?.id ?? '';
      if (uid.isNotEmpty) {
        try {
          _storageService.save<String>(_votdDateKey(uid), _formatYmd(todayDate));
          _storageService.save<String>(_votdVerseIdKey(uid), newVerseId);
        } catch (e) {
          debugPrint('getVerseOfTheDay persist error: $e');
        }
      }

      debugPrint('VOTD rotated to: $newVerseId for date: ${_formatYmd(todayDate)}');
      return newVerseId;
    } catch (e) {
      debugPrint('getVerseOfTheDay error: $e');
      return 'John 3:16'; // fallback
    }
  }

  // ================== Record chapter COMPLETED and unlock achievements ==================
  // NOTE: This is only called when user explicitly presses "Complete Chapter" button
  Future<List<AchievementModel>> recordChapterRead(String book, int chapter, {bool hasMetReadingThreshold = false}) async {
    try {
      final b = _normalizeDisplayBook(book);
      if (b.isEmpty || chapter <= 0) return const [];
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return const [];

      // Load current map from storage (defensive)
      final currentMap = _loadReadChapters(uid);
      final set = currentMap.putIfAbsent(b, () => <int>{});
      final hadBefore = set.contains(chapter);
      set.add(chapter);
      await _persistReadChapters(uid, currentMap);
      _readChaptersPerBook = currentMap;
      
      if (kDebugMode) {
        final count = _readChaptersPerBook[b]?.length ?? 0;
        debugPrint('[CompletionState] completedChaptersCount=$count for book=$b (just added chapter=$chapter)');
      }
      
      notifyListeners();

      // Daily Activity: only log when this is a newly read chapter (affects totalChaptersRead)
      try {
        if (!hadBefore) {
          logChaptersReadForToday(1);
        }
      } catch (e) {
        debugPrint('daily activity log error: $e');
      }

      // Mastery: record chapter read
      try {
        _bookMasteryService.recordChapterRead(b);
      } catch (e) {
        debugPrint('mastery recordChapterRead hook error: $e');
      }

      // Auto-progress Weekly Quest Board quest ONLY if reading time threshold was met
      // (Both daily and weekly quests now require real reading time)
      try {
        if (!hadBefore && hasMetReadingThreshold) {
          // Treat as 1 verse unit if exact verse count isn't available
          incrementQuestProgressForType('weekly', amount: 1);
          debugPrint('Weekly quest progressed: chapter read with sufficient time');
        } else if (!hadBefore) {
          debugPrint('Weekly quest NOT progressed: reading time threshold not met');
        }
      } catch (e) {
        debugPrint('weekly quest auto-progress error: $e');
      }

      // Reading Plan hook: if active and this chapter fulfills the current step, mark it complete
      try {
        final step = getCurrentPlanStep();
        final plan = activeReadingPlan;
        if (plan != null && step != null) {
          final contains = _stepContainsChapter(step, b, chapter);
          if (contains) {
            final allDone = _areAllStepReferencesRead(step);
            if (allDone) {
              await completePlanStep(step.stepIndex);
            }
          }
        }
      } catch (e) {
        debugPrint('reading plan hook error: $e');
      }

      final unlocked = <AchievementModel>[];

      // Record streak event for today ONLY if reading time threshold was met
      // (Streak requires real reading, not just chapter opens)
      if (hasMetReadingThreshold) {
        final streakUnlocks = await recordBibleStreakEvent(DateTime.now());
        if (streakUnlocks.isNotEmpty) {
          unlocked.addAll(streakUnlocks);
        }
      }

      // If a streak recovery quest is active and not expired, increment for chapter reads (max 2)
      await _checkStreakRecoveryExpiry();
      if (hasActiveStreakRecoveryQuest && _activeStreakRecoveryQuestId != null) {
        try {
          // Prefer to count only unique reads to avoid abuse
          final recoveryId = _activeStreakRecoveryQuestId!;
          final q = _quests.firstWhere((e) => e.id == recoveryId, orElse: () =>
              TaskModel(
                id: '', title: '', description: '', targetCount: 1, xpReward: 0, startDate: DateTime.now(), createdAt: DateTime.now(), updatedAt: DateTime.now()));
          if (q.id.isNotEmpty && q.status != 'completed' && q.status != 'expired' && q.currentProgress < 2) {
            // Only increment on first-time chapter reads
            if (!hadBefore) {
              await _questService.updateQuestProgress(recoveryId, 1);
              _quests = await _questService.getAllQuests();
              notifyListeners();
            }
          }
        } catch (e) {
          debugPrint('streak recovery quest chapter progress error: $e');
        }
      }

      // If this action newly completes the book, unlock dynamic book achievement
      final total = bookTotalChapters[b] ?? bibleService.getChapterCount(b);
      final nowCount = set.length;
      final justCompleted = (!hadBefore && total > 0 && nowCount >= total);
      if (justCompleted) {
        // Mastery: record book completion (lifetime, never resets)
        try {
          _bookMasteryService.recordBookCompleted(b);
        } catch (e) {
          debugPrint('mastery recordBookCompleted hook error: $e');
        }
        final tier = total < 10 ? 'Rare' : 'Epic';
        final id = _bookCompletedId(b);
        final ach = AchievementModel(
          id: id,
          name: 'Completed $b',
          description: 'Read all chapters in $b.',
          category: 'Bible',
          rarity: tier.toLowerCase(),
          requirement: total,
          xpReward: tier == 'Epic' ? 200 : 100,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        unlocked.addAll(await _unlockDynamicAchievement(ach));

        // Book-specific artifact rewards: grant one unowned, story-appropriate item
        try {
          final granted = _bookRewardService?.grantRewardForBook(b);
          if (granted != null) {
            // Emit full-screen reveal modal event instead of small snackbar
            emitBookRewardGranted(b, granted.id);
            // Mastery: sync artifacts owned for this book after grant
            try {
              final owned = _ownedArtifactIdsForBook(b);
              _bookMasteryService.syncArtifactsForBook(b, owned);
            } catch (e) {
              debugPrint('mastery sync after book grant error: $e');
            }
          }
        } catch (e) {
          debugPrint('book reward grant error: $e');
        }

        // First book completed global achievement
        if (totalBooksCompleted >= 1) {
          unlocked.addAll(await _unlockDynamicAchievement(AchievementModel(
            id: 'first_book_completed',
            name: 'First Book Completed',
            description: 'Finish every chapter in one book.',
            category: 'Bible',
            rarity: 'rare',
            requirement: 1,
            xpReward: 150,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )));
          // Milestone loot: David's Harp (epic, alias supported) only if this is truly
          // the FIRST book completed and it's NOT Psalms (Psalms has its own mapping).
          if (totalBooksCompleted == 1 && b != 'Psalms') {
            try {
              final granted = _lootService?.grantByIdIfUnowned('davids_harp');
              if (granted != null) {
                // Queue alongside book reward reveal for a composed "1 of N" flow
                emitBookRewardGranted(b, granted.id);
                // Mastery: sync if this item maps to the completed book via mapping
                try {
                  final owned = _ownedArtifactIdsForBook(b);
                  _bookMasteryService.syncArtifactsForBook(b, owned);
                } catch (e) {
                  debugPrint('mastery sync after milestone grant error: $e');
                }
              }
            } catch (e) {
              debugPrint('first book completed loot grant error: $e');
            }
          }
        }

        // All 66 books completed global achievement
        if (totalBooksCompleted >= 66) {
          unlocked.addAll(await _unlockDynamicAchievement(AchievementModel(
            id: 'all_books_completed',
            name: 'All 66 Books Completed',
            description: 'Finish every chapter in all 66 books (KJV).',
            category: 'Bible',
            rarity: 'legendary',
            requirement: 66,
            xpReward: 1000,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )));
        }
      }

      // Titles & Achievements v1.0: Reading milestones
      try {
        final distinct = distinctBooksRead;
        if (distinct >= 10) {
          await unlockAchievementPublic('explorer');
        }
        final chapters = totalChaptersRead;
        if (chapters >= 5) {
          await unlockAchievementPublic('read_chapters_5');
        }
        if (chapters >= 10) {
          await unlockAchievementPublic('read_chapters_10');
        }
        if (chapters >= 25) {
          await unlockAchievementPublic('read_chapters_25');
        }
        if (chapters >= 50) {
          await unlockAchievementPublic('faithful_reader');
        }
        // Composite: Joyful Reader (chapters milestone + at least one Psalms of Peace step)
        try {
          final uid = _currentUser?.id ?? '';
          if (uid.isNotEmpty && chapters >= 15) {
            final defs = await _questlineService.getAvailableQuestlines(uid);
            final hasPsalms = defs.any((d) => d.id == 'psalms_of_peace');
            if (hasPsalms) {
              final p = await _questlineService.getQuestlineProgress(uid, 'psalms_of_peace');
              final stepsDone = p?.completedStepIds.length ?? 0;
              if (stepsDone >= 1) {
                await unlockAchievementPublic('joyful_reader');
              }
            }
          }
        } catch (e) {
          debugPrint('joyful_reader unlock check error: $e');
        }
      } catch (e) {
        debugPrint('reading milestones unlock error: $e');
      }

      return unlocked;
    } catch (e) {
      debugPrint('recordChapterRead error: $e');
      return const [];
    }
  }

  // ================== Daily Reading Activity API ==================
  /// Increment today's chapter count by [deltaChapters] in the user's local timezone.
  /// No-ops for non-positive deltas. Persists per-user map safely.
  void logChaptersReadForToday(int deltaChapters) {
    try {
      if (deltaChapters <= 0) return;
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return;
      final now = DateTime.now();
      final key = _formatYmd(DateTime(now.year, now.month, now.day));
      final prev = _dailyChapterReads[key] ?? 0;
      final next = prev + deltaChapters;
      _dailyChapterReads[key] = next < 0 ? 0 : next;
      // Persist
      _persistDailyReads(uid, _dailyChapterReads);
      notifyListeners();
    } catch (e) {
      debugPrint('logChaptersReadForToday error: $e');
    }
  }

  /// Returns an ordered map of the last [days] days (oldest -> newest),
  /// filling missing days with 0. Keys are yyyy-MM-dd local dates.
  Map<String, int> getDailyReadingForLastNDays(int days) {
    final map = <String, int>{};
    try {
      final n = (days <= 0) ? 0 : days;
      if (n == 0) return map;
      final now = DateTime.now();
      for (int i = n - 1; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        final key = _formatYmd(DateTime(d.year, d.month, d.day));
        map[key] = _dailyChapterReads[key] ?? 0;
      }
    } catch (e) {
      debugPrint('getDailyReadingForLastNDays error: $e');
    }
    return map;
  }

  Map<String, int> _loadDailyReads(String uid) {
    final key = _dailyReadsKey(uid);
    final raw = _storageService.getString(key);
    final map = <String, int>{};
    if (raw == null) return map;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        decoded.forEach((k, v) {
          try {
            final dateKey = (k as String).trim();
            if (dateKey.isEmpty) return;
            final count = int.tryParse('$v') ?? 0;
            if (count > 0) map[dateKey] = count;
          } catch (_) {}
        });
      }
    } catch (e) {
      debugPrint('dailyReads decode error: $e');
    }
    return map;
  }

  Set<String> _loadCompletedQuizzes(String uid) {
    final key = _quizCompletedKey(uid);
    final raw = _storageService.getString(key);
    final set = <String>{};
    if (raw == null) return set;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final e in decoded) {
          final s = (e ?? '').toString().trim();
          if (s.isNotEmpty && s.contains(':')) set.add(s);
        }
      }
    } catch (e) {
      debugPrint('completed quizzes decode error: $e');
    }
    return set;
  }

  Future<void> _persistCompletedQuizzes(String uid) async {
    try {
      final key = _quizCompletedKey(uid);
      await _storageService.save<String>(key, jsonEncode(_completedChapterQuizzes.toList()));
    } catch (e) {
      debugPrint('persist completed quizzes error: $e');
    }
  }

  Future<void> _persistDailyReads(String uid, Map<String, int> map) async {
    try {
      final key = _dailyReadsKey(uid);
      await _storageService.save(key, jsonEncode(map));
    } catch (e) {
      debugPrint('persist dailyReads error: $e');
    }
  }

  // ================== Bible Streak ==================
  Future<List<AchievementModel>> recordBibleStreakEvent(DateTime readDate) async {
    try {
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return const [];

      final today = DateTime(readDate.year, readDate.month, readDate.day);
      final last = _lastBibleReadDate == null
          ? null
          : DateTime(_lastBibleReadDate!.year, _lastBibleReadDate!.month, _lastBibleReadDate!.day);

      // Case 1: first time
      final previousStreak = _currentBibleStreak;
      bool countedNewDay = false;
      if (last == null) {
        _currentBibleStreak = 1;
        _longestBibleStreak = 1;
        _lastBibleReadDate = today;
        countedNewDay = true;
      } else {
        final diffDays = today.difference(last).inDays;
        if (diffDays == 0) {
          // same day, already counted
        } else if (diffDays == 1) {
          _currentBibleStreak += 1;
          if (_currentBibleStreak > _longestBibleStreak) {
            _longestBibleStreak = _currentBibleStreak;
          }
          _lastBibleReadDate = today;
          countedNewDay = true;
          // Trigger streak celebration animation
          _streakCelebrationEvent++;
          _streakCelebrationValue = _currentBibleStreak;
        } else if (diffDays > 1) {
          // missed a day; reset to 1
          try {
            await ProgressEngine.instance.emit(ProgressEvent.streakBroken(previousStreak: previousStreak));
          } catch (e) {
            debugPrint('emit streakBroken error: $e');
          }
          _currentBibleStreak = 1;
          if (_currentBibleStreak > _longestBibleStreak) {
            _longestBibleStreak = _currentBibleStreak;
          }
          _lastBibleReadDate = today;
          countedNewDay = true;
        } else {
          // today is before last? unlikely due to normalization; set to today and keep streak
          _lastBibleReadDate = today;
        }
      }

      // Persist
      await _storageService.save(_streakCurrentKey(uid), _currentBibleStreak);
      await _storageService.save(_streakLongestKey(uid), _longestBibleStreak);
      await _storageService.save(_streakLastDateKey(uid), _formatYmd(today));
      notifyListeners();

      // Weekly quest: progress "days active" when a new day is counted
      if (countedNewDay) {
        try {
          await checkActiveQuests(event: 'onStreakMaintained', payload: {
            'day': _currentBibleStreak,
          });
        } catch (e) {
          debugPrint('onStreakMaintained hook error: $e');
        }
        // Unified Progress Engine: streak maintained
        try {
          await ProgressEngine.instance.emit(ProgressEvent.streakDayKept(_currentBibleStreak));
        } catch (e) {
          debugPrint('emit streakDayKept error: $e');
        }
      }

      // Detect streak break from 7+ to reset (newStreak == 1)
      try {
        final newStreak = _currentBibleStreak;
        if (previousStreak >= 7 && newStreak == 1 && !hasActiveStreakRecoveryQuest) {
          await _createStreakRecoveryQuest(previousStreak);
        }
      } catch (e) {
        debugPrint('streak recovery create quest check error: $e');
      }

      // Check streak achievements
      final unlocked = <AchievementModel>[];
      Future<List<AchievementModel>> unlock(String id, String title, String desc, String tier, int xp) async {
        return await _unlockDynamicAchievement(AchievementModel(
          id: id,
          name: title,
          description: desc,
          category: 'Bible',
          rarity: tier.toLowerCase(),
          requirement: 1,
          xpReward: xp,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      if (_currentBibleStreak == 3) {
        unlocked.addAll(await unlock(
          'bible_streak_3',
          '3-Day Streak',
          'Read the Bible 3 days in a row.',
          'Common',
          25,
        ));
        // Milestone loot: Pilgrim's Sandals (rare)
        try {
          final granted = _lootService?.grantByIdIfUnowned('pilgrims_sandals');
          if (granted != null) emitNewArtifactAcquired(granted);
        } catch (e) {
          debugPrint('streak 3 loot grant error: $e');
        }
      }
      if (_currentBibleStreak == 7) {
        unlocked.addAll(await unlock(
          'bible_streak_7',
          '7-Day Streak',
          'Read the Bible 7 days in a row.',
          'Rare',
          100,
        ));
        // Titles & Achievements v1.0 alias: Daily Seeker (7-day streak)
        try {
          await unlockAchievementPublic('daily_seeker');
        } catch (e) {
          debugPrint('daily_seeker unlock error: $e');
        }
        // Milestone loot: Shepherd's Staff (rare)
        try {
          final granted = _lootService?.grantByIdIfUnowned('shepherds_staff');
          if (granted != null) emitNewArtifactAcquired(granted);
        } catch (e) {
          debugPrint('streak 7 loot grant error: $e');
        }
      }
      if (_currentBibleStreak == 30) {
        unlocked.addAll(await unlock(
          'bible_streak_30',
          '30-Day Streak',
          'Read the Bible 30 days in a row.',
          'Epic',
          300,
        ));
      }
      return unlocked;
    } catch (e) {
      debugPrint('recordBibleStreakEvent error: $e');
      return const [];
    }
  }

  // ================== Streak Recovery Helpers ==================
  Future<void> _saveBibleStreakState() async {
    try {
      if (_currentUser == null) return;
      final uid = _currentUser!.id;
      await _storageService.save(_streakCurrentKey(uid), _currentBibleStreak);
      await _storageService.save(_streakLongestKey(uid), _longestBibleStreak);
      if (_lastBibleReadDate != null) {
        await _storageService.save(_streakLastDateKey(uid), _formatYmd(_lastBibleReadDate!));
      }
    } catch (e) {
      debugPrint('_saveBibleStreakState error: $e');
    }
  }

  Future<void> _saveStreakRecoveryState() async {
    try {
      if (_currentUser == null) return;
      final uid = _currentUser!.id;
      if (_previousBibleStreakBeforeBreak != null) {
        await _storageService.save(_streakRecoveryPrevKey(uid), _previousBibleStreakBeforeBreak!);
      } else {
        await _storageService.delete(_streakRecoveryPrevKey(uid));
      }
      if (_activeStreakRecoveryQuestId != null) {
        await _storageService.save(_streakRecoveryQuestIdKey(uid), _activeStreakRecoveryQuestId!);
      } else {
        await _storageService.delete(_streakRecoveryQuestIdKey(uid));
      }
      if (_streakRecoveryExpiresAt != null) {
        await _storageService.save(_streakRecoveryExpiresKey(uid), _streakRecoveryExpiresAt!.toIso8601String());
      } else {
        await _storageService.delete(_streakRecoveryExpiresKey(uid));
      }
    } catch (e) {
      debugPrint('_saveStreakRecoveryState error: $e');
    }
  }

  Future<void> _createStreakRecoveryQuest(int previousStreak) async {
    try {
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return;

      final now = DateTime.now();
      final expires = now.add(const Duration(days: 3));
      final questId = 'streak_recovery_${uid}_${now.millisecondsSinceEpoch}';

      final quest = TaskModel(
        id: questId,
        title: 'Streak Recovery Quest',
        description: 'You missed a day, but grace wins. Read 2 chapters in the FaithQuest Bible and write 1 reflection to repair your streak.',
        type: 'challenge',
        category: 'event',
        difficulty: 'Medium',
        questType: 'Reading/Reflection',
        spiritualFocus: 'Perseverance',
        scriptureReference: null,
        targetCount: 3,
        currentProgress: 0,
        xpReward: 150,
        status: 'not_started',
        isDaily: false,
        isWeekly: false,
        startDate: now,
        endDate: expires,
        createdAt: now,
        updatedAt: now,
        reflectionPrompt: 'What did you learn from coming back after missing a day?',
      );

      await _questService.addQuest(quest);
      _quests = await _questService.getAllQuests();

      _previousBibleStreakBeforeBreak = previousStreak;
      _activeStreakRecoveryQuestId = questId;
      _streakRecoveryExpiresAt = expires;
      await _saveStreakRecoveryState();
      notifyListeners();
    } catch (e) {
      debugPrint('_createStreakRecoveryQuest error: $e');
    }
  }

  Future<void> _checkStreakRecoveryExpiry() async {
    try {
      if (_activeStreakRecoveryQuestId == null || _streakRecoveryExpiresAt == null) return;
      final now = DateTime.now();
      if (now.isAfter(_streakRecoveryExpiresAt!)) {
        final id = _activeStreakRecoveryQuestId!;
        await _questService.expireQuestById(id);
        // Clear metadata
        _activeStreakRecoveryQuestId = null;
        _previousBibleStreakBeforeBreak = null;
        _streakRecoveryExpiresAt = null;
        await _saveStreakRecoveryState();
        _quests = await _questService.getAllQuests();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('_checkStreakRecoveryExpiry error: $e');
    }
  }

  // ================== Private helpers for read chapters ==================
  String _normalizeDisplayBook(String book) {
    try {
      final disp = bibleService.refToDisplay(book);
      // refToDisplay returns same if already display
      return disp.trim();
    } catch (_) {
      return book.trim();
    }
  }

  Map<String, Set<int>> _loadReadChapters(String uid) {
    final key = _readChaptersKey(uid);
    final raw = _storageService.getString(key);
    final map = <String, Set<int>>{};
    if (raw == null) return map;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        decoded.forEach((k, v) {
          final book = (k as String).trim();
          final list = (v as List<dynamic>? ?? const []).map((e) => int.tryParse('$e') ?? 0).where((n) => n > 0).toSet();
          if (book.isNotEmpty && list.isNotEmpty) {
            map[book] = list;
          }
        });
      }
    } catch (e) {
      debugPrint('readChapters decode error: $e');
    }
    return map;
  }

  Future<void> _persistReadChapters(String uid, Map<String, Set<int>> map) async {
    try {
      final key = _readChaptersKey(uid);
      final serializable = <String, List<int>>{};
      map.forEach((k, v) => serializable[k] = v.toList()..sort());
      await _storageService.save(key, jsonEncode(serializable));
    } catch (e) {
      debugPrint('persist readChapters error: $e');
    }
  }

  // Date helpers for yyyy-MM-dd
  String _formatYmd(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DateTime? _parseYmd(String s) {
    try {
      final parts = s.split('-');
      if (parts.length != 3) return null;
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final d = int.parse(parts[2]);
      return DateTime(y, m, d);
    } catch (_) {
      return null;
    }
  }

  String _bookCompletedId(String bookDisplay) {
    // slugify simple
    final slug = bookDisplay
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return 'book_completed_$slug';
  }

  // ================== Welcome Back helpers ==================
  /// Persist last opened timestamp to now. Safe to call on each Home visit.
  Future<void> updateLastOpenedNow() async {
    try {
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return;
      final now = DateTime.now();
      _lastOpenedAt = now;
      await _storageService.save<String>(_lastOpenedAtKey(uid), now.toIso8601String());
      // No notifyListeners(): purely metadata; avoids rebuild loops
    } catch (e) {
      debugPrint('updateLastOpenedNow error: $e');
    }
  }

  /// Determines if the Welcome Back banner should be shown for [today] (date-only).
  /// Suppresses while Guided Start is incomplete to keep UI calm.
  bool shouldShowWelcomeBackBanner(DateTime today) {
    try {
      final t = DateTime(today.year, today.month, today.day);
      final last = _lastOpenedAt == null
          ? null
          : DateTime(_lastOpenedAt!.year, _lastOpenedAt!.month, _lastOpenedAt!.day);
      if (last == null) return false; // first run handled by Guided Start
      if (last.year == t.year && last.month == t.month && last.day == t.day) return false; // same day

      final shown = _lastWelcomeShownForDay == null
          ? null
          : DateTime(_lastWelcomeShownForDay!.year, _lastWelcomeShownForDay!.month, _lastWelcomeShownForDay!.day);
      if (shown != null && shown.year == t.year && shown.month == t.month && shown.day == t.day) return false; // already shown today

      final guidedStartCompleted = _hasCompletedFirstReading && _hasCompletedFirstJournal && _hasVisitedQuestlines;
      if (!guidedStartCompleted) return false;
      return true;
    } catch (e) {
      debugPrint('shouldShowWelcomeBackBanner error: $e');
      return false;
    }
  }

  /// Mark the welcome banner as shown for [today] and persist.
  Future<void> markWelcomeBackShown(DateTime today) async {
    try {
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return;
      final d = DateTime(today.year, today.month, today.day);
      _lastWelcomeShownForDay = d;
      await _storageService.save<String>(_welcomeShownDayKey(uid), _formatYmd(d));
      // No notifyListeners(): avoid banner flicker mid-frame
    } catch (e) {
      debugPrint('markWelcomeBackShown error: $e');
    }
  }

  // ================== Reading Plan helpers ==================
  bool _stepContainsChapter(ReadingPlanStep step, String displayBook, int chapter) {
    try {
      for (final ref in step.referenceList) {
        final parsed = bibleService.parseReference(ref);
        final book = (parsed['bookDisplay'] as String? ?? '').trim();
        final ch = parsed['chapter'] as int?;
        if (book.toLowerCase() == displayBook.toLowerCase() && ch != null && ch == chapter) {
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('_stepContainsChapter error: $e');
      return false;
    }
  }

  bool _areAllStepReferencesRead(ReadingPlanStep step) {
    try {
      for (final ref in step.referenceList) {
        final parsed = bibleService.parseReference(ref);
        final book = (parsed['bookDisplay'] as String? ?? '').trim();
        final ch = parsed['chapter'] as int?;
        if (book.isEmpty || ch == null || ch <= 0) continue;
        if (!isChapterRead(book, ch)) return false;
      }
      return true;
    } catch (e) {
      debugPrint('_areAllStepReferencesRead error: $e');
      return false;
    }
  }

  // ================== Book Mastery helpers ==================
  String _extractDisplayBookFromRef(String reference) {
    try {
      final raw = reference.trim();
      if (raw.isEmpty) return '';
      // Expect formats like "John 3:16" or "John 20"
      final m = RegExp(r'^(.*?)\s+\d').firstMatch(raw);
      final anyBook = m != null ? m.group(1)! : raw;
      return bibleService.refToDisplay(anyBook).trim();
    } catch (e) {
      debugPrint('_extractDisplayBookFromRef error: $e');
      return reference.trim();
    }
  }

  String? _bookIdForGearId(String gearId) {
    try {
      final id = gearId.trim();
      if (id.isEmpty) return null;
      // Direct match in book reward map
      for (final entry in kBookRewardMap.entries) {
        for (final v in entry.value) {
          if (v == id) return entry.key;
          // Alias support: suffix match
          if (v.endsWith(id) || id.endsWith(v)) return entry.key;
        }
      }
      return null;
    } catch (e) {
      debugPrint('_bookIdForGearId error: $e');
      return null;
    }
  }

  List<String> _allArtifactIdsForBook(String bookId) {
    try {
      final key = _normalizeDisplayBook(bookId);
      final fromMap = List<String>.from(kBookRewardMap[key] ?? const <String>[]);
      final fromQuests = <String>{};
      for (final q in _quests) {
        try {
          final ref = (q.scriptureReference ?? '').trim();
          if (ref.isEmpty) continue;
          final b = _extractDisplayBookFromRef(ref);
          if (b.toLowerCase() == key.toLowerCase()) {
            for (final id in q.possibleRewardGearIds) {
              if (id.trim().isNotEmpty) fromQuests.add(id.trim());
            }
            final g = (q.guaranteedFirstClearGearId ?? '').trim();
            if (g.isNotEmpty) fromQuests.add(g);
          }
        } catch (_) {}
      }
      final all = {...fromMap, ...fromQuests};
      return all.toList();
    } catch (e) {
      debugPrint('_allArtifactIdsForBook error: $e');
      return const <String>[];
    }
  }

  List<String> _ownedArtifactIdsForBook(String bookId) {
    try {
      final gear = _gearService;
      if (gear == null) return const <String>[];
      final allIds = _allArtifactIdsForBook(bookId);
      if (allIds.isEmpty) return const <String>[];
      final ownedSet = <String>{};
      for (final raw in allIds) {
        final resolved = _lootService?.getById(raw);
        final canonicalId = resolved?.id ?? raw.trim();
        if (gear.containsItem(canonicalId)) ownedSet.add(canonicalId);
      }
      return ownedSet.toList();
    } catch (e) {
      debugPrint('_ownedArtifactIdsForBook error: $e');
      return const <String>[];
    }
  }

  Future<List<AchievementModel>> _unlockDynamicAchievement(AchievementModel template, {int? xpRewardOverride}) async {
    try {
      if (_currentUser == null) return const [];
      final uid = _currentUser!.id;
      // Refresh current list
      final list = await _achievementService.getAchievementsForUser(uid);
      int idx = list.indexWhere((a) => a.id == template.id);
      if (idx == -1) {
        // Create entry from template (locked)
        list.add(template.copyWith(isUnlocked: false, unlockedAt: null, progress: 0));
        idx = list.length - 1;
      }
      final a = list[idx];
      if (a.isUnlocked) {
        _achievements = list;
        notifyListeners();
        return const [];
      }
      final unlocked = a.copyWith(
        isUnlocked: true,
        unlockedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        progress: a.requirement,
      );
      list[idx] = unlocked;

      // Apply unified rewards (streak-aware XP) or fallback to legacy xpReward
      try {
        final rewards = (unlocked.rewards.isNotEmpty)
            ? unlocked.rewards
            : [Reward(type: RewardTypes.xp, amount: xpRewardOverride ?? unlocked.xpReward, label: '${xpRewardOverride ?? unlocked.xpReward} XP')];
        final labels = <String>[];
        for (final r in rewards) {
          if (r.type == RewardTypes.xp) {
            final amt = _applyStreakBonusToXp(r.amount ?? 0);
            if (amt > 0) {
              _currentUser = await _rewardService.applyReward(r, xpOverride: amt);
              _triggerXpBurst(amt);
              labels.add('$amt XP');
            }
          } else {
            _currentUser = await _rewardService.applyReward(r);
            labels.add(RewardService.formatRewardLabel(r));
          }
        }
        final summary = labels.where((e) => e.trim().isNotEmpty).join(' • ');
        emitAchievementUnlock(unlocked, summary);
      } catch (e) {
        debugPrint('_unlockDynamicAchievement reward award error: $e');
      }

      await _achievementService.saveAchievementsForUser(uid, list);
      _achievements = list;
      notifyListeners();
      return [unlocked];
    } catch (e) {
      debugPrint('_unlockDynamicAchievement error: $e');
      return const [];
    }
  }

  // ================== Private unlock helper ==================
  Future<List<AchievementModel>> _unlockAchievement(String id, {int? xpRewardOverride}) async {
    try {
      if (_currentUser == null) return const [];
      final uid = _currentUser!.id;
      // Refresh current list
      final list = await _achievementService.getAchievementsForUser(uid);
      final newly = _achievementService.unlockIfNeeded(list, id);
      if (newly.isEmpty) return const [];

      // Apply unified rewards (streak-aware XP) or fallback to legacy xpReward
      final ach = newly.first;
      try {
        final rewards = (ach.rewards.isNotEmpty)
            ? ach.rewards
            : [Reward(type: RewardTypes.xp, amount: xpRewardOverride ?? ach.xpReward, label: '${xpRewardOverride ?? ach.xpReward} XP')];
        final labels = <String>[];
        for (final r in rewards) {
          if (r.type == RewardTypes.xp) {
            final amt = _applyStreakBonusToXp(r.amount ?? 0);
            if (amt > 0) {
              _currentUser = await _rewardService.applyReward(r, xpOverride: amt);
              _triggerXpBurst(amt);
              labels.add('$amt XP');
            }
          } else {
            _currentUser = await _rewardService.applyReward(r);
            labels.add(RewardService.formatRewardLabel(r));
          }
        }
        final summary = labels.where((e) => e.trim().isNotEmpty).join(' • ');
        emitAchievementUnlock(ach, summary);
      } catch (e) {
        debugPrint('_unlockAchievement reward award error: $e');
      }

      await _achievementService.saveAchievementsForUser(uid, list);
      _achievements = list;
      notifyListeners();
      return newly;
    } catch (e) {
      debugPrint('_unlockAchievement error: $e');
      return const [];
    }
  }

  // ============== Public helpers for Titles & Achievements v1.0 ==============
  bool isAchievementUnlocked(String id) {
    try {
      return _achievements.any((a) => a.id == id && a.isUnlocked);
    } catch (_) {
      return false;
    }
  }

  Future<void> unlockAchievementPublic(String id) async {
    try {
      final newly = await _unlockAchievement(id);
      if (newly.isEmpty) return;
      // If a title is tied to this achievement, unlock it too
      try {
        final seeds = TitleSeedsV1.list();
        for (final t in seeds) {
          if (t.unlockAchievementId == id) {
            await unlockTitle(t.id);
          }
        }
      } catch (e) {
        debugPrint('unlockAchievementPublic title check error: $e');
      }
    } catch (e) {
      debugPrint('unlockAchievementPublic error: $e');
    }
  }

  Future<List<String>> getUnlockedTitleIds() async {
    try {
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return const <String>[];
      return await _titlesService.getTitles(uid: uid);
    } catch (_) {
      return const <String>[];
    }
  }

  Future<bool> isTitleUnlocked(String id) async {
    final list = await getUnlockedTitleIds();
    return list.contains(id);
  }

  Future<void> unlockTitle(String id) async {
    try {
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return;
      await _titlesService.unlockTitle(id, uid: uid);
      emitQuestProgress('New title unlocked: ${_resolveTitleName(id)}');
    } catch (e) {
      debugPrint('unlockTitle error: $e');
    }
  }

  Future<void> equipTitle(String id) async {
    try {
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return;
      await _titlesService.setEquippedTitle(id, uid: uid);
      _playerInventory = _playerInventory.copyWith(
        equipped: _playerInventory.equipped.copyWith(titleId: id),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('equipTitle error: $e');
    }
  }

  String _resolveTitleName(String id) {
    try {
      final seeds = TitleSeedsV1.list();
      final t = seeds.firstWhere((e) => e.id == id);
      return t.name;
    } catch (_) {
      return id.replaceAll('_', ' ');
    }
  }

  Future<void> _onQuestlineCompleted(String questlineId) async {
    try {
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return;
      // First-ever questline completion → achievement + title unlock via achievement
      if (!_hasCompletedAnyQuestline) {
        _hasCompletedAnyQuestline = true;
        await _storageService.save<bool>(_anyQuestlineCompletedKey(uid), true);
        await unlockAchievementPublic('first_step_taken');
      }
      // Specific questline completions
      try {
        if (questlineId == 'psalms_of_peace') {
          await unlockAchievementPublic('psalms_of_peace_completed');
        } else if (questlineId == 'teachings_of_jesus') {
          await unlockAchievementPublic('teachings_of_jesus_completed');
        }
      } catch (e) {
        debugPrint('specific questline achievement unlock error: $e');
      }
      // Count total completed questlines
      try {
        final defs = await _questlineService.getAvailableQuestlines(uid);
        int completed = 0;
        for (final d in defs) {
          final p = await _questlineService.getQuestlineProgress(uid, d.id);
          if (p != null && p.isCompleted) completed++;
        }
        if (completed >= 1) {
          await unlockAchievementPublic('questline_completed_1');
        }
        if (completed >= 3) {
          await unlockAchievementPublic('questlines_completed_3');
        }
      } catch (e) {
        debugPrint('questlines completed count unlock error: $e');
      }
      // Special-case title: Seeker of Peace for peace_in_the_storm
      if (questlineId == 'peace_in_the_storm') {
        await unlockTitle('seeker_of_peace');
      }
    } catch (e) {
      debugPrint('_onQuestlineCompleted error: $e');
    }
  }

  // ================== XP helpers ==================
  int _applyStreakBonus(int base) {
    try {
      if (base <= 0) return 0;
      if (hasStreakBonus) {
        // +10% bonus, rounded to nearest integer
        final bonus = (base * 1.10).round();
        return bonus;
      }
      return base;
    } catch (_) {
      return base;
    }
  }

  // Public alias per spec
  int _applyStreakBonusToXp(int baseXp) {
    return _applyStreakBonus(baseXp);
  }

  // ================== Bookmarks ==================
  String _canonicalizeReference(String reference) {
    try {
      final raw = reference.trim();
      if (raw.isEmpty) return '';
      final m = RegExp(r'^(.+?)\s+(\d+)(:.*)?$').firstMatch(raw);
      if (m != null) {
        final anyBook = m.group(1)!;
        final chapter = m.group(2)!;
        final versePart = m.group(3) ?? '';
        final refBook = bibleService.displayToRef(anyBook);
        return '${refBook.toUpperCase()} $chapter${versePart.toUpperCase()}';
      }
      return raw.toUpperCase();
    } catch (e) {
      debugPrint('_canonicalizeReference error: $e');
      return reference.trim().toUpperCase();
    }
  }

  bool isReferenceBookmarked(String reference) {
    try {
      final key = _canonicalizeReference(reference);
      return _bookmarks.any((b) => _canonicalizeReference(b.reference) == key && (b.translationCode.toUpperCase() == 'KJV'));
    } catch (e) {
      debugPrint('isReferenceBookmarked error: $e');
      return false;
    }
  }

  // ================== Onboarding v2.0 setup ==================
  /// Performs first-session setup: enrolls in a starter Quest, creates two starter tasks,
  /// grants a simple starter artifact, unlocks and equips a welcoming title, and
  /// marks onboarding as completed. Safe to call multiple times (idempotent-ish).
  Future<void> completeOnboardingSetup() async {
    try {
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return;

      // 1) Enroll in a starter questline (prefer 'foundations', else first seed)
      try {
        final defs = await _questlineService.getAvailableQuestlines(uid);
        String questlineId = 'foundations';
        final hasFoundations = defs.any((d) => d.id == questlineId);
        if (!hasFoundations) {
          questlineId = defs.isNotEmpty ? defs.first.id : 'onboarding_getting_started';
        }
        await enrollInQuestline(questlineId);
      } catch (e) {
        debugPrint('onboarding: enroll questline error: $e');
      }

      // 2) Create two starter tasks if not already present
      try {
        final now = DateTime.now();
        final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        final all = await _questService.getAllQuests();

        bool existsByTitle(String t) => all.any((q) => q.title.toLowerCase().trim() == t.toLowerCase().trim());

        if (!existsByTitle('Read a chapter')) {
          final daily = TaskModel(
            id: _uuid.v4(),
            title: 'Read a chapter',
            description: 'Open any chapter tonight and read prayerfully.',
            type: 'daily',
            category: 'daily',
            taskCategory: TaskCategory.daily,
            questFrequency: 'daily',
            questType: 'scripture_reading',
            isAutoTracked: true,
            isDaily: true,
            targetCount: 1,
            xpReward: 20,
            rewards: const [Reward(type: RewardTypes.xp, amount: 20, label: '20 XP')],
            startDate: now,
            endDate: todayEnd,
            createdAt: now,
            updatedAt: now,
            autoResetDaily: true,
          );
          await _questService.addQuest(daily);
        }

        if (!existsByTitle('Write one journal thought')) {
          final reflect = TaskModel(
            id: _uuid.v4(),
            title: 'Write one journal thought',
            description: 'Capture a short reflection in your Journal.',
            type: 'challenge',
            category: 'beginner',
            taskCategory: TaskCategory.reflection,
            questFrequency: 'once',
            questType: 'reflection',
            isAutoTracked: false,
            targetCount: 1,
            xpReward: 20,
            rewards: const [Reward(type: RewardTypes.xp, amount: 20, label: '20 XP')],
            startDate: now,
            endDate: null,
            createdAt: now,
            updatedAt: now,
            autoResetDaily: false,
          );
          await _questService.addQuest(reflect);
        }

        _quests = await _questService.getAllQuests();
      } catch (e) {
        debugPrint('onboarding: starter tasks error: $e');
      }

      // 3) Grant a gentle starter artifact and unlock a title
      try {
        final granted = _lootService?.grantByIdIfUnowned('charm_olive_branch');
        if (granted != null) {
          emitNewArtifactAcquired(granted);
        }
      } catch (e) {
        debugPrint('onboarding: grant starter artifact error: $e');
      }
      try {
        await unlockTitle('pilgrim');
        await equipTitle('pilgrim');
      } catch (e) {
        debugPrint('onboarding: unlock/equip title error: $e');
      }

      // 4) Flag as completed and persist
      try {
        _hasCompletedOnboarding = true;
        await _storageService.save<bool>(_onboardingCompletedKey(uid), true);
        _onboardingWelcomeOnce = true; // show banner on next Home
      } catch (e) {
        debugPrint('onboarding: persist complete flag error: $e');
      }

      // Refresh questlines cache to ensure Tonight's Quest reflects enrollment
      try {
        final defs = await _questlineService.getAvailableQuestlines(uid);
        _activeQuestlines = (await _questlineService.getActiveQuestlines(uid)).map((p) {
          final def = defs.firstWhere((d) => d.id == p.questlineId, orElse: () => defs.first);
          return QuestlineProgressView(questline: def, progress: p);
        }).toList();
      } catch (e) {
        debugPrint('onboarding: refresh questlines error: $e');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('completeOnboardingSetup error: $e');
    }
  }

  Future<void> addBookmark(VerseBookmark bookmark) async {
    try {
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) {
        debugPrint('addBookmark: missing user id');
        return;
      }
      // Avoid duplicates by canonical reference + KJV
      final key = _canonicalizeReference(bookmark.reference);
      final existsIndex = _bookmarks.indexWhere((b) => _canonicalizeReference(b.reference) == key && b.translationCode.toUpperCase() == 'KJV');
      if (existsIndex != -1) {
        // Update note if provided
        final existing = _bookmarks[existsIndex];
        final updated = existing.copyWith(note: bookmark.note);
        _bookmarks[existsIndex] = updated;
      } else {
        final id = (bookmark.id.isEmpty) ? _uuid.v4() : bookmark.id;
        _bookmarks.insert(0, bookmark.copyWith(id: id));
      }
      await _bookmarkService.saveBookmarksForUser(uid, _bookmarks);
      notifyListeners();
    } catch (e) {
      debugPrint('addBookmark error: $e');
    }
  }

  Future<void> removeBookmark(String id) async {
    try {
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return;
      _bookmarks.removeWhere((b) => b.id == id);
      await _bookmarkService.saveBookmarksForUser(uid, _bookmarks);
      notifyListeners();
    } catch (e) {
      debugPrint('removeBookmark error: $e');
    }
  }

  // ================== Friends ==================
  bool isFriend(String playerId) {
    try {
      return _friends.any((f) => f.id == playerId);
    } catch (e) {
      debugPrint('isFriend error: $e');
      return false;
    }
  }

  Future<void> addFriendFromPlayer(LeaderboardPlayer player) async {
    try {
      final userId = _currentUser?.id;
      if (userId == null || userId.isEmpty) return;
      if (isFriend(player.id)) return;

      final newFriend = FriendModel(
        id: player.id,
        displayName: player.displayName,
        tagline: player.tagline,
        createdAt: DateTime.now(),
      );

      _friends = [newFriend, ..._friends];
      await _friendService.saveFriendsForUser(userId, _friends);
      notifyListeners();
    } catch (e) {
      debugPrint('addFriendFromPlayer error: $e');
    }
  }

  Future<void> removeFriend(String friendId) async {
    try {
      final userId = _currentUser?.id;
      if (userId == null || userId.isEmpty) return;
      _friends = _friends.where((f) => f.id != friendId).toList();
      await _friendService.saveFriendsForUser(userId, _friends);
      notifyListeners();
    } catch (e) {
      debugPrint('removeFriend error: $e');
    }
  }

  // ================== What's New Modal (v1.0) ==================
  String? _lastSeenVersion;
  String _lastSeenVersionKey(String uid) => 'last_seen_version_$uid';

  /// Check if What's New modal should be shown
  /// Returns true if current version differs from last seen version
  Future<bool> shouldShowWhatsNew() async {
    try {
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return false;
      
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      if (_lastSeenVersion == null) {
        // Load from storage
        _lastSeenVersion = _storageService.getString(_lastSeenVersionKey(uid));
      }
      
      // Show modal if version has changed
      if (_lastSeenVersion == null || _lastSeenVersion != currentVersion) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('shouldShowWhatsNew error: $e');
      return false;
    }
  }

  /// Mark the current app version as seen
  Future<void> markWhatsNewSeen() async {
    try {
      final uid = _currentUser?.id ?? '';
      if (uid.isEmpty) return;
      
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      _lastSeenVersion = currentVersion;
      await _storageService.save<String>(_lastSeenVersionKey(uid), currentVersion);
    } catch (e) {
      debugPrint('markWhatsNewSeen error: $e');
    }
  }

  /// Get current app version string
  Future<String> getCurrentAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      debugPrint('getCurrentAppVersion error: $e');
      return '1.0.0';
    }
  }

  // ================== Device Info for Feedback (v1.0) ==================
  /// Get device information formatted for feedback emails
  Future<Map<String, String>> getDeviceInfoForFeedback() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfo = DeviceInfoPlugin();
      
      String deviceModel = 'Unknown';
      String osVersion = 'Unknown';
      String platform = 'Unknown';
      
      try {
        if (!kIsWeb) {
          if (Platform.isIOS) {
            platform = 'iOS';
            final iosInfo = await deviceInfo.iosInfo;
            deviceModel = iosInfo.utsname.machine ?? 'Unknown iOS Device';
            osVersion = iosInfo.systemVersion ?? 'Unknown';
          } else if (Platform.isAndroid) {
            platform = 'Android';
            final androidInfo = await deviceInfo.androidInfo;
            deviceModel = '${androidInfo.manufacturer ?? ''} ${androidInfo.model ?? ''}'.trim();
            osVersion = 'Android ${androidInfo.version.release ?? 'Unknown'}';
          } else {
            platform = 'Desktop';
          }
        } else {
          platform = 'Web';
          final webInfo = await deviceInfo.webBrowserInfo;
          deviceModel = webInfo.browserName.name;
          osVersion = webInfo.platform ?? 'Unknown';
        }
      } catch (e) {
        debugPrint('Platform detection error: $e');
      }
      
      final summary = 'App Version: ${packageInfo.version}\n'
                      'Build: ${packageInfo.buildNumber}\n'
                      'Device: $deviceModel\n'
                      'OS: $osVersion\n'
                      'Platform: $platform';
      
      return {
        'version': packageInfo.version,
        'build': packageInfo.buildNumber,
        'device': deviceModel,
        'os': osVersion,
        'platform': platform,
        'summary': summary,
      };
    } catch (e) {
      debugPrint('getDeviceInfoForFeedback error: $e');
      return {
        'version': '1.0.0',
        'build': '1',
        'device': 'Unknown',
        'os': 'Unknown',
        'platform': 'Unknown',
        'summary': 'App Version: 1.0.0\nBuild: 1\nDevice: Unknown\nOS: Unknown\nPlatform: Unknown',
      };
    }
  }
}
