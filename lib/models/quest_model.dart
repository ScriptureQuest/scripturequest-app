import 'package:level_up_your_faith/models/reward.dart';

/// Tasks v2.0 categories for lightweight surfacing in UI
/// - daily: short habits, reset each morning
/// - nightly: end-of-day reflection actions, shown as "Tonight"
/// - reflection: deeper, no-pressure tasks that do not reset daily
enum TaskCategory { daily, nightly, reflection }

class TaskModel {
  final String id;
  final String title;
  final String description;
  // Legacy field used previously for grouping (daily/weekly/challenge)
  // Kept for backward compatibility with older data/UI
  final String type;
  // Legacy categorical grouping used widely across the app prior to Tasks v2.0
  // Examples: 'daily', 'weekly', 'beginner', 'event', 'book'
  // Do not remove — other systems still reference this string.
  final String category;
  // Tasks v2.0 explicit category. If null, derive using resolvedCategory.
  final TaskCategory? taskCategory;
  // v1.0 frequency flag: once (default), daily, weekly
  // Used for lightweight rotation buckets without breaking older data.
  final String questFrequency;
  // Optional scripture reference such as "John 3:16"
  final String? scriptureReference;
  // Difficulty: Easy / Medium / Hard
  final String difficulty;
  // Faith-focused enhancements
  // Quest type: scripture_reading, prayer, reflection, service, community
  final String questType;
  // Spiritual focus label such as "Faith", "Hope", "Love"
  final String? spiritualFocus;
  // Optional reflection prompt presented on completion
  final String? reflectionPrompt;
  // Solo/with others flags
  final bool isSolo;
  final bool isWithOthers;
  // Convenience flags
  final bool isDaily;
  final bool isWeekly;
  // Integrity flag — when true, quest progress is driven by real in-app events only.
  // When false, quest may allow a gentle manual completion (rare, offline-only tasks).
  final bool isAutoTracked;
  // Progress data
  final int targetCount;
  final int currentProgress;
  final int xpReward;
  // Unified rewards list (xp + items + titles ...). Backward-compatible with xpReward.
  final List<Reward> rewards;
  // Quest-specific loot metadata (Build 3.6):
  // Canonical gear ids that this quest can reward on completion.
  final List<String> possibleRewardGearIds;
  // If provided, the first time this quest is completed, guarantee this reward id.
  final String? guaranteedFirstClearGearId;
  // Status: not_started / in_progress / completed / expired
  final String status;
  // v2.0: whether user has claimed the completion rewards
  final bool isClaimed;
  final DateTime startDate;
  final DateTime? endDate;
  // When the quest was completed (if completed)
  final DateTime? completedAt;
  // Tasks v2.0 — track when a task was completed last (for daily reset checks)
  final DateTime? lastCompletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Tasks v2.0 — whether this task should reset visibility daily (default true)
  final bool autoResetDaily;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    this.type = 'daily',
    this.category = 'daily',
    this.taskCategory,
    this.questFrequency = 'once',
    this.scriptureReference,
    this.difficulty = 'Easy',
    this.questType = 'scripture_reading',
    this.spiritualFocus,
    this.reflectionPrompt,
    this.isSolo = true,
    this.isWithOthers = false,
    this.isDaily = false,
    this.isWeekly = false,
    this.isAutoTracked = true,
    required this.targetCount,
    this.currentProgress = 0,
    required this.xpReward,
    this.rewards = const [],
    this.possibleRewardGearIds = const <String>[],
    this.guaranteedFirstClearGearId,
    this.status = 'not_started',
    this.isClaimed = false,
    required this.startDate,
    this.endDate,
    this.completedAt,
    this.lastCompletedAt,
    required this.createdAt,
    required this.updatedAt,
    this.autoResetDaily = true,
  });

  bool get isCompleted => status == 'completed';
  bool get isExpired => status == 'expired';
  bool get isInProgress => status == 'in_progress';
  bool get isNotStarted => status == 'not_started';
  double get progress => targetCount > 0 ? currentProgress / targetCount : 0;

  /// Tasks v2.0: compute the effective category for the task.
  /// Priority:
  /// 1) Explicit taskCategory field if present
  /// 2) Nightly if legacy type == 'nightly'
  /// 3) Daily if legacy category/type/flags imply daily
  /// 4) Reflection if questType suggests reflection/prayer
  /// 5) Fallback to daily
  TaskCategory get resolvedCategory {
    if (taskCategory != null) return taskCategory!;
    // Nightly: explicit legacy type hint
    if (type.trim().toLowerCase() == 'nightly') return TaskCategory.nightly;

    final cat = category.trim().toLowerCase();
    final freq = questFrequency.trim().toLowerCase();
    if (cat == 'daily' || isDaily || freq == 'daily' || type.trim().toLowerCase() == 'daily') {
      return TaskCategory.daily;
    }
    // Heuristic: reflection/prayer tasks are shown under Reflection if not daily
    final qtype = questType.trim().toLowerCase();
    if (qtype == 'reflection' || qtype == 'prayer') return TaskCategory.reflection;
    // Default to daily to keep visibility
    return TaskCategory.daily;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type,
    'category': category,
    // Persist v2.0 category as a string for forward-compat; optional
    'taskCategory': taskCategory?.name,
    'questFrequency': questFrequency,
    'scriptureReference': scriptureReference,
    'difficulty': difficulty,
    'questType': questType,
    'spiritualFocus': spiritualFocus,
    'reflectionPrompt': reflectionPrompt,
    'isSolo': isSolo,
    'isWithOthers': isWithOthers,
    'isDaily': isDaily,
    'isWeekly': isWeekly,
    'isAutoTracked': isAutoTracked,
    'targetCount': targetCount,
    'currentProgress': currentProgress,
    'xpReward': xpReward,
    'rewards': rewards.map((r) => r.toJson()).toList(),
    'possibleRewardGearIds': possibleRewardGearIds,
    'guaranteedFirstClearGearId': guaranteedFirstClearGearId,
    'status': status,
    'isClaimed': isClaimed,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'lastCompletedAt': lastCompletedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'autoResetDaily': autoResetDaily,
  };

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
    id: (json['id'] ?? '').toString(),
    title: (json['title'] ?? '').toString(),
    description: (json['description'] ?? '').toString(),
    type: (json['type'] ?? 'daily').toString(),
    category: (json['category'] ?? (json['type'] ?? 'daily')).toString(),
    taskCategory: _parseTaskCategory(json['taskCategory']),
    questFrequency: (json['questFrequency'] ?? 'once').toString(),
    scriptureReference: json['scriptureReference'],
    difficulty: (json['difficulty'] ?? 'Easy').toString(),
    questType: (json['questType'] ?? 'scripture_reading').toString(),
    spiritualFocus: json['spiritualFocus'],
    reflectionPrompt: json['reflectionPrompt'],
    isSolo: json['isSolo'] ?? true,
    isWithOthers: json['isWithOthers'] ?? false,
    isDaily: json['isDaily'] ?? (json['type'] == 'daily'),
    isWeekly: json['isWeekly'] ?? (json['type'] == 'weekly'),
    isAutoTracked: json['isAutoTracked'] == null ? true : (json['isAutoTracked'] == true),
    targetCount: json['targetCount'] ?? 1,
    currentProgress: json['currentProgress'] ?? 0,
    xpReward: json['xpReward'] ?? 10,
    rewards: (json['rewards'] is List)
        ? List<Map<String, dynamic>>.from(json['rewards'] as List)
            .map(Reward.fromJson)
            .toList()
        : const [],
    possibleRewardGearIds: (json['possibleRewardGearIds'] is List)
        ? (json['possibleRewardGearIds'] as List).map((e) => e.toString()).toList()
        : const <String>[],
    guaranteedFirstClearGearId: (json['guaranteedFirstClearGearId'] ?? '')
            .toString()
            .trim()
            .isEmpty
        ? null
        : (json['guaranteedFirstClearGearId'] as String?)?.trim(),
    status: _normalizeStatus(json['status']),
    isClaimed: json['isClaimed'] == true,
    startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : DateTime.now(),
    endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    lastCompletedAt: json['lastCompletedAt'] != null ? DateTime.parse(json['lastCompletedAt']) : null,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    autoResetDaily: json['autoResetDaily'] == null ? true : (json['autoResetDaily'] == true),
  );

  static String _normalizeStatus(dynamic raw) {
    final value = (raw ?? '').toString();
    if (value.isEmpty) return 'not_started';
    // Map legacy 'active' -> 'not_started'
    if (value == 'active') return 'not_started';
    return value;
  }

  static TaskCategory? _parseTaskCategory(dynamic raw) {
    try {
      final s = (raw ?? '').toString().trim();
      switch (s) {
        case 'daily':
          return TaskCategory.daily;
        case 'nightly':
          return TaskCategory.nightly;
        case 'reflection':
          return TaskCategory.reflection;
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    String? category,
    TaskCategory? taskCategory,
    String? questFrequency,
    String? scriptureReference,
    String? difficulty,
    String? questType,
    String? spiritualFocus,
    String? reflectionPrompt,
    bool? isSolo,
    bool? isWithOthers,
    bool? isDaily,
    bool? isWeekly,
    bool? isAutoTracked,
    int? targetCount,
    int? currentProgress,
    int? xpReward,
    List<Reward>? rewards,
    List<String>? possibleRewardGearIds,
    String? guaranteedFirstClearGearId,
    String? status,
    bool? isClaimed,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? completedAt,
    DateTime? lastCompletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? autoResetDaily,
  }) => TaskModel(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    type: type ?? this.type,
    category: category ?? this.category,
    taskCategory: taskCategory ?? this.taskCategory,
    questFrequency: questFrequency ?? this.questFrequency,
    scriptureReference: scriptureReference ?? this.scriptureReference,
    difficulty: difficulty ?? this.difficulty,
    questType: questType ?? this.questType,
    spiritualFocus: spiritualFocus ?? this.spiritualFocus,
    reflectionPrompt: reflectionPrompt ?? this.reflectionPrompt,
    isSolo: isSolo ?? this.isSolo,
    isWithOthers: isWithOthers ?? this.isWithOthers,
    isDaily: isDaily ?? this.isDaily,
    isWeekly: isWeekly ?? this.isWeekly,
    isAutoTracked: isAutoTracked ?? this.isAutoTracked,
    targetCount: targetCount ?? this.targetCount,
    currentProgress: currentProgress ?? this.currentProgress,
    xpReward: xpReward ?? this.xpReward,
    rewards: rewards ?? this.rewards,
    possibleRewardGearIds: possibleRewardGearIds ?? this.possibleRewardGearIds,
    guaranteedFirstClearGearId: guaranteedFirstClearGearId ?? this.guaranteedFirstClearGearId,
    status: status ?? this.status,
    isClaimed: isClaimed ?? this.isClaimed,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    completedAt: completedAt ?? this.completedAt,
    lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    autoResetDaily: autoResetDaily ?? this.autoResetDaily,
  );
}
