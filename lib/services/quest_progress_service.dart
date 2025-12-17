import 'package:flutter/foundation.dart';
import 'package:level_up_your_faith/models/quest_model.dart';
import 'package:level_up_your_faith/models/verse_model.dart';
import 'package:level_up_your_faith/services/quest_service.dart';
import 'package:level_up_your_faith/services/verse_service.dart';

/// Debug flag for quest progress logging
const bool _kQuestProgressDebug = true;

/// QuestProgressService (v2.0)
/// Centralizes event-driven quest progression so all Scripture actions can
/// nudge relevant quests. UI/Providers supply callbacks for persistence/rewards.
class QuestProgressService {
  final TaskService questService;
  final VerseService verseService;

  const QuestProgressService({required this.questService, required this.verseService});

  // Nightly window helper: 20:00 → 02:59 local
  // Returns true if the provided local time is within the nightly quest window.
  static bool isNightlyWindow(DateTime t) {
    final h = t.hour;
    return h >= 20 || h <= 2;
  }

  /// Parses a scripture reference to extract book and chapter.
  /// Examples:
  ///   "John 3:16" -> (book: "john", chapter: 3)
  ///   "Psalms 23" -> (book: "psalms", chapter: 23)
  ///   "1 Corinthians 13:4-7" -> (book: "1 corinthians", chapter: 13)
  static ({String book, int? chapter}) parseReference(String reference) {
    final ref = reference.trim();
    if (ref.isEmpty) return (book: '', chapter: null);

    // Match patterns like "John 3:16", "Psalms 23", "1 Corinthians 13"
    // Book names can have numbers prefix (1 John, 2 Kings)
    final regex = RegExp(r'^(\d?\s*[A-Za-z]+(?:\s+[A-Za-z]+)?)\s*(\d+)?');
    final match = regex.firstMatch(ref);
    if (match == null) return (book: ref.toLowerCase(), chapter: null);

    final bookPart = (match.group(1) ?? '').trim().toLowerCase();
    final chapterPart = match.group(2);
    final chapter = chapterPart != null ? int.tryParse(chapterPart) : null;

    return (book: bookPart, chapter: chapter);
  }

  /// Checks if completed book+chapter matches quest target.
  /// Strict matching rules:
  /// 1. If quest has no scriptureReference -> any chapter counts
  /// 2. If quest specifies exact book+chapter -> must match exactly
  /// 3. If quest specifies only book (no chapter) -> any chapter of that book counts
  /// 4. Special: for Psalm-related quests, only Psalms book counts
  static bool matchesQuestTarget({
    required String completedBook,
    required int completedChapter,
    required String? questScriptureReference,
    required String questTitle,
  }) {
    final normBook = completedBook.trim().toLowerCase();
    final questRef = (questScriptureReference ?? '').trim();

    // No target specified -> generic quest, any chapter counts
    if (questRef.isEmpty) {
      _debugLog('Quest has no target, any chapter counts', questTitle, completedBook, completedChapter, true);
      return true;
    }

    // Parse the quest target
    final target = parseReference(questRef);

    // Check for Psalm-specific quest (title mentions "Psalm" but maybe no specific reference)
    final titleLower = questTitle.toLowerCase();
    if (titleLower.contains('psalm') && !normBook.contains('psalm')) {
      _debugLog('Psalm quest requires Psalms book', questTitle, completedBook, completedChapter, false);
      return false;
    }

    // Book must match
    final targetBook = target.book;
    if (targetBook.isNotEmpty && !_booksMatch(normBook, targetBook)) {
      _debugLog('Book mismatch: expected "$targetBook"', questTitle, completedBook, completedChapter, false);
      return false;
    }

    // If quest specifies a chapter, it must match
    if (target.chapter != null && target.chapter != completedChapter) {
      _debugLog('Chapter mismatch: expected ${target.chapter}', questTitle, completedBook, completedChapter, false);
      return false;
    }

    _debugLog('Match found', questTitle, completedBook, completedChapter, true);
    return true;
  }

  /// Checks if two book names refer to the same book (handles variations)
  /// Uses STRICT matching - no substring containment to prevent "John" matching "1 John"
  static bool _booksMatch(String completedBook, String targetBook) {
    // Normalize: remove spaces, lowercase
    String norm(String s) => s.replaceAll(' ', '').replaceAll(RegExp(r'[^\w]'), '').toLowerCase();
    final a = norm(completedBook);
    final b = norm(targetBook);

    // Direct match
    if (a == b) return true;

    // Known aliases - EXPLICIT list to avoid substring issues
    const aliases = <Set<String>>[
      {'psalm', 'psalms'},
      {'songofsolomon', 'songofsongs', 'canticles'},
      {'revelation', 'revelations', 'apocalypse'},
      {'ecclesiastes', 'qoheleth'},
    ];

    for (final aliasSet in aliases) {
      if (aliasSet.contains(a) && aliasSet.contains(b)) return true;
    }

    // NO substring matching - "john" must NOT match "1john"
    return false;
  }

