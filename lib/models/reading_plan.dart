import 'package:flutter/foundation.dart';

class ReadingPlanStep {
  final int stepIndex; // 0-based index
  final List<String> referenceList; // e.g., ["Matthew 1", "Matthew 2"]
  final String friendlyLabel; // e.g., "Day 1: Read Matthew 1–2"

  const ReadingPlanStep({
    required this.stepIndex,
    required this.referenceList,
    required this.friendlyLabel,
  });

  ReadingPlanStep copyWith({int? stepIndex, List<String>? referenceList, String? friendlyLabel}) =>
      ReadingPlanStep(
        stepIndex: stepIndex ?? this.stepIndex,
        referenceList: referenceList ?? this.referenceList,
        friendlyLabel: friendlyLabel ?? this.friendlyLabel,
      );

  Map<String, dynamic> toJson() => {
        'stepIndex': stepIndex,
        'referenceList': referenceList,
        'friendlyLabel': friendlyLabel,
      };

  factory ReadingPlanStep.fromJson(Map<String, dynamic> json) {
    try {
      final refs = (json['referenceList'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => e.toString())
          .toList();
      return ReadingPlanStep(
        stepIndex: json['stepIndex'] is int ? (json['stepIndex'] as int) : int.tryParse('${json['stepIndex']}') ?? 0,
        referenceList: refs,
        friendlyLabel: (json['friendlyLabel'] ?? '').toString(),
      );
    } catch (e) {
      debugPrint('ReadingPlanStep.fromJson error: $e');
      return ReadingPlanStep(stepIndex: 0, referenceList: const [], friendlyLabel: '');
    }
  }
}

class ReadingPlan {
  final String planId;
  final String title;
  final String subtitle;
  final String description;
  final List<ReadingPlanStep> days; // ordered steps

  // Optional metadata flags for future use; not strictly required for seeds
  final bool isActive; // default false for seeds

  const ReadingPlan({
    required this.planId,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.days,
    this.isActive = false,
  });

  int get totalDays => days.length;

  ReadingPlan copyWith({
    String? planId,
    String? title,
    String? subtitle,
    String? description,
    List<ReadingPlanStep>? days,
    bool? isActive,
  }) =>
      ReadingPlan(
        planId: planId ?? this.planId,
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        description: description ?? this.description,
        days: days ?? this.days,
        isActive: isActive ?? this.isActive,
      );

  Map<String, dynamic> toJson() => {
        'planId': planId,
        'title': title,
        'subtitle': subtitle,
        'description': description,
        'days': days.map((e) => e.toJson()).toList(),
        'isActive': isActive,
      };

  factory ReadingPlan.fromJson(Map<String, dynamic> json) {
    try {
      final list = (json['days'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => e is Map<String, dynamic> ? ReadingPlanStep.fromJson(e) : ReadingPlanStep.fromJson(e.cast<String, dynamic>()))
          .toList();
      return ReadingPlan(
        planId: (json['planId'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        subtitle: (json['subtitle'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        days: list,
        isActive: (json['isActive'] is bool) ? json['isActive'] as bool : false,
      );
    } catch (e) {
      debugPrint('ReadingPlan.fromJson error: $e');
      return ReadingPlan(planId: '', title: '', subtitle: '', description: '', days: const <ReadingPlanStep>[]);
    }
  }
}
