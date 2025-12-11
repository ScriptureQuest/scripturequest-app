import 'package:level_up_your_faith/models/reward.dart';

/// Canonical categories for Achievements v1.0
enum AchievementCategory {
  reading,
  streak,
  mastery,
  collection,
  avatar,
  special,
  // Fallback for legacy categories in storage (e.g., Bible/Quests/XP/Journal)
  legacy,
}

class AchievementModel {
  final String id;
  // New canonical fields
  final String name; // preferred over legacy `title`
  final String description;
  final String iconKey; // preferred over legacy `iconName`
  // Legacy string category (kept for backward UI compatibility)
  final String category; // e.g., Quests, Bible, Journal, XP/Level or V1 labels
  // Canonical enum category for v1.0
  final AchievementCategory categoryEnum;
  final String rarity; // canonical: "common"|"rare"|"epic"|"legendary"
  
  // Legacy compatibility fields (kept in model for smooth migration)
  final String title; // alias to name
  final String iconName; // alias to iconKey
  final String tier; // alias to rarity in Title Case

  // Definition-side optional requirement/progress for legacy progress UI
  final int requirement; // e.g., 10 quests for "ten_quests"
  final int progress; // runtime progress (non-persistent or stored)

  // V1 scoring/progress fields
  final int points; // non-grindy scoring weight
  final int target; // preferred over requirement
  final String? source; // e.g., "reading", "streak", "mastery"

  // New fields
  final int xpReward; // Legacy XP shortcut when rewards not present
  final List<Reward> rewards; // Unified rewards
  final bool isSecret; // if true, hidden until unlocked

  // User-side runtime state
  final bool isUnlocked; // unlocked flag (alias: unlocked)
  final DateTime? unlockedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  AchievementModel({
    required this.id,
    required this.name,
    required this.description,
    this.iconKey = 'emoji_events',
    required this.category,
    this.categoryEnum = AchievementCategory.legacy,
    this.rarity = 'common',
    // Legacy mirrors (filled from canonical where not provided)
    String? title,
    String? iconName,
    String? tier,
    this.requirement = 0,
    this.progress = 0,
    this.points = 0,
    this.target = 0,
    this.source,
    this.xpReward = 0,
    this.rewards = const [],
    this.isSecret = false,
    this.isUnlocked = false,
    this.unlockedAt,
    required this.createdAt,
    required this.updatedAt,
  })  : title = title ?? name,
        iconName = iconName ?? iconKey,
        tier = tier ?? _rarityToTitleCase(rarity);

  // Convenience alias for API consistency with spec
  bool get unlocked => isUnlocked;
  double get progressPercent {
    final tgt = (target > 0) ? target : requirement;
    if (tgt <= 0) return 0;
    final pct = progress / tgt;
    if (pct.isNaN || pct.isInfinite) return 0;
    return pct.clamp(0, 1);
  }

