import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/widgets/xp_bar.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/widgets/home_action_button.dart';
import 'package:level_up_your_faith/services/faith_power_service.dart';

class PublicProfileScreen extends StatelessWidget {
  final String? userId; // null or current user's id => show current user

  const PublicProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, provider, _) {
      final me = provider.currentUser;
      if (me == null) {
        return const Scaffold(body: Center(child: Text('Loading player...')));
      }

      final isSelf = userId == null || userId == me.id;

      // Other player (bot/friend) public view powered by local LeaderboardPlayer
      if (!isSelf) {
        final player = provider.getLeaderboardPlayerById(userId!);
        return Scaffold(
          appBar: AppBar(
            leading: Navigator.of(context).canPop()
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: GamerColors.accent),
                    onPressed: () => context.pop(),
                  )
                : null,
            title: Text('Player Profile', style: Theme.of(context).textTheme.headlineSmall),
            centerTitle: true,
            actions: const [HomeActionButton()],
          ),
          body: player == null
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: GamerColors.darkCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GamerColors.accent.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline, color: GamerColors.textSecondary, size: 36),
                        const SizedBox(height: 12),
                        Text(
                          "This player's public profile is not available yet.",
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: GamerColors.darkCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: GamerColors.accent.withValues(alpha: 0.3), width: 1),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: GamerColors.darkSurface,
                                borderRadius: BorderRadius.circular(44),
                                border: Border.all(color: GamerColors.accent, width: 2),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _initials(player.displayName),
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: GamerColors.accent, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(player.displayName, style: Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _LevelPill(level: player.level),
                                const SizedBox(width: 8),
                                _AppPill(),
                              ],
                            ),
                            if ((player.tagline ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                player.tagline!.trim(),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: GamerColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // XP / Level (compact)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: GamerColors.darkCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: GamerColors.accent.withValues(alpha: 0.3), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.shield, color: GamerColors.accent, size: 20),
                                    const SizedBox(width: 8),
                                    Text('Level ${player.level}', style: Theme.of(context).textTheme.titleMedium),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.bolt, color: GamerColors.neonCyan, size: 20),
                                    const SizedBox(width: 8),
                                    Text('XP: ${player.xp}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: GamerColors.neonCyan)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Builder(builder: (context) {
                              final fp = const FaithPowerService().calculateFaithPower(
                                soulLevel: player.level,
                                booksMasteredCount: player.booksCompleted,
                                equippedArtifacts: const [],
                              );
                              return Row(
                                children: [
                                  const Icon(Icons.auto_awesome, color: GamerColors.neonPurple, size: 18),
                                  const SizedBox(width: 8),
                                  Text('Faith Power: ~$fp', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: GamerColors.neonPurple)),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Faith Stats
                      _StatsGrid(stats: [
                        {
                          'icon': Icons.local_fire_department,
                          'label': 'Current Streak',
                          'value': '${player.currentStreak}',
                          'color': GamerColors.danger,
                        },
                        {
                          'icon': Icons.timeline,
                          'label': 'Longest Streak',
                          'value': '${player.longestStreak}',
                          'color': GamerColors.accent,
                        },
                        {
                          'icon': Icons.menu_book,
                          'label': 'Bible Completion',
                          'value': '${player.booksCompleted} / 66',
                          'color': GamerColors.neonCyan,
                        },
                        {
                          'icon': Icons.emoji_events,
                          'label': 'Achievements',
                          'value': '${player.achievementsUnlocked}',
                          'color': GamerColors.success,
                        },
                      ]),
                      const SizedBox(height: 24),
                      // Bible Progress Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: GamerColors.darkCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: GamerColors.accent.withValues(alpha: 0.3), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_stories, color: GamerColors.accent),
                                const SizedBox(width: 8),
                                Text('Bible Progress', style: Theme.of(context).textTheme.titleMedium),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text('${player.booksCompleted} of 66 books completed', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 4),
                            Text('Progress is local to this device.', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: GamerColors.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Achievements placeholder
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: GamerColors.darkCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: GamerColors.neonPurple.withValues(alpha: 0.25), width: 1),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, color: GamerColors.neonPurple),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Achievements data for this player is not available yet.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      }

      // Current user public-facing preview
      final user = me;
      final unlocked = [...provider.unlockedAchievements]
        ..sort((a, b) => (b.unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0)));

      return Scaffold(
        appBar: AppBar(
          leading: Navigator.of(context).canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: GamerColors.accent),
                  onPressed: () => context.pop(),
                )
              : null,
          title: Text('Player Profile', style: Theme.of(context).textTheme.headlineSmall),
          centerTitle: true,
          actions: const [HomeActionButton()],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Gamer Card Header
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Scripture Gamer Card', style: Theme.of(context).textTheme.headlineSmall),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: GamerColors.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GamerColors.accent.withValues(alpha: 0.3), width: 1),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: GamerColors.darkSurface,
                        borderRadius: BorderRadius.circular(44),
                        border: Border.all(color: GamerColors.accent, width: 2),
                      ),
                      child: const Icon(Icons.person, color: GamerColors.accent, size: 44),
                    ),
                    const SizedBox(height: 12),
                    Text(user.username, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 6),
                    // Faith title
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(colors: [
                          GamerColors.neonCyan.withValues(alpha: 0.9),
                          GamerColors.neonPurple.withValues(alpha: 0.9),
                        ]),
                        boxShadow: [
                          BoxShadow(color: GamerColors.accent.withValues(alpha: 0.35), blurRadius: 16, spreadRadius: 1),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars, color: GamerColors.darkBackground, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            provider.faithTitle,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: GamerColors.darkBackground, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    if ((provider.profileTagline ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        provider.profileTagline!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: GamerColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LevelPill(level: user.currentLevel),
                        const SizedBox(width: 8),
                        _AppPill(),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // XP / Level
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: GamerColors.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GamerColors.accent.withValues(alpha: 0.3), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    XPBar(currentXP: user.currentXP, maxXP: user.xpToNextLevel, level: user.currentLevel),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: GamerColors.neonPurple, size: 18),
                        const SizedBox(width: 8),
                        Text('Faith Power: ${provider.faithPower}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: GamerColors.neonPurple)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'XP and level shown are approximate in public view',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: GamerColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Faith Stats
              _StatsGrid(stats: [
                {
                  'icon': Icons.flag,
                  'label': 'Quests Completed',
                  'value': provider.totalQuestsCompleted.toString(),
                  'color': GamerColors.neonPurple,
                },
                {
                  'icon': Icons.menu_book,
                  'label': 'Scriptures Opened',
                  'value': provider.totalScripturesOpened.toString(),
                  'color': GamerColors.neonCyan,
                },
                {
                  'icon': Icons.edit_note,
                  'label': 'Journal Entries',
                  'value': provider.totalJournalEntries.toString(),
                  'color': GamerColors.accent,
                },
                {
                  'icon': Icons.emoji_events,
                  'label': 'Achievements Unlocked',
                  'value': provider.totalAchievementsUnlocked.toString(),
                  'color': GamerColors.success,
                },
              ]),
              const SizedBox(height: 24),
              // Bible Progress
              _BibleCompletionCard(
                completed: provider.totalBooksCompleted,
                total: 66,
                recent: provider.mostRecentCompletedBook,
              ),
              const SizedBox(height: 12),
              // Faith Streak
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: GamerColors.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GamerColors.accent.withValues(alpha: 0.3), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department, color: GamerColors.danger),
                        const SizedBox(width: 8),
                        Text('Faith Streak', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _StreakMetric(
                          label: 'Current Streak',
                          value: '${provider.currentBibleStreak} day${provider.currentBibleStreak == 1 ? '' : 's'}',
                          color: GamerColors.danger,
                        ),
                        const SizedBox(width: 16),
                        _StreakMetric(
                          label: 'Longest Streak',
                          value: '${provider.longestBibleStreak} day${provider.longestBibleStreak == 1 ? '' : 's'}',
                          color: GamerColors.accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (provider.hasStreakXpBonus)
                      Row(
                        children: [
                          const Icon(Icons.bolt, color: GamerColors.success),
                          const SizedBox(width: 8),
                          Text(
                            'Streak XP Bonus Active (+10%)',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: GamerColors.success),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (unlocked.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Recent Achievements', style: Theme.of(context).textTheme.headlineSmall),
                ),
                const SizedBox(height: 12),
                ...unlocked.take(3).map((a) => InkWell(
                      onTap: () => context.push('/achievements'),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: GamerColors.darkCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: GamerColors.success.withValues(alpha: 0.3), width: 1),
                          boxShadow: [
                            BoxShadow(color: GamerColors.success.withValues(alpha: 0.15), blurRadius: 18, spreadRadius: 1),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.emoji_events, color: GamerColors.success, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.title, style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${a.category} • ${a.tier} • ${_formatDate(a.unlockedAt)} • +${a.xpReward} XP',
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: GamerColors.textSecondary),
                          ],
                        ),
                      ),
                    )),
              ],
            ],
          ),
        ),
      );
    });
  }
}

