import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/widgets/soul_avatar.dart';
import 'package:level_up_your_faith/widgets/home_action_button.dart';
import 'package:level_up_your_faith/data/title_seeds.dart';
import 'package:level_up_your_faith/widgets/sacred/sacred_ui.dart';
import 'package:level_up_your_faith/models/achievement_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, provider, _) {
      final user = provider.currentUser;
      if (user == null) return const Scaffold(body: Center(child: Text('Error loading user')));

      // Scripture stats
      final totalChaptersRead = provider.totalChaptersRead;
      final totalChapters = AppProvider.bookTotalChapters.values.fold<int>(0, (s, v) => s + v);
      final overallPct = totalChapters > 0 ? (totalChaptersRead / totalChapters).clamp(0.0, 1.0) : 0.0;
      final booksCompleted = provider.totalBooksCompleted;
      final booksInProgress = AppProvider.bookTotalChapters.keys.where((book) {
        final read = provider.chaptersReadForBook(book);
        return read > 0 && !provider.isBookCompleted(book);
      }).length;

      // Equipped title (if any)
      final titleId = provider.equippedTitleId;
      final invItem = (titleId != null) ? provider.playerInventory.items[titleId] : null;
      String? equippedTitleName = invItem?.name?.trim().isNotEmpty == true ? invItem!.name : null;
      final equippedTitleRarity = invItem?.rarity;
      if ((equippedTitleName == null || equippedTitleName.trim().isEmpty) && titleId != null && titleId.isNotEmpty) {
        try {
          final t = TitleSeedsV1.list().firstWhere((e) => e.id == titleId);
          equippedTitleName = t.name;
        } catch (_) {}
      }

      final cs = Theme.of(context).colorScheme;
      return Scaffold(
        appBar: AppBar(
          title: Text('Profile', style: Theme.of(context).textTheme.titleLarge),
          centerTitle: true,
          actions: const [HomeActionButton()],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          children: [
            // Header — avatar + equipped title badge (compact)
            SacredCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TopIdentity(
                    username: user.username,
                    level: user.currentLevel,
                    faithTitle: provider.faithTitle,
                    equippedTitle: equippedTitleName,
                    equippedRarity: equippedTitleRarity,
                    hasAura: (provider.equippedCosmetics['aura'] ?? '').toString().isNotEmpty,
                    hasFrame: (provider.equippedCosmetics['frame'] ?? '').toString().isNotEmpty,
                  ),
                  const SizedBox(height: 10),
                  _EquippedTitlePill(title: (equippedTitleName == null || equippedTitleName.trim().isEmpty) ? provider.faithTitle : equippedTitleName),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const SectionHeader('Your Journey so far', icon: Icons.insights_rounded),
            FutureBuilder<Map<String, int>>(
              future: provider.getUserStats(),
              builder: (context, snap) {
                final stats = snap.data ?? const <String, int>{};
                final chapters = stats['totalChaptersCompleted'] ?? 0;
                final quizzesDone = stats['totalQuizzesCompleted'] ?? 0;
                final reflections = stats['reflectionsCompleted'] ?? 0;
                final steps = stats['questStepsCompleted'] ?? 0;
                final planDays = stats['readingPlanDaysCompleted'] ?? 0;
                final currentStreak = provider.currentBibleStreak;
                final longestStreak = provider.longestBibleStreak;
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return FadeSlideIn(
                  child: _YourJourneySoFarCard(
                    chapters: chapters,
                    quizzes: quizzesDone,
                    reflections: reflections,
                    questSteps: steps,
                    planDays: planDays,
                    currentStreak: currentStreak,
                    longestStreak: longestStreak,
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
            const SectionHeader('Tools', icon: Icons.apps_rounded),
            const SizedBox(height: 8),
            // Simplified tools list (beta focus)
            FadeSlideIn(
              child: _SimpleToolsList(),
            ),

            const SizedBox(height: 16),
            // Collapsible Explore section
            FadeSlideIn(
              child: _CollapsibleExploreSection(),
            ),

            const SizedBox(height: 12),
            // Secondary sections with reduced emphasis
            FadeSlideIn(child: _TitlesCard()),

            const SizedBox(height: 12),
            FadeSlideIn(child: _AchievementsPreviewCard()),

            const SizedBox(height: 12),
          ],
        ),
      );
    });
  }
}

