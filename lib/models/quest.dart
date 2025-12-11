import 'package:level_up_your_faith/models/reward.dart';

class Quest {
  final String id;
  final String title;
  final String description;
  // daily | weekly | reflection | special
  final String type;
  final int progress;
  final int goal;
  final int xpReward;
  final List<Reward> rewards; // unified rewards for board quests
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isCompleted;

  const Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.progress,
    required this.goal,
    required this.xpReward,
    this.rewards = const [],
    required this.createdAt,
    this.expiresAt,
    this.isCompleted = false,
  });

  double get progressPercent => goal > 0 ? (progress / goal).clamp(0.0, 1.0) : 0.0;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  Quest copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    int? progress,
    int? goal,
    int? xpReward,
    List<Reward>? rewards,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isCompleted,
  }) {
    return Quest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      progress: progress ?? this.progress,
      goal: goal ?? this.goal,
      xpReward: xpReward ?? this.xpReward,
      rewards: rewards ?? this.rewards,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