  // Canonical getters for callers that may still use legacy fields
  String get displayName => name.isNotEmpty ? name : title;
  String get displayIconKey => iconKey.isNotEmpty ? iconKey : iconName;
  String get displayRarity {
    if (rarity.isNotEmpty) return rarity.toLowerCase();
    // fall back to tier
    return _titleCaseToRarity(tier);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        // Keep both names for compatibility
        'name': name,
        'title': title,
        'description': description,
        'iconKey': iconKey,
        'iconName': iconName,
        'category': category,
        'categoryEnum': categoryEnum.name,
        'rarity': displayRarity,
        'tier': tier,
        'requirement': requirement,
        'progress': progress,
        'points': points,
        'target': target,
        'source': source,
        'xpReward': xpReward,
        'rewards': rewards.map((r) => r.toJson()).toList(),
        'isSecret': isSecret,
        // keep both keys for backwards compatibility
        'isUnlocked': isUnlocked,
        'unlocked': isUnlocked,
        'unlockedAt': unlockedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AchievementModel.fromJson(Map<String, dynamic> json) => AchievementModel(
        id: json['id']?.toString() ?? '',
        name: (json['name']?.toString() ?? json['title']?.toString() ?? ''),
        description: json['description']?.toString() ?? '',
        iconKey: json['iconKey']?.toString() ?? json['iconName']?.toString() ?? 'emoji_events',
        category: json['category']?.toString() ?? 'general',
        categoryEnum: _parseCategory(json['categoryEnum']?.toString(), json['category']?.toString()),
        rarity: _normalizeRarity(json['rarity']?.toString(), json['tier']?.toString()),
        title: json['title']?.toString(),
        iconName: json['iconName']?.toString(),
        tier: json['tier']?.toString(),
        requirement: (json['requirement'] is int) ? json['requirement'] as int : int.tryParse('${json['requirement']}') ?? 0,
        progress: (json['progress'] is int) ? json['progress'] as int : int.tryParse('${json['progress']}') ?? 0,
        points: (json['points'] is int) ? json['points'] as int : int.tryParse('${json['points']}') ?? 0,
        target: (json['target'] is int) ? json['target'] as int : int.tryParse('${json['target']}') ?? 0,
        source: json['source']?.toString(),
        xpReward: (json['xpReward'] is int) ? json['xpReward'] as int : int.tryParse('${json['xpReward']}') ?? 0,
        rewards: (json['rewards'] is List)
            ? List<Map<String, dynamic>>.from(json['rewards'] as List)
                .map(Reward.fromJson)
                .toList()
            : const [],
        isSecret: json['isSecret'] == true,
        isUnlocked: (json['isUnlocked'] == true) || (json['unlocked'] == true),
        unlockedAt: json['unlockedAt'] != null && '${json['unlockedAt']}'.isNotEmpty
            ? DateTime.tryParse(json['unlockedAt'].toString())
            : null,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );

  AchievementModel copyWith({
    String? id,
    String? name,
    String? description,
    String? iconKey,
    String? category,
    AchievementCategory? categoryEnum,
    String? rarity,
    // Legacy mirrors for convenience
    String? title,
    String? iconName,
    String? tier,
    int? requirement,
    int? progress,
    int? points,
    int? target,
    String? source,
    int? xpReward,
    List<Reward>? rewards,
    bool? isSecret,
    bool? isUnlocked,
    DateTime? unlockedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      AchievementModel(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        iconKey: iconKey ?? this.iconKey,
        category: category ?? this.category,
        categoryEnum: categoryEnum ?? this.categoryEnum,
        rarity: rarity ?? this.rarity,
        // keep legacy mirrors derived if not explicitly provided
        title: title ?? (name != null ? name : this.title),
        iconName: iconName ?? (iconKey != null ? iconKey : this.iconName),
        tier: tier ?? (rarity != null ? _rarityToTitleCase(rarity) : this.tier),
        requirement: requirement ?? this.requirement,
        progress: progress ?? this.progress,
        points: points ?? this.points,
        target: target ?? this.target,
        source: source ?? this.source,
        xpReward: xpReward ?? this.xpReward,
        rewards: rewards ?? this.rewards,
        isSecret: isSecret ?? this.isSecret,
        isUnlocked: isUnlocked ?? this.isUnlocked,
        unlockedAt: unlockedAt ?? this.unlockedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  // Helpers
  static String _normalizeRarity(String? rarity, String? tier) {
    final r = (rarity ?? '').trim().toLowerCase();
    if (r == 'common' || r == 'rare' || r == 'epic' || r == 'legendary') return r;
    final t = (tier ?? '').trim().toLowerCase();
    switch (t) {
      case 'legendary':
        return 'legendary';
      case 'epic':
        return 'epic';
      case 'rare':
        return 'rare';
      case 'common':
      default:
        return 'common';
    }
  }

  static String _rarityToTitleCase(String rarity) {
    switch (rarity.trim().toLowerCase()) {
      case 'legendary':
        return 'Legendary';
      case 'epic':
        return 'Epic';
      case 'rare':
        return 'Rare';
      case 'common':
      default:
        return 'Common';
    }
  }

  static String _titleCaseToRarity(String titleCase) {
    switch (titleCase.trim()) {
      case 'Legendary':
        return 'legendary';
      case 'Epic':
        return 'epic';
      case 'Rare':
        return 'rare';
      case 'Common':
      default:
        return 'common';
    }
  }

  static AchievementCategory _parseCategory(String? enumText, String? legacyText) {
    final e = (enumText ?? '').trim().toLowerCase();
    switch (e) {
      case 'reading':
        return AchievementCategory.reading;
      case 'streak':
        return AchievementCategory.streak;
      case 'mastery':
        return AchievementCategory.mastery;
      case 'collection':
        return AchievementCategory.collection;
      case 'avatar':
        return AchievementCategory.avatar;
      case 'special':
        return AchievementCategory.special;
    }
    // Best-effort map from legacy category strings
    final l = (legacyText ?? '').trim().toLowerCase();
    if (l.contains('bible') || l.contains('reading') || l.contains('scripture')) return AchievementCategory.reading;
    if (l.contains('streak')) return AchievementCategory.streak;
    if (l.contains('xp') || l.contains('level') || l.contains('avatar')) return AchievementCategory.avatar;
    if (l.contains('journal')) return AchievementCategory.special;
    if (l.contains('quest')) return AchievementCategory.special;
    return AchievementCategory.legacy;
  }
}
