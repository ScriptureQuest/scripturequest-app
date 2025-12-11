import 'inventory_item.dart';

class PlayerInventory {
  final Map<String, InventoryItem> items; // id -> item
  final List<String> ownedIds; // all owned IDs
  final EquippedState equipped;

  const PlayerInventory({
    required this.items,
    required this.ownedIds,
    required this.equipped,
  });

  factory PlayerInventory.empty() => PlayerInventory(
        items: <String, InventoryItem>{},
        ownedIds: const <String>[],
        equipped: const EquippedState(),
      );

  PlayerInventory copyWith({
    Map<String, InventoryItem>? items,
    List<String>? ownedIds,
    EquippedState? equipped,
  }) {
    return PlayerInventory(
      items: items ?? this.items,
      ownedIds: ownedIds ?? this.ownedIds,
      equipped: equipped ?? this.equipped,
    );
  }

  factory PlayerInventory.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final map = <String, InventoryItem>{};
    if (rawItems is Map) {
      rawItems.forEach((key, value) {
        try {
          final id = key.toString();
          if (value is Map<String, dynamic>) {
            map[id] = InventoryItem.fromJson({...value, 'id': id});
          } else if (value is Map) {
            map[id] = InventoryItem.fromJson(value.cast<String, dynamic>()..['id'] = id);
          }
        } catch (_) {}
      });
    }
    final owned = <String>[];
    final rawOwned = json['ownedIds'];
    if (rawOwned is List) {
      for (final v in rawOwned) {
        final id = v.toString();
        if (id.isNotEmpty) owned.add(id);
      }
    }
    final eq = EquippedState.fromJson(json['equipped'] is Map ? (json['equipped'] as Map).cast<String, dynamic>() : <String, dynamic>{});
    return PlayerInventory(items: map, ownedIds: owned, equipped: eq);
  }

  Map<String, dynamic> toJson() => {
        'items': items.map((k, v) => MapEntry(k, v.toJson())),
        'ownedIds': ownedIds,
        'equipped': equipped.toJson(),
      };
}

class EquippedState {
  final Map<String, String?> gearSlots; // e.g., head/chest/hands/feet
  final Map<String, String?> cosmetics; // e.g., aura/frame
  final String? titleId; // equipped title id

  const EquippedState({
    this.gearSlots = const <String, String?>{
      'head': null,
      'chest': null,
      'hands': null,
      'feet': null,
    },
    this.cosmetics = const <String, String?>{
      'aura': null,
      'frame': null,
    },
    this.titleId,
  });

  EquippedState copyWith({
    Map<String, String?>? gearSlots,
    Map<String, String?>? cosmetics,
    String? titleId,
  }) {
    return EquippedState(
      gearSlots: gearSlots ?? this.gearSlots,
      cosmetics: cosmetics ?? this.cosmetics,
      titleId: titleId ?? this.titleId,
    );
  }

  factory EquippedState.fromJson(Map<String, dynamic> json) {
    Map<String, String?> asMap(dynamic v) {
      final out = <String, String?>{};
      if (v is Map) {
        v.forEach((key, value) {
          out[key.toString()] = value?.toString();
        });
      }
      return out;
    }

    return EquippedState(
      gearSlots: asMap(json['gearSlots']),
      cosmetics: asMap(json['cosmetics']),
      titleId: json['titleId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'gearSlots': gearSlots,
        'cosmetics': cosmetics,
        'titleId': titleId,
      };
}
