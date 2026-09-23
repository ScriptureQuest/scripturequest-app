import '../data/connected/journey_definitions.dart';
import 'dart:convert';
import 'package:level_up_your_faith/utils/integrity/serial_queue.dart';
import 'package:flutter/foundation.dart';
import 'package:level_up_your_faith/models/quest_model.dart';
import 'package:level_up_your_faith/models/questline.dart';
import 'package:level_up_your_faith/models/reward.dart';
import 'package:level_up_your_faith/services/quest_service.dart';
import 'package:level_up_your_faith/services/storage_service.dart';
import 'package:uuid/uuid.dart';
import 'package:level_up_your_faith/services/progress/progress_engine.dart';
import 'package:level_up_your_faith/services/progress/progress_event.dart';

class QuestlineService {
  final StorageService _storage;
  final TaskService _questService;
  final _uuid = const Uuid();
  static final _transitions = SerialQueue();

  Future<List<QuestlineProgress>> getHistory(String userId) => _loadAllProgress(userId);

  QuestlineService(this._storage, this._questService);

  String _progressKey(String uid) => 'questline_progress_$uid';

  // ====== Public API ======
  Future<List<Questline>> getAvailableQuestlines(String userId) async {
    // For now, provide static definitions that generate concrete quests on enroll
    return journeyDefinitions();
  }

  Future<List<QuestlineProgress>> getActiveQuestlines(String userId) async {
    final all = await _loadAllProgress(userId);
    return all.where((p) => !p.isCompleted).toList();
  }

  Future<QuestlineProgress?> getQuestlineProgress(String userId, String questlineId) async {
    final all = await _loadAllProgress(userId);
    try {
      return all.firstWhere((p) => p.questlineId == questlineId);
    } catch (_) {
      return null;
    }
  }

  Future<QuestlineProgress> enrollInQuestline(String userId, String questlineId) => _transitions.run(() async {
    final defs = await getAvailableQuestlines(userId);
    final def = defs.firstWhere((d) => d.id == questlineId);
    var all = await _loadAllProgress(userId);
    final existing = all.where((p) => p.questlineId == questlineId).toList();
    if (existing.isNotEmpty) {
      return existing.first;
    }

    // Create new progress
    final firstStep = def.steps.isNotEmpty ? def.steps.first : null;
    final now = DateTime.now();
    final progress = QuestlineProgress(
      questlineId: questlineId,
      activeStepIds: firstStep == null ? <String>[] : <String>[firstStep.id],
      completedStepIds: <String>[],
      stepQuestIds: <String, String>{},
      dateStarted: now,
    );
    // Ensure quest for first step
    if (firstStep != null) {
      final qid = await _ensureStepQuest(def, firstStep);
      progress.stepQuestIds[firstStep.id] = qid;
    }

    all.add(progress);
    await _saveAllProgress(userId, all);
    return progress;
  });

  Future<QuestlineProgress?> markStepComplete(String userId, String questlineId, String stepId, {bool awardStep = true}) => _transitions.run(() async {
    var all = await _loadAllProgress(userId);
    final idx = all.indexWhere((p) => p.questlineId == questlineId);
    if (idx == -1) return null;
    final progress = all[idx];
    if (progress.completedStepIds.contains(stepId)) return progress; // already done

    final defs = await getAvailableQuestlines(userId);
    final def = defs.firstWhere((d) => d.id == questlineId);
    final ordered = [...def.steps]..sort((a, b) => a.order.compareTo(b.order));
    final stepIndex = ordered.indexWhere((s) => s.id == stepId);

    if (stepIndex < 0 || !progress.activeStepIds.contains(stepId)) return null;
    final completed = [...progress.completedStepIds, stepId];
    final active = [...progress.activeStepIds];
    active.remove(stepId);

    DateTime? dateCompleted;
    // Determine next step
    if (stepIndex != -1 && stepIndex + 1 < ordered.length) {
      final nextStep = ordered[stepIndex + 1];
      active.clear();
      active.add(nextStep.id);
      // ensure quest exists for next step
      final qid = await _ensureStepQuest(def, nextStep);
      final map = {...progress.stepQuestIds, nextStep.id: qid};
      final updated = progress.copyWith(
        activeStepIds: active,
        completedStepIds: completed,
        skippedStepIds: awardStep ? progress.skippedStepIds : [...progress.skippedStepIds, stepId],
        stepQuestIds: map,
      );
      all[idx] = updated;
      await _saveAllProgress(userId, all);
      // Emit step completion event with the resolved step index (0-based)
      try {
        if (awardStep) await ProgressEngine.instance.emit(
          ProgressEvent.questStepCompleted(questlineId, stepIndex == -1 ? 0 : stepIndex),
        );
      } catch (e) {
        debugPrint('emit questStepCompleted error: $e');
      }
      return updated;
    } else {
      // No more steps — completed
      dateCompleted = DateTime.now();
      final updated = progress.copyWith(
        activeStepIds: <String>[],
        completedStepIds: completed,
        skippedStepIds: awardStep ? progress.skippedStepIds : [...progress.skippedStepIds, stepId],
        dateCompleted: dateCompleted,
      );
      all[idx] = updated;
      await _saveAllProgress(userId, all);
      // Emit step completion event (final step index)
      try {
        if (awardStep) await ProgressEngine.instance.emit(
          ProgressEvent.questStepCompleted(questlineId, stepIndex == -1 ? 0 : stepIndex),
        );
      } catch (e) {
        debugPrint('emit questStepCompleted (final) error: $e');
      }
      return updated;
    }
  });

