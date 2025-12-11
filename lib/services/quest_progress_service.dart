import 'package:flutter/foundation.dart';
import 'package:level_up_your_faith/models/quest_model.dart';
import 'package:level_up_your_faith/models/verse_model.dart';
import 'package:level_up_your_faith/services/quest_service.dart';
import 'package:level_up_your_faith/services/verse_service.dart';

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
            if (q.questType == 'scripture_reading') {
              // Special case: Nightly quest only progresses within the nightly window
              if (q.type == 'nightly') {
                shouldApply = QuestProgressService.isNightlyWindow(DateTime.now());
              } else {
                if ((q.scriptureReference == null) || q.scriptureReference!.isEmpty) {
                  shouldApply = true;
                } else if (book.isNotEmpty && q.scriptureReference!.toLowerCase().contains(book.toLowerCase())) {
                  shouldApply = true;
                }
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
