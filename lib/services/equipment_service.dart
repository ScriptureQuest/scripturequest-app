import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:level_up_your_faith/services/storage_service.dart';

/// Soul Avatar equipment slots (v1.0)
/// These are high-level, peaceful artifact placements.
enum SlotType { head, chest, hand, relic1, relic2, aura }

class EquipmentService {
  final StorageService _storage;
  String? _uid; // per-user storage key segment
  Map<SlotType, String?> _equipped = {
    SlotType.head: null,
    SlotType.chest: null,
    SlotType.hand: null,
    SlotType.relic1: null,
    SlotType.relic2: null,
    SlotType.aura: null,
  };

  EquipmentService(this._storage);

  String _key(String uid) => 'equipment_slots_v1_$uid';

  Map<SlotType, String?> get equipped => Map.unmodifiable(_equipped);

  Future<void> setUser(String? uid) async {
    try {
      _uid = (uid == null || uid.trim().isEmpty) ? null : uid.trim();
      if (_uid == null) {
        // Reset to empty for signed-out/local state
        _equipped = {
          SlotType.head: null,
          SlotType.chest: null,
          SlotType.hand: null,
          SlotType.relic1: null,
          SlotType.relic2: null,
          SlotType.aura: null,
        };
        return;
      }
      await _load();
    } catch (e) {
      debugPrint('EquipmentService.setUser error: $e');
    }
  }

  Future<void> _load() async {
    try {
      final uid = _uid;
      if (uid == null) return;
      final raw = _storage.getString(_key(uid));
      if (raw == null || raw.trim().isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final map = decoded.cast<String, dynamic>();
      final out = <SlotType, String?>{};
      for (final t in SlotType.values) {
        final k = describeEnum(t);
        final v = map[k];
        out[t] = (v == null || v.toString().trim().isEmpty) ? null : v.toString();
      }
      _equipped = out;
    } catch (e) {
      debugPrint('EquipmentService._load error: $e');
    }
  }

  Future<void> _save() async {
    try {
      final uid = _uid;
      if (uid == null) return;
      final map = <String, String?>{};
      _equipped.forEach((k, v) {
        map[describeEnum(k)] = v;
      });
      await _storage.save(_key(uid), jsonEncode(map));
    } catch (e) {
      debugPrint('EquipmentService._save error: $e');
    }
  }

  String? getEquipped(SlotType slot) => _equipped[slot];

  Future<void> equip(SlotType slot, String artifactId) async {
    try {
      final id = artifactId.trim();
      if (id.isEmpty) return;
      _equipped[slot] = id;
      await _save();
    } catch (e) {
      debugPrint('EquipmentService.equip error: $e');
    }
  }

  Future<void> unequip(SlotType slot) async {
    try {
      if (!_equipped.containsKey(slot)) return;
      _equipped[slot] = null;
      await _save();
    } catch (e) {
      debugPrint('EquipmentService.unequip error: $e');
    }
  }
}
