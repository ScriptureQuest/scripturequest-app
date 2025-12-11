import 'dart:math';
import 'package:flutter/foundation.dart';

import '../data/gear_seeds.dart';
import '../models/gear_item.dart';
import '../services/gear_inventory_service.dart';

/// Scripture Quest — LootService (Build 3.5)
///
/// Responsible for rarity-weighted selection of canonical artifacts and
/// granting them to the player's in-memory GearInventoryService.
class LootService {
  final GearInventoryService _gear;

  LootService(this._gear);

  // Public: all canonical items (unowned/owned unspecified)
  List<GearItem> get allCanonicalItems => kGearSeedList;

  // Helper: does the player already own the item id?
  bool ownsItem(String id) {
    try {
      return _gear.containsItem(id);
    } catch (e) {
      debugPrint('LootService.ownsItem error: $e');
      return false;
    }
  }

  // Items not yet owned by id
  List<GearItem> getUnownedItems() {
    try {
      return allCanonicalItems
          .where((g) => !_gear.containsItem(g.id))
          .toList(growable: false);
    } catch (e) {
      debugPrint('LootService.getUnownedItems error: $e');
      return const <GearItem>[];
    }
  }

  // Grant a specific item (no duplicates). Returns the granted item or null if already owned.
  GearItem? grantItem(GearItem item) {
    try {
      if (_gear.containsItem(item.id)) return null;
      _gear.addItem(item);
      return item;
    } catch (e) {
      debugPrint('LootService.grantItem error: $e');
      return null;
    }
  }

  // Rarity weights for standard quests
  Map<GearRarity, int> get _rarityWeights => const {
        GearRarity.common: 40,
        GearRarity.uncommon: 30,
        GearRarity.rare: 18,
        GearRarity.epic: 9,
        GearRarity.legendary: 3,
      };

  List<GearItem> _unownedByRarity(GearRarity rarity) {
    final list = getUnownedItems().where((g) => g.rarity == rarity).toList();
    return list;
  }

  // Rolls a rarity based on weights, then falls back to progressively lower
  // rarities if the chosen bucket is empty. Returns null if nothing unowned remains.
  GearRarity? _rollRarityForStandardQuest(Random rng) {
    final unowned = getUnownedItems();
    if (unowned.isEmpty) return null;

    final entries = _rarityWeights.entries.toList();
    final total = entries.fold<int>(0, (a, b) => a + b.value);
    final roll = rng.nextInt(total);

    int accum = 0;
    GearRarity chosen = entries.first.key;
    for (final e in entries) {
      accum += e.value;
      if (roll < accum) {
        chosen = e.key;
        break;
      }
    }

    // Fallback chain to lower rarities
    GearRarity? firstAvailable(GearRarity start) {
      GearRarity? tryRarity(GearRarity r) => _unownedByRarity(r).isNotEmpty ? r : null;

      // order: Legendary -> Epic -> Rare -> Uncommon -> Common, but we need lower-only fallback.
      // We'll implement sequence arrays per starting point.
      List<GearRarity> chain;
      switch (start) {
        case GearRarity.legendary:
          chain = const [GearRarity.legendary, GearRarity.epic, GearRarity.rare, GearRarity.uncommon, GearRarity.common];
          break;
        case GearRarity.epic:
          chain = const [GearRarity.epic, GearRarity.rare, GearRarity.uncommon, GearRarity.common];
          break;
        case GearRarity.rare:
          chain = const [GearRarity.rare, GearRarity.uncommon, GearRarity.common];
          break;
        case GearRarity.uncommon:
          chain = const [GearRarity.uncommon, GearRarity.common];
          break;
        case GearRarity.common:
          chain = const [GearRarity.common];
          break;
      }

      for (final r in chain) {
        final found = tryRarity(r);
        if (found != null) return found;
      }
      return null;
    }

    return firstAvailable(chosen);
  }

  // Pick a random unowned item for a standard quest based on rarity weights.
  GearItem? pickRandomUnownedForStandardQuest(Random rng) {
    final rarity = _rollRarityForStandardQuest(rng);
    if (rarity == null) return null;
    final bucket = _unownedByRarity(rarity);
    if (bucket.isEmpty) return null;
    final idx = rng.nextInt(bucket.length);
    return bucket[idx];
  }

  // Lookup by canonical id, with suffix fallback to support aliases like
  // 'mustard_seed_pendant' -> 'charm_mustard_seed_pendant'.
  GearItem? getById(String id) {
    try {
      final trimmed = id.trim();
      if (trimmed.isEmpty) return null;
      for (final g in allCanonicalItems) {
        if (g.id == trimmed) return g;
      }
      // Fallback: suffix match for ids without slot prefix
      for (final g in allCanonicalItems) {
        if (g.id.endsWith(trimmed)) return g;
      }
      return null;
    } catch (e) {
      debugPrint('LootService.getById error: $e');
      return null;
    }
  }

  // Grant by id if unowned, returns the granted item or null if already owned / not found.
  GearItem? grantByIdIfUnowned(String id) {
    try {
      final item = getById(id);
      if (item == null) return null;
      return grantItem(item);
    } catch (e) {
      debugPrint('LootService.grantByIdIfUnowned error: $e');
      return null;
    }
  }

  // ================== Quest-specific reward logic ==================
  // Grants a quest reward based on provided metadata. Returns the granted item or null.
  // Behavior:
  // - If quest has guaranteedFirstClearGearId and this is the first clear, try to grant it.
  // - Else, pick a random unowned from possibleRewardGearIds.
  // - If none granted (all owned or missing), return null.
  GearItem? grantRewardForQuest(dynamic quest) {
    try {
      // Expect a QuestModel-like object with fields: possibleRewardGearIds, guaranteedFirstClearGearId, completedAt, id
      final List<String> pool = List<String>.from(quest.possibleRewardGearIds ?? const <String>[]);
      if (pool.isEmpty) return null;

      final bool firstClear = (quest.completedAt == null);
      final String? guaranteed = (quest.guaranteedFirstClearGearId as String?);

      // Helper to resolve id with alias support and grant
      GearItem? _grantByEitherId(String rawId) {
        final item = getById(rawId);
        if (item == null) return null;
        return grantItem(item);
      }

      // First-clear guarantee
      if (firstClear && guaranteed != null && guaranteed.trim().isNotEmpty) {
        final granted = _grantByEitherId(guaranteed.trim());
        if (granted != null) return granted;
      }

      // Random unowned from the pool
      final candidates = <GearItem>[];
      for (final id in pool) {
        final item = getById(id);
        if (item != null && !ownsItem(item.id)) {
          candidates.add(item);
        }
      }
      if (candidates.isEmpty) return null;
      final rng = Random();
      final choice = candidates[rng.nextInt(candidates.length)];
      return grantItem(choice);
    } catch (e) {
      debugPrint('LootService.grantRewardForQuest error: $e');
      return null;
    }
  }
}
