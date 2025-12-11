import 'package:flutter/foundation.dart';
import 'package:level_up_your_faith/models/gear_item.dart';

/// Faith Power v1.0 — respectful, game-only progress score
/// Pure calculation: no IO. Inputs are level, books mastered, and equipped artifacts.
class FaithPowerService {
  const FaithPowerService();

  int calculateFaithPower({
    required int soulLevel,
    required int booksMasteredCount,
    required List<GearItem> equippedArtifacts,
  }) {
    try {
      final level = soulLevel.clamp(0, 9999);
      final mastered = booksMasteredCount.clamp(0, 9999);
      final baseFromLevel = level * 10;
      final baseFromArtifacts = equippedArtifacts
          .map((a) => a.blessingValue)
          .fold<int>(0, (a, b) => a + (b < 0 ? 0 : b));
      final baseFromMastery = mastered * 5;

      final basePower = baseFromLevel + baseFromArtifacts + baseFromMastery;

      // v1.0: no multipliers. Future TODO: streak/achievement gentle boosts.
      return basePower;
    } catch (e) {
      debugPrint('FaithPowerService.calculateFaithPower error: $e');
      return 0;
    }
  }
}
