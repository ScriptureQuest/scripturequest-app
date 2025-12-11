class UserModel {
  final String id;
  final String username;
  final String email;
  final String avatarUrl;
  final int currentLevel;
  final int currentXP;
  final int totalXP;
  final int streakDays;
  final int longestStreak;
  // Unified Reward System extensions
  final int currency; // soft tokens/currency
  final int streakTokens; // consumables to protect streak, etc.
  final String? lastRewardSummary; // last reward label for UI
  final List<String> achievements;
  final List<String> completedVerses;
  final List<String> completedQuests;
  final String preferredBibleVersionCode;
  // Public profile fields
  final bool isProfilePublic; // default true
  final String? tagline; // short bio
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl = '',
    this.currentLevel = 1,
    this.currentXP = 0,
    this.totalXP = 0,
    this.streakDays = 0,
    this.longestStreak = 0,
    this.currency = 0,
    this.streakTokens = 0,
    this.lastRewardSummary,
    this.achievements = const [],
    this.completedVerses = const [],
    this.completedQuests = const [],
    this.preferredBibleVersionCode = 'KJV',
    this.isProfilePublic = true,
    this.tagline,
    required this.createdAt,
    required this.updatedAt,
  });

  int get xpToNextLevel => currentLevel * 100;
  double get xpProgress => currentXP / xpToNextLevel;

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'avatarUrl': avatarUrl,
    'currentLevel': currentLevel,
    'currentXP': currentXP,
    'totalXP': totalXP,
    'streakDays': streakDays,
    'longestStreak': longestStreak,
    'currency': currency,
    'streakTokens': streakTokens,
    'lastRewardSummary': lastRewardSummary,
    'achievements': achievements,
    'completedVerses': completedVerses,
    'completedQuests': completedQuests,
    'preferredBibleVersionCode': preferredBibleVersionCode,
    'isProfilePublic': isProfilePublic,
    'tagline': tagline,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] ?? '',
    username: json['username'] ?? '',
    email: json['email'] ?? '',
    avatarUrl: json['avatarUrl'] ?? '',
    currentLevel: json['currentLevel'] ?? 1,
    currentXP: json['currentXP'] ?? 0,
    totalXP: json['totalXP'] ?? 0,
    streakDays: json['streakDays'] ?? 0,
    longestStreak: json['longestStreak'] ?? 0,
    currency: json['currency'] ?? 0,
    streakTokens: json['streakTokens'] ?? 0,
    lastRewardSummary: (json['lastRewardSummary']?.toString().trim().isEmpty ?? true)
        ? null
        : json['lastRewardSummary'].toString(),
    achievements: List<String>.from(json['achievements'] ?? []),
    completedVerses: List<String>.from(json['completedVerses'] ?? []),
    completedQuests: List<String>.from(json['completedQuests'] ?? []),
    preferredBibleVersionCode: (json['preferredBibleVersionCode'] ?? 'KJV').toString(),
    isProfilePublic: (json['isProfilePublic'] is bool)
        ? json['isProfilePublic'] as bool
        : (json['isProfilePublic'] == null ? true : (json['isProfilePublic'].toString() != 'false')),
    tagline: json['tagline'] == null || (json['tagline'] as String?)?.trim().isEmpty == true
        ? null
        : json['tagline'] as String?,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
  );

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? avatarUrl,
    int? currentLevel,
    int? currentXP,
    int? totalXP,
    int? streakDays,
    int? longestStreak,
    int? currency,
    int? streakTokens,
    String? lastRewardSummary,
    List<String>? achievements,
    List<String>? completedVerses,
    List<String>? completedQuests,
    String? preferredBibleVersionCode,
    bool? isProfilePublic,
    String? tagline,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserModel(
    id: id ?? this.id,
    username: username ?? this.username,
    email: email ?? this.email,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    currentLevel: currentLevel ?? this.currentLevel,
    currentXP: currentXP ?? this.currentXP,
    totalXP: totalXP ?? this.totalXP,
    streakDays: streakDays ?? this.streakDays,
    longestStreak: longestStreak ?? this.longestStreak,
    currency: currency ?? this.currency,
    streakTokens: streakTokens ?? this.streakTokens,
    lastRewardSummary: lastRewardSummary ?? this.lastRewardSummary,
    achievements: achievements ?? this.achievements,
    completedVerses: completedVerses ?? this.completedVerses,
    completedQuests: completedQuests ?? this.completedQuests,
    preferredBibleVersionCode: preferredBibleVersionCode ?? this.preferredBibleVersionCode,
    isProfilePublic: isProfilePublic ?? this.isProfilePublic,
    tagline: tagline ?? this.tagline,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
