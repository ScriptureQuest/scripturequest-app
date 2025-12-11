import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:level_up_your_faith/widgets/home_action_button.dart';
import 'package:level_up_your_faith/widgets/sacred/sacred_ui.dart';
// We now render a custom Unlocked/Locked layout instead of the old grid tile widget

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final achievements = provider.achievements;
        final unlocked = achievements.where((a) => a.isUnlocked).toList();
        final locked = achievements.where((a) => !a.isUnlocked).toList();
        final unlockedCount = unlocked.length;

        return Scaffold(
          appBar: AppBar(
            title: Text('Achievements', style: Theme.of(context).textTheme.headlineSmall),
            leading: Navigator.of(context).canPop()
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.pop(),
                  )
                : null,
            centerTitle: true,
            actions: const [HomeActionButton()],
          ),
          body: FadeSlideIn(
            child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [GamerColors.success.withValues(alpha: 0.18), GamerColors.accent.withValues(alpha: 0.16)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25), width: 1),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
                        const SizedBox(width: 10),
                        Text(
                          'Achievements',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$unlockedCount / ${achievements.length} unlocked',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: achievements.isEmpty ? 0 : unlockedCount / achievements.length,
                        minHeight: 8,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(GamerColors.accent),
                      ),
                    ),
                  ],
                ),
              ),

              // Unlocked section
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: SectionHeader('Unlocked', icon: Icons.emoji_events_rounded),
              ),
              if (unlocked.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const EmptyState(message: 'Your journey has only begun.'),
                )
              else
                _gridWrapper(context, unlocked, unlockedMode: true),

              const SizedBox(height: 12),

              // Locked section
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: SectionHeader('Locked', icon: Icons.lock_rounded),
              ),
              if (locked.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const EmptyState(message: 'You have unlocked everything. Legendary!'),
                )
              else
                _gridWrapper(context, locked, unlockedMode: false),
            ],
          )),
        );
      },
    );
  }
}

Widget _hintCard(BuildContext context, String message) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: GamerColors.darkCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: GamerColors.accent.withValues(alpha: 0.2), width: 1),
    ),
    child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
  );
}

Widget _gridWrapper(BuildContext context, List achievements, {required bool unlockedMode}) {
  Color rarityColor(dynamic a) {
    final r = ((a.rarity ?? a.displayRarity ?? a.tier ?? 'common').toString()).toLowerCase();
    switch (r) {
      case 'legendary':
        return Colors.amber;
      case 'epic':
        return Colors.purpleAccent;
      case 'rare':
        return Colors.lightBlueAccent;
      case 'common':
      default:
        return Colors.grey;
    }
  }
  String rarityLabel(dynamic a) {
    final r = ((a.rarity ?? a.displayRarity ?? a.tier ?? 'Common').toString()).toLowerCase();
    switch (r) {
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
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        for (int index = 0; index < achievements.length; index++) ...[
          _achievementListTile(context, achievements[index], rarityColor, rarityLabel),
          if (index != achievements.length - 1) const SizedBox(height: 10),
        ],
      ],
    ),
  );
}

Widget _achievementListTile(BuildContext context, dynamic a, Color Function(dynamic) rarityColor, String Function(dynamic) rarityLabel) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  final isUnlocked = a.isUnlocked == true;
  final baseColor = isUnlocked ? rarityColor(a) : cs.onSurfaceVariant;
  final titleText = (!isUnlocked && a.isSecret == true) ? 'Secret Achievement' : a.title;
  final descText = (!isUnlocked && a.isSecret == true) ? 'Keep going to reveal this.' : a.description;
  final reward = _rewardShort(a);
  
  // Enhanced styling: unlocked gets stronger colors, locked gets dimmed
  final iconColor = isUnlocked ? GamerColors.accent : cs.onSurfaceVariant.withValues(alpha: 0.5);
  final iconSize = isUnlocked ? 24.0 : 22.0;
  final tileOpacity = isUnlocked ? 1.0 : 0.75;
  
  return Opacity(
    opacity: tileOpacity,
    child: SacredCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.emoji_events_rounded, color: iconColor, size: iconSize),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        titleText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusChip(context, isUnlocked: isUnlocked),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  descText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isUnlocked ? cs.onSurfaceVariant : cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                if (reward.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    reward,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isUnlocked ? GamerColors.accent : cs.onSurfaceVariant.withValues(alpha: 0.6),
                      fontWeight: isUnlocked ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _statusChip(BuildContext context, {required bool isUnlocked}) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: cs.outline.withValues(alpha: 0.24)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(isUnlocked ? Icons.check_rounded : Icons.lock_rounded, size: 14, color: isUnlocked ? cs.primary : cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(isUnlocked ? 'Unlocked' : 'Locked', style: theme.textTheme.labelSmall),
      ],
    ),
  );
}

String _formatDate(DateTime dt) {
  final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  final m = months[dt.month - 1];
  return '$m ${dt.day}, ${dt.year}';
}

String _rewardShort(dynamic a) {
  try {
    if (a.rewards is List && (a.rewards as List).isNotEmpty) {
      final first = (a.rewards as List).first;
      final label = (first.label?.toString() ?? '').trim();
      if (label.isNotEmpty) return label;
    }
    final int xp = (a.xpReward is int) ? a.xpReward as int : int.tryParse('${a.xpReward}') ?? 0;
    if (xp > 0) return '+$xp XP';
    return '';
  } catch (_) {
    return '';
  }
}