class _LevelPill extends StatelessWidget {
  final int level;
  const _LevelPill({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GamerColors.accent.withValues(alpha: 0.5), width: 1),
        color: GamerColors.darkSurface,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield, size: 14, color: GamerColors.accent),
          const SizedBox(width: 6),
          Text('Level $level', style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _AppPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GamerColors.neonCyan.withValues(alpha: 0.5), width: 1),
        color: GamerColors.darkSurface,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videogame_asset, size: 14, color: GamerColors.neonCyan),
          const SizedBox(width: 6),
          Text('Scripture Quest™', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: GamerColors.neonCyan)),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final List<Map<String, dynamic>> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: GamerColors.darkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (stat['color'] as Color).withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(stat['icon'] as IconData, color: stat['color'] as Color, size: 28),
              const SizedBox(height: 8),
              Text(stat['value'] as String, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: stat['color'] as Color)),
              const SizedBox(height: 4),
              Text(
                stat['label'] as String,
                style: Theme.of(context).textTheme.labelSmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BibleCompletionCard extends StatelessWidget {
  final int completed;
  final int total;
  final String? recent;
  const _BibleCompletionCard({required this.completed, required this.total, this.recent});

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GamerColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GamerColors.accent.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories, color: GamerColors.accent),
              const SizedBox(width: 8),
              Text('Bible Completion: $completed/$total books', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(height: 10, color: GamerColors.darkSurface),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: 10,
                  width: MediaQuery.of(context).size.width * ratio,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      GamerColors.neonCyan.withValues(alpha: 0.9),
                      GamerColors.neonPurple.withValues(alpha: 0.9),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          if ((recent ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.check_circle, color: GamerColors.success, size: 18),
                const SizedBox(width: 6),
                Text('Most recent: $recent', style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StreakMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StreakMetric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: GamerColors.darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: GamerColors.textSecondary)),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime? dt) {
  if (dt == null) return '';
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _initials(String name) {
  try {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    String firstChar(String s) => s.isNotEmpty ? s.substring(0, 1).toUpperCase() : '';
    if (parts.length == 1) return firstChar(parts.first);
    final first = firstChar(parts.first);
    final last = firstChar(parts.last);
    return '$first$last';
  } catch (_) {
    return name.isNotEmpty ? name[0].toUpperCase() : '';
  }
}
