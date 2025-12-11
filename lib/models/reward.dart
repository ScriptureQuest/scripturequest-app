import 'package:flutter/foundation.dart';

/// Unified reward model usable by quests, achievements, streak milestones, etc.
class Reward {
  final String? id; // identifier for gear/titles/items
  final String type; // "xp" | "streak" | "item" | "gear" | "title" | "cosmetic" | "token"
  final int? amount; // XP amount or token count (null for non-numeric)
  final String rarity; // "common" | "rare" | "epic" | "legendary"
  final String label; // user-facing summary (e.g., "250 XP", "New Title: Disciple")
  final String? description; // optional flavor text
  final Map<String, dynamic>? meta; // extra payload for gear/cosmetics

  const Reward({
    this.id,
    required this.type,
    this.amount,
    this.rarity = 'common',
    required this.label,
    this.description,
    this.meta,
  });

  Reward copyWith({
    String? id,
    String? type,
    int? amount,
    String? rarity,
    String? label,
    String? description,
    Map<String, dynamic>? meta,
  }) => Reward(
        id: id ?? this.id,
        type: type ?? this.type,
        amount: amount ?? this.amount,
        rarity: rarity ?? this.rarity,
        label: label ?? this.label,
        description: description ?? this.description,
        meta: meta ?? this.meta,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'amount': amount,
        'rarity': rarity,
        'label': label,
        'description': description,
        'meta': meta,
      };

  static Reward fromJson(Map<String, dynamic> json) {
    try {
      return Reward(
        id: json['id']?.toString(),
        type: (json['type'] ?? '').toString(),
        amount: json['amount'] == null ? null : int.tryParse('${json['amount']}'),
        rarity: (json['rarity'] ?? 'common').toString(),
        label: (json['label'] ?? '').toString(),
        description: json['description']?.toString(),
        meta: json['meta'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(json['meta'] as Map)
            : null,
      );
    } catch (e) {
      debugPrint('Reward.fromJson error: $e');
      return Reward(type: (json['type'] ?? 'xp').toString(), amount: 0, label: (json['label'] ?? '').toString());
    }
  }
}

class RewardTypes {
  static const String xp = 'xp';
  static const String streak = 'streak';
  static const String item = 'item';
  static const String gear = 'gear';
  static const String title = 'title';
  static const String cosmetic = 'cosmetic';
  static const String token = 'token';
  // v2.0 quest rewards
  static const String artifactFragment = 'artifact_fragment';
  static const String streakBuff = 'streak_buff';
  static const String bookMasteryXp = 'book_mastery_xp';
}

class RewardRarities {
  static const String common = 'common';
  static const String rare = 'rare';
  static const String epic = 'epic';
  static const String legendary = 'legendary';
}