  /// Returns (questlineId, stepId) for a given questId, if it belongs to any active questline step.
  Future<Map<String, String>?> questlineStepForQuestId(String userId, String questId) async {
    final all = await _loadAllProgress(userId);
    for (final p in all) {
      for (final entry in p.stepQuestIds.entries) {
        if (entry.value == questId) {
          return {'questlineId': p.questlineId, 'stepId': entry.key};
        }
      }
    }
    return null;
  }

  // ====== Storage helpers ======
  Future<List<QuestlineProgress>> _loadAllProgress(String userId) async {
    if (userId.isEmpty) return [];
    final raw = _storage.getString(_progressKey(userId));
    if (raw == null || raw.trim().isEmpty) return [];
    final data = jsonDecode(raw);
    if (data is! List) throw const FormatException('Journey history is not a list');
    return data.map((row) {
      if (row is! Map<String, dynamic> || (row['questlineId'] ?? '').toString().isEmpty) {
        throw const FormatException('Journey history contains an unreadable entry');
      }
      return QuestlineProgress.fromJson(row);
    }).toList();
  }

  Future<void> _saveAllProgress(String userId, List<QuestlineProgress> list) async {
    if (userId.isEmpty) throw StateError('No journey profile');
    await _storage.save(_progressKey(userId), jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  // ====== Step quest generation ======
  Future<String> _ensureStepQuest(Questline def, QuestlineStep step) async {
    // Check if quest already exists by id reference
    final all = await _questService.getAllQuests();
    final exists = all.any((q) => q.id == step.questId);
    if (exists) return step.questId;

    // If questId is a template, generate a concrete quest
    if (step.questId.startsWith('tpl:')) {
      return await _createQuestFromTemplate(def, step);
    }

    // Otherwise, leave as-is; if it doesn't exist, create a basic placeholder quest to avoid dead step
    final now = DateTime.now();
    final q = TaskModel(
      id: step.questId,
      title: step.titleOverride ?? 'Step: ${def.title}',
      description: step.descriptionOverride ?? 'Complete this step in the questline ${def.title}.',
      type: 'challenge',
      category: def.category == 'book' ? 'beginner' : 'event',
      questType: 'scripture_reading',
      targetCount: 1,
      currentProgress: 0,
      xpReward: 20,
      rewards: const [Reward(type: RewardTypes.xp, amount: 20, label: '20 XP')],
      status: 'not_started',
      startDate: now,
      createdAt: now,
      updatedAt: now,
    );
    await _questService.addQuest(q);
    return q.id;
  }

  Future<String> _createQuestFromTemplate(Questline def, QuestlineStep step) async {
    final now = DateTime.now();
    final parts = step.questId.split(':');
    // Formats we support:
    // tpl:read:John 3:16
    // tpl:readChapter:John 1
    // tpl:reflection:Quick Reflection about God's Love
    // tpl:memorize:John 3:16
    final kind = parts.length > 1 ? parts[1] : 'read';
    final payload = parts.length > 2 ? step.questId.substring('tpl:$kind:'.length) : '';

    String title = step.titleOverride ?? def.title;
    String description = step.descriptionOverride ?? '';
    String? scriptureRef;
    String questType = 'scripture_reading';
    int xp = 25;

    switch (kind) {
      case 'read':
        scriptureRef = payload.isNotEmpty ? payload : 'John 3:16';
        title = step.titleOverride ?? 'Read $scriptureRef';
        description = step.descriptionOverride ?? 'Open and read $scriptureRef in the Bible.';
        questType = 'scripture_reading';
        xp = 25;
        break;
      case 'readChapter':
        scriptureRef = payload.isNotEmpty ? payload : 'John 1';
        title = step.titleOverride ?? 'Read $scriptureRef';
        description = step.descriptionOverride ?? 'Read the chapter $scriptureRef.';
        questType = 'scripture_reading';
        xp = 30;
        break;
      case 'reflection':
        scriptureRef = null;
        title = step.titleOverride ?? 'Write a Reflection';
        description = step.descriptionOverride ?? 'Write a brief reflection in your journal.';
        questType = 'reflection';
        xp = 30;
        break;
      case 'pray':
        scriptureRef = null;
        title = step.titleOverride ?? 'Spend time in prayer';
        description = step.descriptionOverride ?? 'Open the prayer guide and pray briefly.';
        questType = 'prayer';
        xp = 25;
        break;
      case 'memorize':
        scriptureRef = payload.isNotEmpty ? payload : null;
        title = step.titleOverride ?? (scriptureRef != null ? 'Memorize $scriptureRef' : 'Memorize a verse');
        description = step.descriptionOverride ?? 'Practice memorizing a verse from this journey.';
        questType = 'memorization';
        xp = 30;
        break;
      default:
        scriptureRef = null;
        title = step.titleOverride ?? 'Questline Step';
        description = step.descriptionOverride ?? 'Complete this step.';
        questType = 'scripture_reading';
        xp = 20;
    }

    final q = TaskModel(
      id: _uuid.v4(),
      title: title,
      description: description,
      type: 'challenge',
      category: def.category == 'book' ? 'beginner' : 'event',
      questType: questType,
      spiritualFocus: null,
      scriptureReference: scriptureRef,
      targetCount: 1,
      currentProgress: 0,
      xpReward: xp,
      rewards: [Reward(type: RewardTypes.xp, amount: xp, label: '$xp XP')],
      status: 'not_started',
      startDate: now,
      createdAt: now,
      updatedAt: now,
    );
    await _questService.addQuest(q);
    return q.id;
  }

}
