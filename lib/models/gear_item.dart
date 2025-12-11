import 'package:flutter/material.dart';
import 'spiritual_stats.dart';

enum GearSlot {
  head,
  chest,
  hands,
  legs,
  feet,
  hand, // staffs, scrolls, lanterns
  charm, // rings, pendants
  artifact, // legendary-only
}

enum GearRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

@immutable
class GearItem {
  final String id;
  final String name;
  final String? subtitle;
  final GearSlot slot;
  final GearRarity rarity;
  final String description;
  // Optional scripture metadata
  final String? reference; // e.g., "Exodus 3:1–10"
  final String? visualKey; // future icon/3D asset routing
  final SpiritualStats stats;
  final String? iconAsset;
  final bool isEquipped;
  // Respectful, game-only contribution to Faith Power
  final int blessingValue;

  const GearItem({
    required this.id,
    required this.name,
    required this.slot,
    required this.rarity,
    required this.description,
    this.reference,
    this.visualKey,
    required this.stats,
    this.subtitle,
    this.iconAsset,
    this.isEquipped = false,
    this.blessingValue = 0,
  });

  GearItem copyWith({
    String? id,
    String? name,
    String? subtitle,
    GearSlot? slot,
    GearRarity? rarity,
    String? description,
    String? reference,
    String? visualKey,
    SpiritualStats? stats,
    String? iconAsset,
    bool? isEquipped,
  int? blessingValue,
  }) {
    return GearItem(
      id: id ?? this.id,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      slot: slot ?? this.slot,
      rarity: rarity ?? this.rarity,
      description: description ?? this.description,
      reference: reference ?? this.reference,
      visualKey: visualKey ?? this.visualKey,
      stats: stats ?? this.stats,
      iconAsset: iconAsset ?? this.iconAsset,
      isEquipped: isEquipped ?? this.isEquipped,
    blessingValue: blessingValue ?? this.blessingValue,
    );
  }

  factory GearItem.fromJson(Map<String, dynamic> json) {
    final statsJson = (json['stats'] as Map?)?.cast<String, dynamic>();
    return GearItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      subtitle: json['subtitle'] as String?,
      slot: GearSlot.values.firstWhere(
        (e) => e.name == (json['slot'] ?? '').toString(),
        orElse: () => GearSlot.head,
      ),
      rarity: GearRarity.values.firstWhere(
        (e) => e.name == (json['rarity'] ?? '').toString(),
        orElse: () => GearRarity.common,
      ),
      description: (json['description'] ?? '').toString(),
      reference: json['reference'] as String?,
      visualKey: json['visualKey'] as String?,
      stats: SpiritualStats(
        wisdom: int.tryParse('${statsJson?['wisdom'] ?? 0}') ?? 0,
        discipline: int.tryParse('${statsJson?['discipline'] ?? 0}') ?? 0,
        compassion: int.tryParse('${statsJson?['compassion'] ?? 0}') ?? 0,
        witness: int.tryParse('${statsJson?['witness'] ?? 0}') ?? 0,
      ),
      iconAsset: json['iconAsset'] as String?,
      isEquipped: (json['isEquipped'] ?? false) == true,
      blessingValue: int.tryParse('${json['blessingValue'] ?? 0}') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subtitle': subtitle,
        'slot': slot.name,
        'rarity': rarity.name,
        'description': description,
        'reference': reference,
        'visualKey': visualKey,
        'stats': {
          'wisdom': stats.wisdom,
          'discipline': stats.discipline,
          'compassion': stats.compassion,
          'witness': stats.witness,
        },
        'iconAsset': iconAsset,
        'isEquipped': isEquipped,
        'blessingValue': blessingValue,
      };
}

Color gearRarityColor(GearRarity rarity, ThemeData theme) {
  switch (rarity) {
    case GearRarity.common:
      return theme.colorScheme.outline.withValues(alpha: 0.7);
    case GearRarity.uncommon:
      return Colors.greenAccent.shade400;
    case GearRarity.rare:
      return Colors.blueAccent.shade400;
    case GearRarity.epic:
      return Colors.purpleAccent.shade400;
    case GearRarity.legendary:
      return Colors.amberAccent.shade400;
  }
}
