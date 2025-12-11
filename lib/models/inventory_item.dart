import 'dart:convert';

class InventoryItem {
  final String id;
  final String type; // gear | cosmetic | title | token | item
  final String name;
  final String description;
  final String rarity; // common | rare | epic | legendary
  final String? iconKey;
  final Map<String, dynamic> meta;

  const InventoryItem({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.rarity,
    this.iconKey,
    this.meta = const {},
  });

  InventoryItem copyWith({
    String? id,
    String? type,
    String? name,
    String? description,
    String? rarity,
    String? iconKey,
    Map<String, dynamic>? meta,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      rarity: rarity ?? this.rarity,
      iconKey: iconKey ?? this.iconKey,
      meta: meta ?? this.meta,
    );
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id']?.toString() ?? '',
      type: (json['type']?.toString() ?? 'item'),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      rarity: (json['rarity']?.toString() ?? 'common'),
      iconKey: json['iconKey']?.toString(),
      meta: _safeMap(json['meta']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'name': name,
        'description': description,
        'rarity': rarity,
        'iconKey': iconKey,
        'meta': meta,
      };

  static Map<String, dynamic> _safeMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.cast<String, dynamic>();
    if (v is String) {
      try {
        final decoded = jsonDecode(v);
        if (decoded is Map) return decoded.cast<String, dynamic>();
      } catch (_) {}
    }
    return <String, dynamic>{};
  }
}
