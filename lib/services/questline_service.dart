import 'dart:convert';
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

  QuestlineService(this._storage, this._questService);

  String _progressKey(String uid) => 'questline_progress_$uid';

  // ====== Public API ======
  Future<List<Questline>> getAvailableQuestlines(String userId) async {
    // For now, provide static definitions that generate concrete quests on enroll
    return _definitions();
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

  Future<QuestlineProgress> enrollInQuestline(String userId, String questlineId) async {
    final defs = await getAvailableQuestlines(userId);
    final def = defs.firstWhere((d) => d.id == questlineId);
    var all = await _loadAllProgress(userId);
    final existing = all.where((p) => p.questlineId == questlineId && !p.isCompleted).toList();
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
  }

  Future<QuestlineProgress?> markStepComplete(String userId, String questlineId, String stepId) async {
    var all = await _loadAllProgress(userId);
    final idx = all.indexWhere((p) => p.questlineId == questlineId);
    if (idx == -1) return null;
    final progress = all[idx];
    if (progress.completedStepIds.contains(stepId)) return progress; // already done

    final defs = await getAvailableQuestlines(userId);
    final def = defs.firstWhere((d) => d.id == questlineId);
    final ordered = [...def.steps]..sort((a, b) => a.order.compareTo(b.order));
    final stepIndex = ordered.indexWhere((s) => s.id == stepId);

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
        stepQuestIds: map,
      );
      all[idx] = updated;
      await _saveAllProgress(userId, all);
      // Emit step completion event with the resolved step index (0-based)
      try {
        await ProgressEngine.instance.emit(
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
        dateCompleted: dateCompleted,
      );
      all[idx] = updated;
      await _saveAllProgress(userId, all);
      // Emit step completion event (final step index)
      try {
        await ProgressEngine.instance.emit(
          ProgressEvent.questStepCompleted(questlineId, stepIndex == -1 ? 0 : stepIndex),
        );
      } catch (e) {
        debugPrint('emit questStepCompleted (final) error: $e');
      }
      return updated;
    }
  }

  /// Returns (questlineId, stepId) for a given questId, if it belongs to any active questline step.
  Future<Map<String, String>?> questlineStepForQuestId(String userId, String questId) async {
    final all = await _loadAllProgress(userId);
    for (final p in all) {
      if (p.isCompleted) continue;
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
    try {
      if (userId.isEmpty) return <QuestlineProgress>[];
      final raw = _storage.getString(_progressKey(userId));
      if (raw == null || raw.trim().isEmpty) return <QuestlineProgress>[];
      final arr = jsonDecode(raw);
      if (arr is! List) return <QuestlineProgress>[];
      final result = <QuestlineProgress>[];
      for (final item in arr) {
        try {
          if (item is Map<String, dynamic>) {
            result.add(QuestlineProgress.fromJson(item));
          } else if (item is Map) {
            result.add(QuestlineProgress.fromJson(item.cast<String, dynamic>()));
          }
        } catch (e) {
          debugPrint('Skipping malformed questline progress: $e');
        }
      }
      // sanitize write-back
      await _saveAllProgress(userId, result);
      return result;
    } catch (e) {
      debugPrint('_loadAllProgress error: $e');
      return <QuestlineProgress>[];
    }
  }

  Future<void> _saveAllProgress(String userId, List<QuestlineProgress> list) async {
    try {
      if (userId.isEmpty) return;
      final enc = jsonEncode(list.map((e) => e.toJson()).toList());
      await _storage.save(_progressKey(userId), enc);
    } catch (e) {
      debugPrint('_saveAllProgress error: $e');
    }
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

  // ====== Static definitions ======
  List<Questline> _definitions() {
    return [
      Questline(
        id: 'onboarding_getting_started',
        title: 'Getting Started',
        description: 'A quick intro: read two core verses and write one reflection.',
        category: 'onboarding',
        themeTag: 'Start',
        isActive: true,
        isRepeatable: false,
        iconKey: 'rocket',
        steps: const [
          QuestlineStep(id: 's1', questId: 'tpl:read:John 3:16', order: 1),
          QuestlineStep(id: 's2', questId: 'tpl:read:Romans 8:28', order: 2),
          QuestlineStep(id: 's3', questId: 'tpl:reflection:First Reflection', order: 3),
        ],
        rewards: const [Reward(type: RewardTypes.xp, amount: 150, label: '150 XP')],
      ),
      Questline(
        id: 'book_journey_through_john',
        title: 'Journey through John',
        description: 'Highlight moments in the Gospel of John: 1, 3, and 20.',
        category: 'book',
        themeTag: 'Gospel',
        isActive: true,
        isRepeatable: true,
        iconKey: 'book',
        steps: const [
          QuestlineStep(id: 'j1', questId: 'tpl:readChapter:John 1', order: 1),
          QuestlineStep(id: 'j2', questId: 'tpl:readChapter:John 3', order: 2),
          QuestlineStep(id: 'j3', questId: 'tpl:readChapter:John 20', order: 3),
        ],
        rewards: const [Reward(type: RewardTypes.xp, amount: 250, label: '250 XP')],
      ),
      // v0.5 themed seeds
      Questline(
        id: 'peace_in_the_storm',
        title: 'Peace in the Storm',
        description: 'A calm journey through shepherd-care and Jesus over the storm.',
        category: 'seasonal',
        themeTag: 'Peace',
        isActive: true,
        isRepeatable: false,
        iconKey: 'peace',
        steps: const [
          QuestlineStep(id: 'p1', questId: 'tpl:readChapter:Psalms 23', order: 1, titleOverride: 'Read Psalm 23'),
          QuestlineStep(id: 'p2', questId: 'tpl:reflection:Journal on “The Lord is my shepherd”', order: 2, titleOverride: 'Journal your reflection'),
          QuestlineStep(id: 'p3', questId: 'tpl:read:Mark 4:35-41', order: 3, titleOverride: 'Read Mark 4:35–41'),
          QuestlineStep(id: 'p4', questId: 'tpl:memorize:', order: 4, titleOverride: 'Memorize a verse from this journey'),
        ],
        rewards: const [
          Reward(type: RewardTypes.xp, amount: 200, label: '200 XP'),
          Reward(id: 'hand_censer_of_incense', type: RewardTypes.gear, rarity: 'rare', label: 'Censer of Incense'),
        ],
      ),
      Questline(
        id: 'knowing_jesus',
        title: 'Knowing Jesus',
        description: 'Meet Christ in John’s Gospel and respond in prayer.',
        category: 'seasonal',
        themeTag: 'Faith',
        isActive: true,
        isRepeatable: true,
        iconKey: 'christ',
        steps: const [
          QuestlineStep(id: 'k1', questId: 'tpl:readChapter:John 1', order: 1, titleOverride: 'Read John 1'),
          QuestlineStep(id: 'k2', questId: 'tpl:reflection:One thing you learned about Jesus', order: 2, titleOverride: 'Journal: one thing you learned'),
          QuestlineStep(id: 'k3', questId: 'tpl:readChapter:John 3', order: 3, titleOverride: 'Read John 3'),
          QuestlineStep(id: 'k4', questId: 'tpl:reflection:A prayer of response', order: 4, titleOverride: 'Journal a prayer of response'),
        ],
        rewards: const [
          Reward(type: RewardTypes.xp, amount: 250, label: '250 XP'),
          Reward(id: 'charm_pearl_of_great_price', type: RewardTypes.gear, rarity: 'epic', label: 'Pearl of Great Price'),
        ],
      ),
      // ===== New Questlines v1.0 =====
      Questline(
        id: 'psalms_of_peace',
        title: 'Psalms of Peace',
        description: 'Find calm and rest in God through beloved Psalms.',
        category: 'seasonal',
        themeTag: 'Peace',
        isActive: true,
        isRepeatable: true,
        iconKey: 'peace',
        steps: const [
          QuestlineStep(
            id: 'pp1',
            questId: 'tpl:read:Psalms 4:8',
            order: 1,
            titleOverride: 'Lie Down in Safety — Psalm 4:8',
            descriptionOverride: '“I will both lay me down in peace, and sleep.” Read and breathe slowly. Ask God to quiet your heart tonight.',
          ),
          QuestlineStep(
            id: 'pp2',
            questId: 'tpl:readChapter:Psalms 23',
            order: 2,
            titleOverride: 'The Lord is My Shepherd — Psalm 23',
            descriptionOverride: 'Read Psalm 23 like a gentle walk with the Shepherd. Which line comforts you most? Jot a short note.',
          ),
          QuestlineStep(
            id: 'pp3',
            questId: 'tpl:read:Psalms 46:1',
            order: 3,
            titleOverride: 'Refuge and Strength — Psalm 46:1',
            descriptionOverride: '“God is our refuge and strength…” Read and whisper the verse. Imagine God standing with you right now.',
          ),
          QuestlineStep(
            id: 'pp4',
            questId: 'tpl:read:Psalms 91:1-2',
            order: 4,
            titleOverride: 'Under His Wings — Psalm 91:1–2',
            descriptionOverride: 'Read these verses about shelter. Picture resting under God’s care. Tell Him one worry.',
          ),
          QuestlineStep(
            id: 'pp5',
            questId: 'tpl:read:Psalms 121:1-2',
            order: 5,
            titleOverride: 'Help From the Lord — Psalm 121:1–2',
            descriptionOverride: 'Lift your eyes to the hills. Read and thank God for being your Keeper. Write one sentence of thanks.',
          ),
        ],
        rewards: const [Reward(type: RewardTypes.xp, amount: 220, label: '220 XP')],
      ),

      Questline(
        id: 'teachings_of_jesus',
        title: 'Teachings of Jesus',
        description: 'Walk through six gentle teachings of Jesus and practice them.',
        category: 'seasonal',
        themeTag: 'Jesus',
        isActive: true,
        isRepeatable: true,
        iconKey: 'christ',
        steps: const [
          QuestlineStep(
            id: 'tj1',
            questId: 'tpl:read:Matthew 5:3-10',
            order: 1,
            titleOverride: 'The Beatitudes — Matthew 5:3–10',
            descriptionOverride: 'Read slowly. Which blessing speaks to you today? Circle it in your mind and smile.',
          ),
          QuestlineStep(
            id: 'tj2',
            questId: 'tpl:read:Matthew 5:14-16',
            order: 2,
            titleOverride: 'Salt and Light — Matthew 5:14–16',
            descriptionOverride: 'Read and ask: How can I shine kindly today? Pick one small action.',
          ),
          QuestlineStep(
            id: 'tj3',
            questId: 'tpl:read:Matthew 22:37-39',
            order: 3,
            titleOverride: 'Greatest Commandment — Matthew 22:37–39',
            descriptionOverride: 'Love God. Love neighbor. Whisper a short prayer: “Teach me to love today.”',
          ),
          QuestlineStep(
            id: 'tj4',
            questId: 'tpl:read:Luke 8:11-15',
            order: 4,
            titleOverride: 'Parable of the Sower — Luke 8:11–15',
            descriptionOverride: 'Ask God to make your heart “good soil.” What helps you listen to Jesus?',
          ),
          QuestlineStep(
            id: 'tj5',
            questId: 'tpl:read:Luke 6:27-28',
            order: 5,
            titleOverride: 'Love Your Enemies — Luke 6:27–28',
            descriptionOverride: 'Think of someone hard to love. Whisper one kind prayer for them.',
          ),
          QuestlineStep(
            id: 'tj6',
            questId: 'tpl:pray:Live the teaching today',
            order: 6,
            titleOverride: 'Simple Prayer',
            descriptionOverride: 'Take 30 seconds: “Lord Jesus, help me live Your words with a kind heart.”',
          ),
        ],
        rewards: const [Reward(type: RewardTypes.xp, amount: 300, label: '300 XP')],
      ),

      Questline(
        id: 'genesis_beginnings',
        title: 'Genesis Beginnings',
        description: 'From creation to Joseph — God’s good plan begins.',
        category: 'seasonal',
        themeTag: 'Beginnings',
        isActive: true,
        isRepeatable: true,
        iconKey: 'book',
        steps: const [
          QuestlineStep(
            id: 'gb1',
            questId: 'tpl:read:Genesis 1:1-5',
            order: 1,
            titleOverride: 'Creation Begins — Genesis 1:1–5',
            descriptionOverride: '“In the beginning God created…” Read and notice the light. Thank God for today’s light in your life.',
          ),
          QuestlineStep(
            id: 'gb2',
            questId: 'tpl:read:Genesis 12:1-3',
            order: 2,
            titleOverride: 'Abraham’s Call — Genesis 12:1–3',
            descriptionOverride: 'God calls and blesses. What small step of trust can you take this week?',
          ),
          QuestlineStep(
            id: 'gb3',
            questId: 'tpl:read:Genesis 15:5-6',
            order: 3,
            titleOverride: 'Promise and Faith — Genesis 15:5–6',
            descriptionOverride: 'Abraham believed the Lord. Whisper: “Help my faith grow.” Write a tiny prayer if you wish.',
          ),
          QuestlineStep(
            id: 'gb4',
            questId: 'tpl:read:Genesis 50:20',
            order: 4,
            titleOverride: 'Joseph’s Perspective — Genesis 50:20',
            descriptionOverride: 'God can bring good even from hard things. Thank God for being with you in all seasons.',
          ),
        ],
        rewards: const [Reward(type: RewardTypes.xp, amount: 180, label: '180 XP')],
      ),

      Questline(
        id: 'proverbs_for_wisdom',
        title: 'Proverbs for Wisdom',
        description: 'Short wisdom verses with kid‑friendly prompts for daily life.',
        category: 'seasonal',
        themeTag: 'Wisdom',
        isActive: true,
        isRepeatable: true,
        iconKey: 'book',
        steps: const [
          QuestlineStep(
            id: 'pw1',
            questId: 'tpl:read:Proverbs 1:7',
            order: 1,
            titleOverride: 'The Beginning of Knowledge — Prov 1:7',
            descriptionOverride: 'Read gently. Ask: How can I show respect for God today? Choose one small way.',
          ),
          QuestlineStep(
            id: 'pw2',
            questId: 'tpl:read:Proverbs 3:5-6',
            order: 2,
            titleOverride: 'Trust in the Lord — Prov 3:5–6',
            descriptionOverride: 'Read and breathe. Tell God one thing you’re worried about. Invite Him to lead your path.',
          ),
          QuestlineStep(
            id: 'pw3',
            questId: 'tpl:read:Proverbs 4:23',
            order: 3,
            titleOverride: 'Guard Your Heart — Prov 4:23',
            descriptionOverride: 'What fills your heart today—joy, worry, hope? Write one line in your journal.',
          ),
          QuestlineStep(
            id: 'pw4',
            questId: 'tpl:read:Proverbs 12:25',
            order: 4,
            titleOverride: 'Anxiety and a Kind Word — Prov 12:25',
            descriptionOverride: 'Think of someone who needs encouragement. Plan to share a kind word.',
          ),
          QuestlineStep(
            id: 'pw5',
            questId: 'tpl:read:Proverbs 17:22',
            order: 5,
            titleOverride: 'A Merry Heart — Prov 17:22',
            descriptionOverride: 'Smile and thank God for one simple joy today. Write it down as a gratitude.',
          ),
        ],
        rewards: const [Reward(type: RewardTypes.xp, amount: 220, label: '220 XP')],
      ),

      Questline(
        id: 'life_of_david',
        title: 'Life of David',
        description: 'From shepherd to king — God’s faithfulness in David’s story.',
        category: 'seasonal',
        themeTag: 'David',
        isActive: true,
        isRepeatable: true,
        iconKey: 'star',
        steps: const [
          QuestlineStep(
            id: 'ld1',
            questId: 'tpl:read:1 Samuel 16:7',
            order: 1,
            titleOverride: 'God Looks at the Heart — 1 Sam 16:7',
            descriptionOverride: 'God sees the heart. Ask Him to shape your heart to be brave and kind.',
          ),
          QuestlineStep(
            id: 'ld2',
            questId: 'tpl:read:1 Samuel 17:45-47',
            order: 2,
            titleOverride: 'David and Goliath — 1 Sam 17:45–47',
            descriptionOverride: 'Read the victory in God’s name. What “giant” can you face with prayer today?',
          ),
          QuestlineStep(
            id: 'ld3',
            questId: 'tpl:read:1 Samuel 18:1-3',
            order: 3,
            titleOverride: 'Friendship with Jonathan — 1 Sam 18:1–3',
            descriptionOverride: 'Thank God for friends. Think of one way to be loyal and kind.',
          ),
          QuestlineStep(
            id: 'ld4',
            questId: 'tpl:read:Psalms 23:1-3',
            order: 4,
            titleOverride: 'The Lord My Shepherd — Psalm 23:1–3',
            descriptionOverride: 'Let these lines calm your heart. Picture God leading you beside still waters.',
          ),
          QuestlineStep(
            id: 'ld5',
            questId: 'tpl:read:Psalms 51:10',
            order: 5,
            titleOverride: 'Create in Me a Clean Heart — Psalm 51:10',
            descriptionOverride: 'Pray these words softly. Ask God to renew a right spirit within you.',
          ),
          QuestlineStep(
            id: 'ld6',
            questId: 'tpl:read:2 Samuel 7:12-13',
            order: 6,
            titleOverride: 'God’s Promise to David — 2 Sam 7:12–13',
            descriptionOverride: 'God keeps His promises. Whisper a short prayer of trust for your future.',
          ),
        ],
        rewards: const [Reward(type: RewardTypes.xp, amount: 300, label: '300 XP')],
      ),
    ];
  }
}
