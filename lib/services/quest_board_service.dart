import 'package:uuid/uuid.dart';
import 'package:level_up_your_faith/models/quest.dart' as board;
import 'package:level_up_your_faith/models/reward.dart';

class QuestBoardService {
  final _uuid = const Uuid();

  /// Full set of quests for the board
  List<board.Quest> createInitialQuests(DateTime now) {
    return [
      _buildDailyBibleQuest(now),
      _buildWeeklyChallenge(now),
      _buildReflectionQuest(now),
    ];
  }

  /// Determines if quests need refreshing due to:
  /// - new day (daily)
  /// - new week (weekly)
  /// - expiration
  bool shouldRefreshQuests(DateTime now, List<board.Quest> existing) {
    if (existing.isEmpty) return true;

    final today = DateTime(now.year, now.month, now.day);

    // Daily quest refresh
    for (final q in existing.where((q) => q.type == 'daily')) {
      final d = q.createdAt;
      final dDay = DateTime(d.year, d.month, d.day);
      if (dDay != today) return true;
    }

    // Weekly quest refresh
    for (final q in existing.where((q) => q.type == 'weekly')) {
      if (_weekOfYear(q.createdAt) != _weekOfYear(now)) return true;
    }

    // Any expiration
    if (existing.any((q) => q.isExpired)) return true;

    return false;
  }

  // DAILY QUEST
  board.Quest _buildDailyBibleQuest(DateTime now) {
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return board.Quest(
      id: 'daily_${_uuid.v4()}',
      title: 'Daily Scripture Step',
      description: 'Read 1 chapter today. A gentle step forward. 🙏',
      type: 'daily',
      progress: 0,
      goal: 1,
      xpReward: 35,
      rewards: const [
        Reward(type: RewardTypes.xp, amount: 35, label: '35 XP', rarity: RewardRarities.common),
      ],
      createdAt: now,
      expiresAt: endOfDay,
    );
  }

  // WEEKLY QUEST
  board.Quest _buildWeeklyChallenge(DateTime now) {
    final endOfWeek = _endOfWeek(now);
    return board.Quest(
      id: 'weekly_${_uuid.v4()}',
      title: 'Weekly Warrior',
      description: 'Read 5 chapters this week. Steady and kind. ⚔️',
      type: 'weekly',
      progress: 0,
      goal: 5,
      xpReward: 120,
      rewards: const [
        Reward(type: RewardTypes.xp, amount: 120, label: '120 XP', rarity: RewardRarities.common),
      ],
      createdAt: now,
      expiresAt: endOfWeek,
    );
  }

  // REFLECTION QUEST
  board.Quest _buildReflectionQuest(DateTime now) {
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return board.Quest(
      id: 'reflection_${_uuid.v4()}',
      title: 'Reflection Check-in',
      description: 'Write 1 short reflection after reading today. ✍️',
      type: 'reflection',
      progress: 0,
      goal: 1,
      xpReward: 40,
      rewards: const [
        Reward(type: RewardTypes.xp, amount: 40, label: '40 XP', rarity: RewardRarities.common),
      ],
      createdAt: now,
      expiresAt: endOfDay,
    );
  }

  // Week helpers
  DateTime _endOfWeek(DateTime dt) {
    // Dart weekday: 1=Mon ... 7=Sun
    final daysToSunday = 7 - dt.weekday;
    final sunday =
        DateTime(dt.year, dt.month, dt.day).add(Duration(days: daysToSunday));
    return DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
  }

  int _weekOfYear(DateTime dt) {
    // Simple week-of-year approximation sufficient for local weekly rotation
    final first = DateTime(dt.year, 1, 1);
    final diff = dt.difference(first);
    return ((diff.inDays + first.weekday) / 7).floor();
  }
}
