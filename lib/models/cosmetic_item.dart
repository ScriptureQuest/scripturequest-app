import 'package:flutter/foundation.dart';

/// Cosmetic items are purely visual and optional. Monetization is disabled in v1.0.
class CosmeticItem {
  final String id;
  final String name;
  final String description;
  final CosmeticType type; // theme | avatar_glow | frame | artifact_skin
  final CosmeticRarity rarity; // common | rare | epic | legendary
  final String? iconAsset;
  final String? previewAsset;
  final double? priceUSD; // nullable, unused while purchases are disabled
  final bool owned; // false by default

  const CosmeticItem({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    this.iconAsset,
    this.previewAsset,
    this.priceUSD,
    this.owned = false,
  });

  CosmeticItem copyWith({
    String? id,
    String? name,
    String? description,
    CosmeticType? type,
    CosmeticRarity? rarity,
    String? iconAsset,
    String? previewAsset,
    double? priceUSD,
    bool? owned,
  }) {
    return CosmeticItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      iconAsset: iconAsset ?? this.iconAsset,
      previewAsset: previewAsset ?? this.previewAsset,
      priceUSD: priceUSD ?? this.priceUSD,
      owned: owned ?? this.owned,
    );
  }
}

enum CosmeticType { theme, avatar_glow, frame, artifact_skin }

enum CosmeticRarity { common, rare, epic, legendary }

extension CosmeticRarityX on CosmeticRarity {
  String get label => describeEnum(this);
}