/// Simplified tools list for beta focus - only essential items
class _SimpleToolsList extends StatelessWidget {
  const _SimpleToolsList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SacredCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          _ExploreRow(
            icon: Icons.edit_rounded,
            label: 'Journal',
            onTap: () => context.go('/journal'),
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.12)),
          _ExploreRow(
            icon: Icons.favorite_rounded,
            label: 'Favorites',
            onTap: () => context.go('/favorite-verses'),
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.12)),
          _ExploreRow(
            icon: Icons.settings_rounded,
            label: 'Settings',
            onTap: () => context.go('/settings'),
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.12)),
          _ExploreRow(
            icon: Icons.people_alt_rounded,
            label: 'Friends (Beta)',
            onTap: () => context.go('/friends'),
          ),
        ],
      ),
    );
  }
}

/// Collapsible Explore section - collapsed by default
class _CollapsibleExploreSection extends StatefulWidget {
  const _CollapsibleExploreSection();

  @override
  State<_CollapsibleExploreSection> createState() => _CollapsibleExploreSectionState();
}

class _CollapsibleExploreSectionState extends State<_CollapsibleExploreSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SacredCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.explore_rounded, color: cs.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Explore (Coming Soon)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: cs.onSurfaceVariant,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Column(
                children: [
                  Divider(height: 1, color: cs.outline.withValues(alpha: 0.12)),
                  _ExploreRow(
                    icon: Icons.auto_stories_rounded,
                    label: 'Reading Plans',
                    onTap: () => context.go('/reading-plans'),
                  ),
                  Divider(height: 1, color: cs.outline.withValues(alpha: 0.12)),
                  _ExploreRow(
                    icon: Icons.self_improvement_rounded,
                    label: 'Avatar & Cosmetics',
                    onTap: () => context.go('/avatar'),
                  ),
                  Divider(height: 1, color: cs.outline.withValues(alpha: 0.12)),
                  _ExploreRow(
                    icon: Icons.people_rounded,
                    label: 'Community',
                    onTap: () => context.go('/community'),
                  ),
                  Divider(height: 1, color: cs.outline.withValues(alpha: 0.12)),
                  _ExploreRow(
                    icon: Icons.games_rounded,
                    label: 'Play & Learn',
                    onTap: () => context.go('/play-learn'),
                  ),
                ],
              ),
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _ExploreSection extends StatelessWidget {
  const _ExploreSection();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SacredCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          _ExploreRow(
            icon: Icons.auto_stories_rounded,
            label: 'Reading Plans',
            onTap: () => context.go('/reading-plans'),
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.12)),
          _ExploreRow(
            icon: Icons.self_improvement_rounded,
            label: 'Avatar & Cosmetics',
            onTap: () => context.go('/avatar'),
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.12)),
          _ExploreRow(
            icon: Icons.people_rounded,
            label: 'Community',
            onTap: () => context.go('/community'),
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.12)),
          _ExploreRow(
            icon: Icons.games_rounded,
            label: 'Play & Learn',
            onTap: () => context.go('/play-learn'),
          ),
        ],
      ),
    );
  }
}

class _ExploreRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ExploreRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: cs.primary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: cs.onSurface,
                    ),
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

