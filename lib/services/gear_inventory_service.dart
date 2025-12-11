import 'package:flutter/foundation.dart';
import '../models/gear_item.dart';
import '../models/spiritual_stats.dart';
import '../data/gear_seeds.dart';

/// Non-persistent, in-memory gear equip manager.
///
/// Deliberately separate from the existing InventoryService used for
/// legacy inventory persistence to avoid breaking current features.
class DevConfig {
  // Defaults are safe for release. They are toggled via assert in debug only.
  static bool devAutoSeedEnabled = false;
  static int devAutoSeedCount = 5;
}

class GearInventoryService extends ChangeNotifier {
  GearInventoryService({
    List<GearItem>? initialInventory,
    Map<GearSlot, GearItem>? initialEquipped,
  })  : _inventory = initialInventory ?? <GearItem>[],
        _equipped = initialEquipped ?? <GearSlot, GearItem>{} {
    // Debug-only auto seeding from canonical list. Will not run in release.
    assert(() {
      // Enable dev auto seed by default in debug builds.
      DevConfig.devAutoSeedEnabled = true;
      DevConfig.devAutoSeedCount = DevConfig.devAutoSeedCount <= 0
          ? 5
          : DevConfig.devAutoSeedCount;

      if (DevConfig.devAutoSeedEnabled && _inventory.isEmpty) {
        seedFromCanonical(
          limit: DevConfig.devAutoSeedCount,
          skipDuplicatesById: true,
        );
      }
      return true;
    }());
  }

  final List<GearItem> _inventory;
  final Map<GearSlot, GearItem> _equipped;

  List<GearItem> get inventory => List.unmodifiable(_inventory);
  Map<GearSlot, GearItem> get equipped => Map.unmodifiable(_equipped);

  // Rarity rank: higher is better for sorting (Legendary -> Common)
  int _rarityRank(GearRarity r) {
    switch (r) {
      case GearRarity.legendary:
        return 5;
      case GearRarity.epic:
        return 4;
      case GearRarity.rare:
        return 3;
      case GearRarity.uncommon:
        return 2;
      case GearRarity.common:
        return 1;
    }
  }

  // Slot order: head, chest, hands, legs, feet, charm, hand, artifact
  int _slotRank(GearSlot s) {
    switch (s) {
      case GearSlot.head:
        return 1;
      case GearSlot.chest:
        return 2;
      case GearSlot.hands:
        return 3;
      case GearSlot.legs:
        return 4;
      case GearSlot.feet:
        return 5;
      case GearSlot.charm:
        return 6;
      case GearSlot.hand:
        return 7;
      case GearSlot.artifact:
        return 8;
    }
  }

  SpiritualStats get totalEquippedStats {
    SpiritualStats total = const SpiritualStats.zero();
    for (final item in _equipped.values) {
      total = total + item.stats;
    }
    return total;
  }

  /// Number of artifacts/items collected so far (current inventory size)
  int get totalArtifactsCollected => _inventory.length;

  /// Returns a new list sorted by rarity DESC, then slot order, then name ASC.
  List<GearItem> getSortedInventory() {
    final list = List<GearItem>.from(_inventory);
    list.sort((a, b) {
      final r = _rarityRank(b.rarity).compareTo(_rarityRank(a.rarity));
      if (r != 0) return r;
      final s = _slotRank(a.slot).compareTo(_slotRank(b.slot));
      if (s != 0) return s;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  /// Top N artifacts for previews.
  List<GearItem> getFeaturedArtifacts({int max = 3}) {
    final sorted = getSortedInventory();
    if (sorted.length <= max) return sorted;
    return sorted.sublist(0, max);
  }

  void addItem(GearItem item) {
    _inventory.add(item);
    notifyListeners();
  }

  void removeItem(String id) {
    _inventory.removeWhere((i) => i.id == id);
    _equipped.removeWhere((slot, item) => item.id == id);
    notifyListeners();
  }

  bool containsItem(String id) => _inventory.any((i) => i.id == id);

  /// Adds many items at once. Optionally skips duplicates by id.
  void addItemsBulk(Iterable<GearItem> items, {bool skipDuplicatesById = true}) {
    final toAdd = <GearItem>[];
    for (final item in items) {
      if (skipDuplicatesById && containsItem(item.id)) continue;
      toAdd.add(item);
    }
    if (toAdd.isEmpty) return;
    _inventory.addAll(toAdd);
    notifyListeners();
  }

  bool isEquipped(GearItem item) {
    return _equipped[item.slot]?.id == item.id;
  }

  /// Equip by id. Gracefully ignores invalid ids or items not in inventory.
  /// Replaces whatever is currently in the item's slot.
  void equipGear(String gearId) {
    try {
      final id = gearId.trim();
      if (id.isEmpty) return;
      final item = _inventory.firstWhere(
        (i) => i.id == id,
        orElse: () => const GearItem(
          id: '',
          name: '',
          subtitle: null,
          slot: GearSlot.head,
          rarity: GearRarity.common,
          description: '',
          stats: SpiritualStats.zero(),
        ),
      );
      if (item.id.isEmpty) return; // not found in inventory; ignore
      _equipped[item.slot] = item;
      notifyListeners();
    } catch (e) {
      debugPrint('equipGear error: $e');
    }
  }

  void equipItem(GearItem item) {
    final exists = _inventory.any((i) => i.id == item.id);
    if (!exists) return;
    _equipped[item.slot] = item;
    notifyListeners();
  }

  void unequipSlot(GearSlot slot) {
    if (_equipped.containsKey(slot)) {
      _equipped.remove(slot);
      notifyListeners();
    }
  }

  void toggleEquip(GearItem item) {
    if (isEquipped(item)) {
      unequipSlot(item.slot);
    } else {
      equipItem(item);
    }
  }

  /// Optionally seed from the canonical Gear List 1.0.
  /// Does nothing if [limit] is 0. Skips duplicates by default.
  void seedFromCanonical({int? limit, bool skipDuplicatesById = true}) {
    Iterable<GearItem> seeds = kGearSeedList;
    if (limit != null && limit >= 0) {
      seeds = seeds.take(limit);
    }
    addItemsBulk(seeds, skipDuplicatesById: skipDuplicatesById);
  }

  /// Temporary seed items for local testing and layout.
  /// No-ops if inventory already contains items.
  void seedDebugItems() {
    if (_inventory.isNotEmpty) return;

    addItem(
      GearItem(
        id: 'head_lamp_of_psalms',
        name: 'Lamp of the Psalms',
        subtitle: '“Thy word is a lamp unto my feet”',
        slot: GearSlot.head,
        rarity: GearRarity.rare,
        description:
            'A gentle glow reminding you to bring emotions to God in prayer.',
        stats: const SpiritualStats(wisdom: 2, discipline: 1, compassion: 1),
      ),
    );

    addItem(
      GearItem(
        id: 'chest_focus_breastplate',
        name: 'Breastplate of Focus',
        subtitle: 'Guarding your attention.',
        slot: GearSlot.chest,
        rarity: GearRarity.epic,
        description:
            'Helps you tune out distractions and stay present in Scripture.',
        stats: const SpiritualStats(wisdom: 1, discipline: 3, witness: 1),
      ),
    );

    addItem(
      GearItem(
        id: 'charm_prayer_ring',
        name: 'Circle of Prayer',
        subtitle: 'A reminder to talk with God.',
        slot: GearSlot.charm,
        rarity: GearRarity.uncommon,
        description: 'Seeing it reminds you to pause and pray.',
        stats: const SpiritualStats(discipline: 2, compassion: 2),
      ),
    );
  }
}
