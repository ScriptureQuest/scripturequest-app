class TitleModel {
  final String id;
  final String name;
  final String description;
  // Unlock conditions
  final String? unlockAchievementId; // unlocked when this achievement is unlocked
  final String? unlockQuestlineId; // special-case: on completing this questline

  const TitleModel({
    required this.id,
    required this.name,
    required this.description,
    this.unlockAchievementId,
    this.unlockQuestlineId,
  });
}