void _openChangeTitleSheet(BuildContext context) {
  final app = context.read<AppProvider>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: GamerColors.darkCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final seeds = TitleSeedsV1.list();
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(ctx).padding.bottom),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: GamerColors.accent),
                    const SizedBox(width: 8),
                    Text('Choose Your Title', style: Theme.of(ctx).textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: FutureBuilder<List<String>>(
                    future: app.getUnlockedTitleIds(),
                    builder: (context, snap) {
                      final unlocked = snap.data ?? const <String>[];
                      final equippedId = app.equippedTitleId;
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemBuilder: (context, index) {
                          final t = seeds[index];
                          final isUnlocked = unlocked.contains(t.id);
                          final isEquipped = equippedId == t.id;
                          final cs = Theme.of(context).colorScheme;
                          return SacredCard(
                            onTap: isUnlocked
                                ? () async {
                                    await app.equipTitle(t.id);
                                    if (context.mounted) Navigator.of(context).pop();
                                  }
                                : null,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            borderSide: isEquipped
                                ? BorderSide(color: cs.primary.withValues(alpha: 0.4), width: 1.2)
                                : BorderSide(color: cs.outline.withValues(alpha: 0.18)),
                            child: Row(
                              children: [
                                Icon(
                                  isUnlocked ? Icons.stars_rounded : Icons.lock_rounded,
                                  color: isUnlocked ? cs.primary : cs.onSurfaceVariant,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.name,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: isUnlocked ? cs.onSurface : cs.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isUnlocked ? t.description : 'Locked • ${t.description}',
                                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _TitleStatusChip(isUnlocked: isUnlocked, isEquipped: isEquipped),
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (context, _) => const SizedBox(height: 10),
                        itemCount: seeds.length,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// Reading Plan CTA has been moved to Community tab; Profile no longer includes it

class _TopIdentity extends StatelessWidget {
  final String username;
  final int level;
  final String faithTitle; // fallback
  final String? equippedTitle;
  final String? equippedRarity; // common|rare|epic|legendary
  final bool hasAura;
  final bool hasFrame;

  const _TopIdentity({
    required this.username,
    required this.level,
    required this.faithTitle,
    required this.equippedTitle,
    required this.equippedRarity,
    required this.hasAura,
    required this.hasFrame,
  });

  Color _rarityColor(String? rarity) {
    switch ((rarity ?? 'common').toLowerCase()) {
      case 'legendary':
        return GamerColors.neonPink;
      case 'epic':
        return GamerColors.neonPurple;
      case 'rare':
        return GamerColors.neonCyan;
      default:
        return GamerColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleToShow = (equippedTitle == null || equippedTitle!.trim().isEmpty) ? faithTitle : equippedTitle!;
    final rarityColor = _rarityColor(equippedRarity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar with subtle circular gradient glow
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      GamerColors.neonCyan.withValues(alpha: 0.15),
                      GamerColors.neonPurple.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                    stops: const [0.2, 0.6, 1.0],
                  ),
                ),
              ),
              Transform.scale(
                scale: 1.06,
                child: Builder(builder: (context) {
                  final app = context.watch<AppProvider>();
                  return SoulAvatarViewV2(
                    level: level,
                    faithPower: app.faithPower.toDouble(),
                    size: SoulAvatarSize.mini,
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(username, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        // Calm stats line under username per spec
        Builder(builder: (context) {
          final app = context.watch<AppProvider>();
          final user = app.currentUser;
          final xp = user?.totalXP ?? user?.currentXP ?? 0;
          final streak = app.currentBibleStreak;
          return Text(
            'XP: $xp • Streak: $streak',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          );
        }),
      ],
    );
  }
}






// Large two-per-row Tools layout — Sacred-Dark tall cards
class _ToolLargeItem {
  final String label;
  final IconData icon;
  final String? route;
  final bool enabled;
  const _ToolLargeItem({
    required this.label,
    required this.icon,
    this.route,
    this.enabled = true,
  });
}

class _ToolsLargeGrid extends StatelessWidget {
  final List<_ToolLargeItem> items;
  const _ToolsLargeGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    const spacing = 16.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final cols = maxWidth >= 720 ? 3 : 2; // responsive: 3 on wide screens
        final itemWidth = (maxWidth - (spacing * (cols - 1))) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final it in items)
              SizedBox(
                width: itemWidth,
                child: _LargeToolTile(item: it),
              ),
          ],
        );
      },
    );
  }
}

class _LargeToolTile extends StatelessWidget {
  final _ToolLargeItem item;
  const _LargeToolTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final purple = Theme.of(context).extension<PurpleUi>();

    final isCosmetics = item.label.toLowerCase().startsWith('cosmetics');

    // Build content with circular icon bg, title and optional subtitle
    final content = SizedBox(
      height: 152, // consistent height 140–160
      child: Stack(
        children: [
          // Coming soon chip (only for disabled cosmetics)
          if (!item.enabled && isCosmetics)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.24)),
                ),
                child: Text('Coming soon', style: Theme.of(context).textTheme.labelSmall),
              ),
            ),
          // Main column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon inside circular bg
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: purple?.iconCircleAlpha ?? 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Icon(item.icon, color: (purple?.accent ?? cs.primary), size: 22)),
              ),
              const SizedBox(height: 12),
              Text(
                isCosmetics ? 'Cosmetics' : item.label,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ],
          ),
        ],
      ),
    );

    VoidCallback? onTap;
    if (item.enabled && (item.route != null && item.route!.isNotEmpty)) {
      onTap = () => context.push(item.route!);
    }

    final card = SacredCard(
      // Do not pass onTap to avoid ripple; we add our own gentle press animation
      padding: const EdgeInsets.all(16),
      child: Opacity(opacity: item.enabled ? 1.0 : 0.45, child: content),
      borderSide: BorderSide(color: (Theme.of(context).extension<PurpleUi>()?.cardOutline ?? cs.outline.withValues(alpha: 0.22))),
      radius: 16,
    );

    if (onTap == null) {
      // Disabled or no route: show as-is (no tap feedback)
      return IgnorePointer(ignoring: true, child: card);
    }

    // Enabled: wrap with gentle press scale (no splash)
    return _PressableScale(onTap: onTap, child: card);
  }
}

