import 'package:flutter/foundation.dart';

/// Scripture Quest — RewardEvent
/// Represents a queued artifact reveal event associated with a completed book
/// or milestone. The UI will present these in a full-screen reveal modal.
@immutable
class RewardEvent {
  final String? bookId; // Display book name, e.g., "Exodus". Nullable for non-book milestones.
  final String? questId; // Quest id if this reward came from a quest
  final String gearId; // Canonical gear id from seeds
  final String rarity; // lower-case rarity string (common|uncommon|rare|epic|legendary)
  final DateTime timestamp;

  const RewardEvent({
    required this.bookId,
    this.questId,
    required this.gearId,
    required this.rarity,
    required this.timestamp,
  });

  // Factory for quest rewards
  factory RewardEvent.forQuest({required String questId, required String gearId, required String rarity, DateTime? timestamp}) {
    return RewardEvent(
      bookId: null,
      questId: questId,
      gearId: gearId,
      rarity: rarity,
      timestamp: timestamp ?? DateTime.now(),
    );
  }
}
