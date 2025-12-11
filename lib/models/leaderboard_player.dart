import 'package:level_up_your_faith/models/user_model.dart';

class LeaderboardPlayer {
  final String id;
  final String displayName;
  final String? tagline;
  final int level;
  final int xp;
  final int currentStreak;
  final int longestStreak;
  final int booksCompleted;
  final int achievementsUnlocked;
  final bool isCurrentUser;

  const LeaderboardPlayer({
    required this.id,
    required this.displayName,
    this.tagline,
    required this.level,
    required this.xp,
    required this.currentStreak,
    required this.longestStreak,
    required this.booksCompleted,
    required this.achievementsUnlocked,
    required this.isCurrentUser,
  });

  LeaderboardPlayer copyWith({
    String? id,
    String? displayName,
    String? tagline,
    int? level,
    int? xp,
    int? currentStreak,
    int? longestStreak,
    int? booksCompleted,
    int? achievementsUnlocked,
    bool? isCurrentUser,
  }) => LeaderboardPlayer(
        id: id ?? this.id,
        displayName: displayName ?? this.displayName,
        tagline: tagline ?? this.tagline,
        level: level ?? this.level,
        xp: xp ?? this.xp,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        booksCompleted: booksCompleted ?? this.booksCompleted,
        achievementsUnlocked: achievementsUnlocked ?? this.achievementsUnlocked,
        isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      );

  // Helper to build from UserModel + provider-computed stats without creating circular deps
  factory LeaderboardPlayer.fromUserModel({
    required UserModel user,
    required int currentStreak,
    required int longestStreak,
    required int booksCompleted,
    required int achievementsUnlocked,
    bool isCurrentUser = false,
  }) {
    return LeaderboardPlayer(
      id: user.id.isNotEmpty ? user.id : 'local_me',
      displayName: (user.username.isNotEmpty ? user.username : 'You'),
      tagline: user.tagline,
      level: user.currentLevel,
      xp: user.currentXP,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      booksCompleted: booksCompleted,
      achievementsUnlocked: achievementsUnlocked,
      isCurrentUser: isCurrentUser,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'tagline': tagline,
        'level': level,
        'xp': xp,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'booksCompleted': booksCompleted,
        'achievementsUnlocked': achievementsUnlocked,
        'isCurrentUser': isCurrentUser,
      };

  factory LeaderboardPlayer.fromJson(Map<String, dynamic> json) => LeaderboardPlayer(
        id: (json['id'] ?? '').toString(),
        displayName: (json['displayName'] ?? '').toString(),
        tagline: (json['tagline'] as String?)?.trim().isEmpty == true ? null : json['tagline'] as String?,
        level: json['level'] is int ? json['level'] as int : int.tryParse('${json['level']}') ?? 1,
        xp: json['xp'] is int ? json['xp'] as int : int.tryParse('${json['xp']}') ?? 0,
        currentStreak: json['currentStreak'] is int ? json['currentStreak'] as int : int.tryParse('${json['currentStreak']}') ?? 0,
        longestStreak: json['longestStreak'] is int ? json['longestStreak'] as int : int.tryParse('${json['longestStreak']}') ?? 0,
        booksCompleted: json['booksCompleted'] is int ? json['booksCompleted'] as int : int.tryParse('${json['booksCompleted']}') ?? 0,
        achievementsUnlocked: json['achievementsUnlocked'] is int
            ? json['achievementsUnlocked'] as int
            : int.tryParse('${json['achievementsUnlocked']}') ?? 0,
        isCurrentUser: json['isCurrentUser'] == true,
      );
}
