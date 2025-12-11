import 'dart:math';
import 'package:flutter/foundation.dart';

import '../data/book_reward_map.dart';
import '../models/gear_item.dart';
import 'gear_inventory_service.dart';
import 'loot_service.dart';

/// Scripture Quest — BookRewardService (Build 3.6)
///
/// Provides book-to-artifact reward lookups and safe grants that never
/// duplicate owned items. Integrates with the canonical seed list via LootService.
class BookRewardService {
  final GearInventoryService _gear;
  final LootService _loot;

  BookRewardService(this._gear, this._loot);

  /// Returns the configured reward ids for a given display book id.
  List<String> getRewardsForBook(String bookId) {
    try {
      final key = bookId.trim();
      if (key.isEmpty) return const <String>[];
      return List<String>.from(kBookRewardMap[key] ?? const <String>[]);
    } catch (e) {
      debugPrint('BookRewardService.getRewardsForBook error: $e');
      return const <String>[];
    }
  }

  /// Returns the subset of reward GearItems for [bookId] that the player does not yet own.
  List<GearItem> getUnownedRewardsForBook(String bookId) {
    try {
      final ids = getRewardsForBook(bookId);
      if (ids.isEmpty) return const <GearItem>[];
      final items = <GearItem>[];
      for (final id in ids) {
        final item = _loot.getById(id);
        if (item == null) continue; // skip unknown ids
        if (_gear.containsItem(item.id)) continue; // skip owned
        items.add(item);
      }
      return items;
    } catch (e) {
      debugPrint('BookRewardService.getUnownedRewardsForBook error: $e');
      return const <GearItem>[];
    }
  }

  /// Grants ONE random unowned reward for the given [bookId], if available.
  /// Returns the granted item, or null if none available or an error occurs.
  GearItem? grantRewardForBook(String bookId) {
    try {
      final unowned = getUnownedRewardsForBook(bookId);
      if (unowned.isEmpty) return null;
      final rng = Random();
      final choice = unowned[rng.nextInt(unowned.length)];
      return _loot.grantItem(choice);
    } catch (e) {
      debugPrint('BookRewardService.grantRewardForBook error: $e');
      return null;
    }
  }
}
