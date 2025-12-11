import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/models/leaderboard_player.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/widgets/home_action_button.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  List<LeaderboardPlayer> _xp = const [];
  List<LeaderboardPlayer> _streak = const [];
  List<LeaderboardPlayer> _bible = const [];
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      final me = provider.currentLeaderboardPlayer;
      final svc = provider.leaderboardService;
      setState(() {
        _xp = svc.buildXpLeaderboard(me);
        _streak = svc.buildStreakLeaderboard(me);
        _bible = svc.buildBibleCompletionLeaderboard(me);
        _ready = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: Navigator.of(context).canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: GamerColors.accent),
                  onPressed: () => context.pop(),
                )
              : null,
          title: Text('Leaderboards', style: Theme.of(context).textTheme.headlineSmall),
          centerTitle: true,
          actions: const [HomeActionButton()],
          bottom: TabBar(
            indicatorColor: GamerColors.accent,
            labelColor: GamerColors.accent,
            unselectedLabelColor: GamerColors.textSecondary,
            tabs: const [
              Tab(icon: Icon(Icons.stars), text: 'XP'),
              Tab(icon: Icon(Icons.local_fire_department), text: 'Streak'),
              Tab(icon: Icon(Icons.auto_stories), text: 'Bible'),
            ],
          ),
        ),
        body: !_ready
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _LeaderboardList(players: _xp, mode: _LeaderboardMode.xp),
                  _LeaderboardList(players: _streak, mode: _LeaderboardMode.streak),
                  _LeaderboardList(players: _bible, mode: _LeaderboardMode.bible),
                ],
              ),
      ),
    );
  }
}

enum _LeaderboardMode { xp, streak, bible }

class _LeaderboardList extends StatelessWidget {
  final List<LeaderboardPlayer> players;
  final _LeaderboardMode mode;

  const _LeaderboardList({required this.players, required this.mode});

  String _subline(LeaderboardPlayer p) {
    switch (mode) {
      case _LeaderboardMode.xp:
        return 'Level ${p.level} • XP: ${p.xp}';
      case _LeaderboardMode.streak:
        return 'Current streak: ${p.currentStreak} days • Longest: ${p.longestStreak} days';
      case _LeaderboardMode.bible:
        return 'Books completed: ${p.booksCompleted} • Level ${p.level}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: players.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = players[index];
        final rank = index + 1;
        final isFirst = rank == 1;
        final isFriend = provider.isFriend(p.id);
        final borderColor = p.isCurrentUser
            ? GamerColors.neonCyan
            : (isFirst ? GamerColors.success : GamerColors.accent.withValues(alpha: 0.25));
        return InkWell(
          onTap: () {
            if (p.isCurrentUser) {
              context.push('/player/me');
            } else {
              context.push('/player/${p.id}');
            }
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: GamerColors.darkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor.withValues(alpha: p.isCurrentUser ? 0.9 : 0.4), width: p.isCurrentUser ? 2 : 1),
              boxShadow: [
                if (p.isCurrentUser)
                  BoxShadow(color: GamerColors.neonCyan.withValues(alpha: 0.2), blurRadius: 18, spreadRadius: 1),
                if (isFirst)
                  BoxShadow(color: GamerColors.success.withValues(alpha: 0.15), blurRadius: 14, spreadRadius: 1),
              ],
            ),
            child: Row(
              children: [
                // Rank
                SizedBox(
                  width: 40,
                  child: Row(
                    children: [
                      if (isFirst) const Icon(Icons.emoji_events, color: GamerColors.success, size: 18),
                      if (isFirst) const SizedBox(width: 4),
                      Text('#$rank', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Middle info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              p.displayName,
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (p.isCurrentUser)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: GamerColors.neonCyan, width: 1),
                              ),
                              child: const Text('You'),
                            ),
                          if (!p.isCurrentUser && isFriend) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: GamerColors.success, width: 1),
                              ),
                              child: const Text('Friend'),
                            ),
                          ],
                        ],
                      ),
                      if ((p.tagline ?? '').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(p.tagline!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: GamerColors.textSecondary)),
                      ],
                      const SizedBox(height: 6),
                      Text(_subline(p), style: Theme.of(context).textTheme.labelMedium),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right action(s)
                if (!p.isCurrentUser)
                  IconButton(
                    tooltip: isFriend ? 'Remove friend' : 'Add friend',
                    icon: Icon(
                      isFriend ? Icons.person_remove_alt_1_outlined : Icons.person_add_alt_1_outlined,
                      color: isFriend ? GamerColors.success : GamerColors.accent,
                    ),
                    onPressed: () async {
                      if (!provider.isFriend(p.id)) {
                        await provider.addFriendFromPlayer(p);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to Friends')),
                        );
                      } else {
                        await provider.removeFriend(p.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Removed from Friends')),
                        );
                      }
                    },
                  )
                else
                  const Icon(Icons.chevron_right, color: GamerColors.textSecondary),
              ],
            ),
          ),
        );
      },
    );
  }
}
