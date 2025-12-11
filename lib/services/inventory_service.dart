import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:level_up_your_faith/models/inventory_item.dart';
import 'package:level_up_your_faith/models/player_inventory.dart';
import 'package:level_up_your_faith/services/storage_service.dart';

/// Minimal local inventory service for cosmetic/gear/items.
class InventoryService {
  final StorageService _storage;
  InventoryService(this._storage);

  String _newKey(String uid) => 'player_inventory_$uid';
  String _legacyKey(String uid) => 'inventory_$uid';

  Future<PlayerInventory> getInventoryForUser(String uid) async {
    try {
      final raw = _storage.getString(_newKey(uid));
      if (raw != null && raw.trim().isNotEmpty) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        return PlayerInventory.fromJson(json);
      }
      // migrate if legacy exists
      final legacyRaw = _storage.getString(_legacyKey(uid));
      if (legacyRaw != null && legacyRaw.trim().isNotEmpty) {
        return await _migrateLegacy(uid, legacyRaw);
      }
      return PlayerInventory.empty();
    } catch (e) {
      debugPrint('InventoryService.getInventoryForUser error: $e');
      return PlayerInventory.empty();
    }
  }

  Future<void> _saveInventory(String uid, PlayerInventory inv) async {
    try {
      await _storage.save(_newKey(uid), jsonEncode(inv.toJson()));
    } catch (e) {
      debugPrint('InventoryService._saveInventory error: $e');
    }
  }

  Future<PlayerInventory> addItemToInventory(
    String uid,
    String itemId,
    InventoryItem item, {
    bool autoEquip = false,
  }) async {
    final inv = await getInventoryForUser(uid);
    final owned = {...inv.items};
    final ownedIds = {...inv.ownedIds};
    final isNew = !owned.containsKey(itemId);
    owned[itemId] = item;
    ownedIds.add(itemId);

    var equipped = inv.equipped;
    if ((autoEquip || isNew) && (item.type == 'gear' || item.type == 'cosmetic')) {
      final slot = (item.meta['slot']?.toString() ?? '').trim();
      if (slot.isNotEmpty) {
        if (item.type == 'gear') {
          final gs = Map<String, String?>.from(equipped.gearSlots);
          gs.putIfAbsent(slot, () => null);
          if (gs[slot] == null) {
            gs[slot] = itemId;
            equipped = equipped.copyWith(gearSlots: gs);
          }
        } else if (item.type == 'cosmetic') {
          final cs = Map<String, String?>.from(equipped.cosmetics);
          cs.putIfAbsent(slot, () => null);
          if (cs[slot] == null) {
            cs[slot] = itemId;
            equipped = equipped.copyWith(cosmetics: cs);
          }
        }
      }
    }

    final updated = inv.copyWith(items: owned, ownedIds: ownedIds.toList(), equipped: equipped);
    await _saveInventory(uid, updated);
    return updated;
  }

  Future<PlayerInventory> removeItemFromInventory(String uid, String itemId) async {
    final inv = await getInventoryForUser(uid);
    final items = {...inv.items}..remove(itemId);
    final ownedIds = inv.ownedIds.where((e) => e != itemId).toList();

    // unequip if equipped
    var equipped = inv.equipped;
    final gs = Map<String, String?>.from(equipped.gearSlots);
    final cs = Map<String, String?>.from(equipped.cosmetics);
    gs.updateAll((key, value) => value == itemId ? null : value);
    cs.updateAll((key, value) => value == itemId ? null : value);
    equipped = equipped.copyWith(gearSlots: gs, cosmetics: cs);

    final updated = inv.copyWith(items: items, ownedIds: ownedIds, equipped: equipped);
    await _saveInventory(uid, updated);
    return updated;
  }

  Future<PlayerInventory> equipItem(String uid, String slotType, String slotKey, String itemId) async {
    final inv = await getInventoryForUser(uid);
    var equipped = inv.equipped;
    if (slotType == 'gear') {
      final gs = Map<String, String?>.from(equipped.gearSlots);
      gs[slotKey] = itemId;
      equipped = equipped.copyWith(gearSlots: gs);
    } else if (slotType == 'cosmetic') {
      final cs = Map<String, String?>.from(equipped.cosmetics);
      cs[slotKey] = itemId;
      equipped = equipped.copyWith(cosmetics: cs);
    }
    final updated = inv.copyWith(equipped: equipped);
    await _saveInventory(uid, updated);
    return updated;
  }

  Future<PlayerInventory> unequipItem(String uid, String slotType, String slotKey) async {
    final inv = await getInventoryForUser(uid);
    var equipped = inv.equipped;
    if (slotType == 'gear') {
      final gs = Map<String, String?>.from(equipped.gearSlots);
      gs[slotKey] = null;
      equipped = equipped.copyWith(gearSlots: gs);
    } else if (slotType == 'cosmetic') {
      final cs = Map<String, String?>.from(equipped.cosmetics);
      cs[slotKey] = null;
      equipped = equipped.copyWith(cosmetics: cs);
    }
    final updated = inv.copyWith(equipped: equipped);
    await _saveInventory(uid, updated);
    return updated;
  }

  Future<bool> isOwned(String uid, String itemId) async {
    final inv = await getInventoryForUser(uid);
    return inv.ownedIds.contains(itemId);
  }

  // -------- Legacy compatibility --------
  Future<void> addItem(String id, {String rarity = 'common', Map<String, dynamic>? meta, String uid = 'local'}) async {
    // Map to new schema with minimal fields
    final item = InventoryItem(
      id: id,
      type: (meta?['type']?.toString() ?? 'item'),
      name: id.replaceAll('_', ' '),
      description: '',
      rarity: rarity,
      iconKey: meta?['iconKey']?.toString(),
      meta: meta ?? <String, dynamic>{},
    );
    await addItemToInventory(uid, id, item, autoEquip: false);
  }

  Future<Map<String, dynamic>> getAll({String uid = 'local'}) async {
    // For compatibility, return flat map of id -> {rarity, meta}
    final inv = await getInventoryForUser(uid);
    final out = <String, dynamic>{};
    for (final e in inv.items.entries) {
      out[e.key] = {
        'rarity': e.value.rarity,
        'meta': e.value.meta,
      };
    }
    return out;
  }

  Future<PlayerInventory> _migrateLegacy(String uid, String legacyRaw) async {
    try {
      final decoded = jsonDecode(legacyRaw);
      final map = (decoded is Map) ? decoded.cast<String, dynamic>() : <String, dynamic>{};
      final items = <String, InventoryItem>{};
      final ownedIds = <String>[];
      map.forEach((id, value) {
        try {
          final rarity = (value is Map && value['rarity'] != null) ? value['rarity'].toString() : 'common';
          final meta = (value is Map && value['meta'] is Map) ? (value['meta'] as Map).cast<String, dynamic>() : <String, dynamic>{};
          final item = InventoryItem(
            id: id,
            type: (meta['type']?.toString() ?? 'item'),
            name: id.replaceAll('_', ' '),
            description: '',
            rarity: rarity,
            iconKey: meta['iconKey']?.toString(),
            meta: meta,
          );
          items[id] = item;
          ownedIds.add(id);
        } catch (_) {}
      });
      final inv = PlayerInventory(items: items, ownedIds: ownedIds, equipped: const EquippedState());
      await _saveInventory(uid, inv);
      // remove legacy key to avoid re-migration loops
      await _storage.delete(_legacyKey(uid));
      return inv;
    } catch (e) {
      debugPrint('InventoryService._migrateLegacy error: $e');
      return PlayerInventory.empty();
    }
  }
}
