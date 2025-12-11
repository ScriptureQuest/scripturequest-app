import 'package:level_up_your_faith/models/reward.dart';

class QuestlineStep {
  final String id;
  final String questId; // may be a template key like "tpl:read:John 3:16"
  final int order;
  final String? titleOverride;
  final String? descriptionOverride;
  final List<Reward>? rewards; // optional bonus rewards per step
  final bool isOptional;

  const QuestlineStep({
    required this.id,
    required this.questId,
    required this.order,
    this.titleOverride,
    this.descriptionOverride,
    this.rewards,
    this.isOptional = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'questId': questId,
        'order': order,
        'titleOverride': titleOverride,
        'descriptionOverride': descriptionOverride,
        'rewards': (rewards ?? const <Reward>[]) .map((r) => r.toJson()).toList(),
        'isOptional': isOptional,
      };

  factory QuestlineStep.fromJson(Map<String, dynamic> json) => QuestlineStep(
        id: (json['id'] ?? '').toString(),
        questId: (json['questId'] ?? '').toString(),
        order: json['order'] ?? 0,
        titleOverride: (json['titleOverride'] as String?),
        descriptionOverride: (json['descriptionOverride'] as String?),
        rewards: (json['rewards'] is List)
            ? List<Map<String, dynamic>>.from(json['rewards'] as List)
                .map(Reward.fromJson)
                .toList()
            : null,
        isOptional: json['isOptional'] == true,
      );
}

class Questline {
  final String id;
  final String title;
  final String description;
  final String category; // book | onboarding | streak | seasonal
  // Optional themed tag for UI pills (e.g., "Peace", "Faith").
  final String? themeTag;
  final bool isActive;
  final bool isRepeatable;
  final List<QuestlineStep> steps;
  final List<Reward> rewards; // final completion rewards (optional)
  final String? iconKey;

  const Questline({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.themeTag,
    this.isActive = true,
    this.isRepeatable = false,
    required this.steps,
    this.rewards = const [],
    this.iconKey,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'themeTag': themeTag,
        'isActive': isActive,
        'isRepeatable': isRepeatable,
        'steps': steps.map((s) => s.toJson()).toList(),
        'rewards': rewards.map((r) => r.toJson()).toList(),
        'iconKey': iconKey,
      };

  factory Questline.fromJson(Map<String, dynamic> json) => Questline(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        category: (json['category'] ?? 'onboarding').toString(),
        themeTag: (json['themeTag'] as String?),
        isActive: json['isActive'] != false,
        isRepeatable: json['isRepeatable'] == true,
        steps: (json['steps'] is List)
            ? List<Map<String, dynamic>>.from(json['steps'] as List)
                .map(QuestlineStep.fromJson)
                .toList()
            : const <QuestlineStep>[],
        rewards: (json['rewards'] is List)
            ? List<Map<String, dynamic>>.from(json['rewards'] as List)
                .map(Reward.fromJson)
                .toList()
            : const <Reward>[],
        iconKey: (json['iconKey'] as String?),
      );
}

class QuestlineProgress {
  final String questlineId;
  final List<String> activeStepIds;
  final List<String> completedStepIds;
  final Map<String, String> stepQuestIds; // stepId -> concrete questId
  final DateTime dateStarted;
  final DateTime? dateCompleted;

  const QuestlineProgress({
    required this.questlineId,
    required this.activeStepIds,
    required this.completedStepIds,
    required this.stepQuestIds,
    required this.dateStarted,
    this.dateCompleted,
  });

  bool get isCompleted => dateCompleted != null;

  Map<String, dynamic> toJson() => {
        'questlineId': questlineId,
        'activeStepIds': activeStepIds,
        'completedStepIds': completedStepIds,
        'stepQuestIds': stepQuestIds,
        'dateStarted': dateStarted.toIso8601String(),
        'dateCompleted': dateCompleted?.toIso8601String(),
      };

  factory QuestlineProgress.fromJson(Map<String, dynamic> json) => QuestlineProgress(
        questlineId: (json['questlineId'] ?? '').toString(),
        activeStepIds: (json['activeStepIds'] is List)
            ? List<String>.from((json['activeStepIds'] as List).map((e) => e.toString()))
            : const <String>[],
        completedStepIds: (json['completedStepIds'] is List)
            ? List<String>.from((json['completedStepIds'] as List).map((e) => e.toString()))
            : const <String>[],
        stepQuestIds: (json['stepQuestIds'] is Map)
            ? (json['stepQuestIds'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()))
            : const <String, String>{},
        dateStarted: json['dateStarted'] != null ? DateTime.parse(json['dateStarted']) : DateTime.now(),
        dateCompleted: json['dateCompleted'] != null ? DateTime.parse(json['dateCompleted']) : null,
      );

  QuestlineProgress copyWith({
    List<String>? activeStepIds,
    List<String>? completedStepIds,
    Map<String, String>? stepQuestIds,
    DateTime? dateStarted,
    DateTime? dateCompleted,
  }) => QuestlineProgress(
        questlineId: questlineId,
        activeStepIds: activeStepIds ?? this.activeStepIds,
        completedStepIds: completedStepIds ?? this.completedStepIds,
        stepQuestIds: stepQuestIds ?? this.stepQuestIds,
        dateStarted: dateStarted ?? this.dateStarted,
        dateCompleted: dateCompleted ?? this.dateCompleted,
      );
}

/// Combines definition + progress for convenient UI consumption
class QuestlineProgressView {
  final Questline questline;
  final QuestlineProgress progress;

  const QuestlineProgressView({required this.questline, required this.progress});

  int get totalSteps => questline.steps.length;
  int get completedSteps => progress.completedStepIds.length;
  double get completionRatio => totalSteps == 0 ? 0.0 : (completedSteps / totalSteps).clamp(0, 1).toDouble();
  QuestlineStep? get currentStep {
    if (progress.activeStepIds.isEmpty) return null;
    final id = progress.activeStepIds.first;
    return questline.steps.firstWhere((s) => s.id == id, orElse: () => questline.steps.first);
  }
}
