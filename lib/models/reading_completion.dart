/// Actual saved deltas from one reader action; not a second reward calculator.
class ReadingCompletion {
  final String reference;
  final bool qualified;
  final int xp;
  final int levelBefore;
  final int levelAfter;
  final List<String> changes;
  final List<String> achievementIds;
  final bool discovered;
  final List<String> discoveryIds;
  final List<String> keepsakes;
  final String? nextJourneyId;
  const ReadingCompletion(
      {required this.reference,
      required this.qualified,
      required this.xp,
      required this.levelBefore,
      required this.levelAfter,
      required this.changes,
      required this.achievementIds,
      required this.discovered,
      this.nextJourneyId,
      this.discoveryIds = const [],
      this.keepsakes = const []});
}
