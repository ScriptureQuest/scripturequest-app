import 'package:flutter/foundation.dart';
import 'package:level_up_your_faith/models/gear_item.dart';
import 'package:level_up_your_faith/services/equipment_service.dart';
import 'package:level_up_your_faith/services/storage_service.dart';
import 'package:level_up_your_faith/services/gear_inventory_service.dart';

/// Bridges EquipmentService (persistent slot -> artifactId) with GearInventoryService
/// (available artifacts list) for UI.
class EquipmentProvider extends ChangeNotifier {
  EquipmentService? _equipmentService;
  final GearInventoryService gearInventoryService;

  EquipmentProvider({required this.gearInventoryService});

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> setUser(String? uid) async {
    _equipmentService ??= EquipmentService(await StorageService.getInstance());
    await _equipmentService!.setUser(uid);
    _initialized = true;
    notifyListeners();
  }

  Map<SlotType, String?> get equipped => _equipmentService?.equipped ?? const {
        SlotType.head: null,
        SlotType.chest: null,
        SlotType.hand: null,
        SlotType.relic1: null,
        SlotType.relic2: null,
        SlotType.aura: null,
      };

  GearItem? findById(String id) {
    try {
      return gearInventoryService.inventory.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> equip(SlotType slot, String artifactId) async {
    if (_equipmentService == null) return;
    await _equipmentService!.equip(slot, artifactId);
    notifyListeners();
  }

  Future<void> unequip(SlotType slot) async {
    if (_equipmentService == null) return;
    await _equipmentService!.unequip(slot);
    notifyListeners();
  }

  /// Filter inventory items that are valid for a given Soul Avatar slot
  List<GearItem> itemsForSlot(SlotType slot) {
    final inv = gearInventoryService.inventory;
    bool accepts(GearItem i) {
      switch (slot) {
        case SlotType.head:
          return i.slot == GearSlot.head;
        case SlotType.chest:
          return i.slot == GearSlot.chest;
        case SlotType.hand:
          return i.slot == GearSlot.hand;
        case SlotType.relic1:
        case SlotType.relic2:
          return i.slot == GearSlot.artifact || i.slot == GearSlot.charm;
        case SlotType.aura:
          // v1.0: allow artifact/charm as placeholder for aura effects
          return i.slot == GearSlot.artifact || i.slot == GearSlot.charm;
      }
    }
    final list = inv.where(accepts).toList();
    // Sort by rarity then name for nicer UX
    list.sort((a, b) {
      int rank(GearRarity r) {
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

      final rr = rank(b.rarity).compareTo(rank(a.rarity));
      if (rr != 0) return rr;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  /// Returns equipped GearItem models in slot order; missing ids are skipped.
  List<GearItem> getEquippedArtifacts() {
    final out = <GearItem>[];
    final map = equipped;
    GearItem? resolve(String? id) => (id == null || id.trim().isEmpty) ? null : findById(id);
    for (final s in [
      SlotType.head,
      SlotType.chest,
      SlotType.hand,
      SlotType.relic1,
      SlotType.relic2,
      SlotType.aura,
    ]) {
      final item = resolve(map[s]);
      if (item != null) out.add(item);
    }
    return out;
  }
}