  static void _debugLog(String message, String questTitle, String book, int chapter, bool matched) {
    if (!_kQuestProgressDebug) return;
    debugPrint('[QuestProgress] $message | Quest: "$questTitle" | Completed: $book $chapter | Matched: $matched');
  }

  /// Handles a gameplay event and applies quest progress via callbacks.
  /// Returns number of quests progressed.
  Future<int> handleEvent({
    required String event,
    Map<String, dynamic>? payload,
    required Future<void> Function(String questId, int amount) onApplyProgress,
    required Future<void> Function(String questId) onMarkComplete,
  }) async {
    try {
      final active = await questService.getActiveQuests();
      if (active.isEmpty) return 0;

      int applied = 0;
      VerseModel? verse;
      String? verseRef;
      String norm(String s) => s.trim().toUpperCase();

      if (event == 'onVerseRead') {
        final id = (payload?['verseId'] ?? '').toString();
        if (id.isNotEmpty) {
          try {
            verse = await verseService.getVerseById(id);
            verseRef = verse?.reference;
          } catch (_) {}
        }
      }

      final book = (payload?['book'] ?? '').toString();
      final chapter = int.tryParse('${payload?['chapter'] ?? ''}') ?? 0;

      for (final q in active) {
        if (q.isCompleted || q.isExpired) continue;
        bool shouldApply = false;
        switch (event) {
          case 'onVerseRead':
            if (q.questType == 'scripture_reading') {
              if ((q.scriptureReference == null) || q.scriptureReference!.isEmpty) {
                shouldApply = true;
              } else if (verseRef != null && norm(q.scriptureReference!) == norm(verseRef!)) {
                shouldApply = true;
              }
            }
            break;
          case 'onQuizCompleted':
            // Treat a completed quiz as meaningful progress for scripture_reading or reflection tasks.
            if (q.questType == 'scripture_reading' || q.questType == 'reflection') {
              if ((q.scriptureReference == null) || q.scriptureReference!.isEmpty) {
                shouldApply = true;
              } else if (book.isNotEmpty && q.scriptureReference!.toLowerCase().contains(book.toLowerCase())) {
                shouldApply = true;
              }
            }
            break;
          case 'onChapterComplete':
            // STRICT MATCHING: Only credit if quest type is scripture_reading or routine
            // AND the completed chapter matches the quest target
            if (q.questType == 'scripture_reading' || q.questType == 'routine') {
              // Special case: Nightly quest only progresses within the nightly window
              if (q.type == 'nightly' && !QuestProgressService.isNightlyWindow(DateTime.now())) {
                if (_kQuestProgressDebug) {
                  debugPrint('[QuestProgress] Skipping nightly quest outside window: ${q.title}');
                }
                continue;
              }

              // Apply strict matching
              shouldApply = matchesQuestTarget(
                completedBook: book,
                completedChapter: chapter,
                questScriptureReference: q.scriptureReference,
                questTitle: q.title,
              );
            } else {
              // Non-scripture quests should NOT auto-progress from chapter completion
              if (_kQuestProgressDebug) {
                debugPrint('[QuestProgress] Ignoring chapter complete for non-scripture quest: ${q.title} (type: ${q.questType})');
              }
            }
            break;
          case 'onBookComplete':
            if (q.questType == 'scripture_reading') {
              if ((q.scriptureReference == null) || q.scriptureReference!.isEmpty) {
                shouldApply = true;
              } else if (book.isNotEmpty && q.scriptureReference!.toLowerCase().contains(book.toLowerCase())) {
                shouldApply = true;
              }
            }
            break;
          case 'onStreakMaintained':
            // Progress weekly "days active" meta quests only
            if (q.questType == 'days_active') {
              shouldApply = true;
            }
            break;
          case 'onReflectionWritten':
            if (q.questType == 'reflection') {
              shouldApply = true;
            }
            break;
          case 'onBibleOpened':
            // Daily routine check-in (opening Bible tab)
            if (q.questType == 'routine') {
              shouldApply = true;
            }
            break;
          case 'onQuestCompleted':
            // Meta quests that respond to any quest completion
            if (q.questType == 'meta') {
              shouldApply = true;
            }
            break;
        }

        if (!shouldApply) continue;
        await onApplyProgress(q.id, 1);
        applied += 1;

        try {
          final updated = (await questService.getAllQuests()).firstWhere(
            (e) => e.id == q.id,
            orElse: () => q,
          );
          if (updated.currentProgress >= updated.targetCount && !updated.isCompleted) {
            await onMarkComplete(updated.id);
          }
        } catch (e) {
          debugPrint('QuestProgressService completion check error: $e');
        }
      }

      return applied;
    } catch (e) {
      debugPrint('QuestProgressService.handleEvent error: $e');
      return 0;
    }
  }
}