// Gentle press feedback without splash: scales down slightly on press
class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressableScale({required this.child, required this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}


// Achievements preview card: shows count and up to 3 recent unlocked achievements.
class _AchievementsPreviewCard extends StatelessWidget {
  const _AchievementsPreviewCard();

  List<AchievementModel> _recentUnlocked(List<AchievementModel> list, {int take = 3}) {
    final unlocked = list.where((a) => a.isUnlocked).toList();
    unlocked.sort((a, b) {
      final at = a.unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });
    if (unlocked.length <= take) return unlocked;
    return unlocked.sublist(0, take);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final achievements = app.achievements;
    final unlockedCount = app.totalAchievementsUnlocked;
    final totalCount = achievements.length;
    final recent = _recentUnlocked(achievements);

    final cs = Theme.of(context).colorScheme;
    final purple = Theme.of(context).extension<PurpleUi>();
    return SacredCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: purple?.accent ?? cs.primary),
              const SizedBox(width: 8),
              Expanded(child: Text('Achievements', style: Theme.of(context).textTheme.titleMedium)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.24)),
                ),
                child: Text('$unlockedCount / $totalCount', style: Theme.of(context).textTheme.labelSmall),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (unlockedCount == 0) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'You haven’t unlocked any achievements yet — they’ll appear here as you keep going.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.push('/achievements'),
                icon: Icon(Icons.chevron_right_rounded, color: purple?.accent ?? cs.primary),
                label: const Text('View all achievements'),
              ),
            ),
          ] else ...[
            // Show up to 3 most recent unlocked achievements
            for (final a in recent) ...[
              _AchievementPreviewRow(name: a.displayName, description: a.description, status: 'Unlocked'),
              const SizedBox(height: 8),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.push('/achievements'),
                icon: Icon(Icons.chevron_right_rounded, color: purple?.accent ?? cs.primary),
                label: const Text('View all achievements'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AchievementPreviewRow extends StatelessWidget {
  final String name;
  final String description;
  final String? status; // e.g., "Unlocked"
  const _AchievementPreviewRow({required this.name, required this.description, this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final purple = Theme.of(context).extension<PurpleUi>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events_rounded, color: purple?.accent ?? cs.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (status != null && status!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(status!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}

// Polished Titles card: highlights equipped title, shows a small preview list, and Manage CTA
class _TitlesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final cs = Theme.of(context).colorScheme;
    final seeds = TitleSeedsV1.list();

    String titleNameFromId(String? id) {
      if (id == null || id.isEmpty) return '';
      try {
        return seeds.firstWhere((e) => e.id == id).name;
      } catch (_) {
        return '';
      }
    }

    final equippedId = app.equippedTitleId;
    final equippedName = (titleNameFromId(equippedId).trim().isEmpty) ? app.faithTitle : titleNameFromId(equippedId);

    return FutureBuilder<List<String>>(
      future: app.getUnlockedTitleIds(),
      builder: (context, snap) {
        final unlocked = snap.data ?? const <String>[];
        final otherUnlocked = seeds
            .where((t) => unlocked.contains(t.id) && t.id != equippedId)
            .take(3)
            .toList();

        return SacredCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events_outlined, color: cs.primary),
                  const SizedBox(width: 8),
                  Text('Your Titles', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 10),
              // Equipped title spotlight (tappable)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openChangeTitleSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outline.withValues(alpha: 0.22)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.stars_rounded, color: cs.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Equipped: $equippedName', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text('Shown across your journey.', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: cs.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (unlocked.length > 1 && otherUnlocked.isNotEmpty) ...[
                Text('Unlocked titles', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in otherUnlocked) _TitleChip(label: t.name),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _openChangeTitleSheet(context),
                  icon: Icon(Icons.chevron_right_rounded, color: cs.primary),
                  label: const Text('Manage titles'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TitleChip extends StatelessWidget {
  final String label;
  const _TitleChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outline.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.label_rounded, size: 14, color: cs.primary),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TitleStatusChip extends StatelessWidget {
  final bool isUnlocked;
  final bool isEquipped;
  const _TitleStatusChip({required this.isUnlocked, required this.isEquipped});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (isEquipped) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outline.withValues(alpha: 0.24)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_rounded, size: 16, color: cs.primary),
            const SizedBox(width: 6),
            Text('Equipped', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      );
    }
    if (isUnlocked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outline.withValues(alpha: 0.24)),
        ),
        child: Text('Unlocked', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurface)),
      );
    }
    return Icon(Icons.lock_rounded, color: cs.onSurfaceVariant);
  }
}

// Sacred pill for equipped title under avatar
class _EquippedTitlePill extends StatelessWidget {
  final String? title;
  const _EquippedTitlePill({required this.title});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final purple = Theme.of(context).extension<PurpleUi>();
    if (title == null || title!.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: purple?.accent.withValues(alpha: 0.12) ?? cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: (purple?.accent.withValues(alpha: 0.22) ?? cs.outline.withValues(alpha: 0.24))),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars_rounded, color: purple?.accent ?? cs.primary, size: 16),
          const SizedBox(width: 8),
          Text(
            title!,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: purple?.accent.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

// Sacred-Dark primary stats card per spec
class _YourJourneySoFarCard extends StatelessWidget {
  final int chapters;
  final int quizzes;
  final int reflections;
  final int questSteps;
  final int planDays;
  final int currentStreak;
  final int longestStreak;

  const _YourJourneySoFarCard({
    required this.chapters,
    required this.quizzes,
    required this.reflections,
    required this.questSteps,
    required this.planDays,
    required this.currentStreak,
    required this.longestStreak,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget row(String label, String value, {IconData? icon}) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? Icons.check_circle_outline, color: cs.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text('$label: $value', style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      );
    }

    return SacredCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.insights_rounded, color: cs.primary), const SizedBox(width: 8), Text('Your Journey so far', style: Theme.of(context).textTheme.titleMedium)]),
          const SizedBox(height: 6),
          Text('A quiet look at how far you\'ve come.', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 12),
          // Keep 5–6 calm lines
          row('Chapters completed', '$chapters', icon: Icons.menu_book_rounded),
          const SizedBox(height: 8),
          row('Quizzes completed', '$quizzes', icon: Icons.fact_check_rounded),
          const SizedBox(height: 8),
          row('Reflections written', '$reflections', icon: Icons.edit_rounded),
          const SizedBox(height: 8),
          row('Quest steps finished', '$questSteps', icon: Icons.flag_circle_rounded),
          const SizedBox(height: 8),
          row('Plan days completed', '$planDays', icon: Icons.calendar_month_rounded),
          const SizedBox(height: 8),
          row('Current streak', currentStreak > 0
              ? '$currentStreak day${currentStreak == 1 ? '' : 's'}' + (longestStreak > 0 ? ' • Longest: $longestStreak' : '')
              : '0', icon: Icons.local_fire_department_rounded),
        ],
      ),
    );
  }
}

// Sacred Stats card per spec

