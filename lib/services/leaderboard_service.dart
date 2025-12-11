import 'package:level_up_your_faith/models/leaderboard_player.dart';

class LeaderboardService {
  List<LeaderboardPlayer> getSamplePlayers() {
    // Local-only bot roster. Stats are intentionally varied for a lively board.
    return const [
      LeaderboardPlayer(
        id: 'bot_1',
        displayName: 'ScriptureSniper',
        tagline: 'Headshots on doubt 🎯',
        level: 18,
        xp: 1450,
        currentStreak: 9,
        longestStreak: 21,
        booksCompleted: 7,
        achievementsUnlocked: 26,
        isCurrentUser: false,
      ),
      LeaderboardPlayer(
        id: 'bot_2',
        displayName: 'HolyCrit',
        tagline: 'Massive crits of grace',
        level: 22,
        xp: 2100,
        currentStreak: 3,
        longestStreak: 18,
        booksCompleted: 12,
        achievementsUnlocked: 34,
        isCurrentUser: false,
      ),
      LeaderboardPlayer(
        id: 'bot_3',
        displayName: 'ArmorUp',
        tagline: 'Ephesians 6 main 🛡️',
        level: 12,
        xp: 860,
        currentStreak: 12,
        longestStreak: 30,
        booksCompleted: 4,
        achievementsUnlocked: 18,
        isCurrentUser: false,
      ),
      LeaderboardPlayer(
        id: 'bot_4',
        displayName: 'PsalmRunner',
        tagline: 'Sprinting through Psalms',
        level: 9,
        xp: 520,
        currentStreak: 2,
        longestStreak: 7,
        booksCompleted: 2,
        achievementsUnlocked: 11,
        isCurrentUser: false,
      ),
      LeaderboardPlayer(
        id: 'bot_5',
        displayName: 'FaithRunner17',
        tagline: 'Speedrunning grace ☄️',
        level: 25,
        xp: 3200,
        currentStreak: 5,
        longestStreak: 40,
        booksCompleted: 20,
        achievementsUnlocked: 48,
        isCurrentUser: false,
      ),
      LeaderboardPlayer(
        id: 'bot_6',
        displayName: 'ArmorSmith',
        tagline: 'Forging virtue daily',
        level: 6,
        xp: 260,
        currentStreak: 1,
        longestStreak: 6,
        booksCompleted: 1,
        achievementsUnlocked: 6,
        isCurrentUser: false,
      ),
      LeaderboardPlayer(
        id: 'bot_7',
        displayName: 'GraceGlider',
        tagline: 'Floating on mercy 💫',
        level: 14,
        xp: 1010,
        currentStreak: 8,
        longestStreak: 14,
        booksCompleted: 6,
        achievementsUnlocked: 22,
        isCurrentUser: false,
      ),
      LeaderboardPlayer(
        id: 'bot_8',
        displayName: 'VerseVanguard',
        tagline: 'Frontline reader',
        level: 3,
        xp: 110,
        currentStreak: 0,
        longestStreak: 2,
        booksCompleted: 0,
        achievementsUnlocked: 2,
        isCurrentUser: false,
      ),
      LeaderboardPlayer(
        id: 'bot_9',
        displayName: 'ArmorCore66',
        tagline: 'One day… all books',
        level: 19,
        xp: 1560,
        currentStreak: 4,
        longestStreak: 22,
        booksCompleted: 13,
        achievementsUnlocked: 29,
        isCurrentUser: false,
      ),
      LeaderboardPlayer(
        id: 'bot_10',
        displayName: 'ScriptureSpark',
        tagline: 'Lighting the way',
        level: 7,
        xp: 330,
        currentStreak: 0,
        longestStreak: 5,
        booksCompleted: 1,
        achievementsUnlocked: 8,
        isCurrentUser: false,
      ),
    ];
  }

  /// Find a player by id among the current user and the local-only bot roster.
  /// Returns null if not found.
  LeaderboardPlayer? findPlayerById({
    required String id,
    required LeaderboardPlayer currentUserPlayer,
  }) {
    if (id == currentUserPlayer.id) return currentUserPlayer;
    final bots = getSamplePlayers();
    try {
      return bots.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<LeaderboardPlayer> _mergeMe(List<LeaderboardPlayer> bots, LeaderboardPlayer me) {
    // Ensure only one entry for 'me' id by replacing if present
    final list = [...bots];
    final existingIdx = list.indexWhere((p) => p.id == me.id);
    if (existingIdx >= 0) {
      list[existingIdx] = me;
    } else {
      list.add(me);
    }
    return list;
  }

  List<LeaderboardPlayer> buildXpLeaderboard(LeaderboardPlayer me) {
    final players = _mergeMe(getSamplePlayers(), me);
    players.sort((a, b) {
      if (b.xp != a.xp) return b.xp.compareTo(a.xp);
      return b.level.compareTo(a.level);
    });
    return players;
  }

  List<LeaderboardPlayer> buildStreakLeaderboard(LeaderboardPlayer me) {
    final players = _mergeMe(getSamplePlayers(), me);
    players.sort((a, b) {
      if (b.currentStreak != a.currentStreak) {
        return b.currentStreak.compareTo(a.currentStreak);
      }
      return b.longestStreak.compareTo(a.longestStreak);
    });
    return players;
  }

  List<LeaderboardPlayer> buildBibleCompletionLeaderboard(LeaderboardPlayer me) {
    final players = _mergeMe(getSamplePlayers(), me);
    players.sort((a, b) {
      if (b.booksCompleted != a.booksCompleted) {
        return b.booksCompleted.compareTo(a.booksCompleted);
      }
      return b.xp.compareTo(a.xp);
    });
    return players;
  }
}
