import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/achievement_model.dart';
import '../providers/app_provider.dart';
import '../services/reward_service.dart';
import '../theme/scripture_theme.dart';
import '../widgets/product/product_ui.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});
  @override
  State<AchievementsScreen> createState() => _AchievementsState();
}

class _AchievementsState extends State<AchievementsScreen> {
  String filter = 'All';
  String family = 'All families';
  @override
  Widget build(BuildContext context) {
    final all = context.watch<AppProvider>().achievements;
    final earned = all.where((a) => a.isUnlocked).length;
    final groups = all
        .where((a) => !a.isSecret || a.isUnlocked)
        .map((a) => a.category)
        .toSet()
        .toList()
      ..sort();
    final items = all
        .where((a) =>
            (filter == 'All' ||
                (filter == 'Earned' ? a.isUnlocked : !a.isUnlocked)) &&
            (family == 'All families' || a.category == family))
        .toList()
      ..sort((a, b) {
        if (a.isUnlocked != b.isUnlocked) return a.isUnlocked ? -1 : 1;
        return a.displayName.compareTo(b.displayName);
      });
    return Scaffold(
        appBar: AppBar(title: const Text('Accomplishments')),
        body: ProductWidth(
            child: ListView(padding: const EdgeInsets.all(24), children: [
          Text('Your exploration leaves a mark.',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          const Text(
              'Earned through reading, learning, and completing your quests. These are app accomplishments, never a measure of spiritual worth.'),
          const SizedBox(height: 20),
          const ProgressIdentity(linkToAchievements: false),
          const SizedBox(height: 24),
          Text('$earned of ${all.length} accomplishments earned',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final value in ['All', 'Earned', 'To explore'])
              ChoiceChip(
                  label: Text(value),
                  selected: filter == value,
                  onSelected: (_) => setState(() => filter = value))
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
              isExpanded: true,
              value: family,
              decoration: const InputDecoration(
                  labelText: 'Accomplishment family',
                  border: OutlineInputBorder()),
              items: [
                for (final value in ['All families', ...groups])
                  DropdownMenuItem(value: value, child: Text(value))
              ],
              onChanged: (v) => setState(() => family = v!)),
          const SizedBox(height: 20),
          if (items.isEmpty)
            const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                    'No accomplishments in this view yet. Your existing progress is kept.')),
          ActivityShelf(children: [
            for (final a in items) AchievementCard(achievement: a)
          ]),
        ])));
  }
}

class AchievementCard extends StatelessWidget {
  final AchievementModel achievement;
  const AchievementCard({super.key, required this.achievement});
  static IconData familyIcon(AchievementModel a) {
    final kind = '${a.category} ${a.iconKey}'.toLowerCase();
    if (kind.contains('read') || kind.contains('bible'))
      return Icons.auto_stories_outlined;
    if (kind.contains('quest')) return Icons.route_outlined;
    if (kind.contains('memory') || kind.contains('mastery'))
      return Icons.psychology_outlined;
    if (kind.contains('journal') || kind.contains('reflection'))
      return Icons.edit_note;
    if (kind.contains('streak')) return Icons.local_fire_department_outlined;
    return Icons.workspace_premium_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final p = QuestPalette.of(context);
    final secret = a.isSecret && !a.isUnlocked;
    final reward = a.rewards.isNotEmpty
        ? a.rewards.map(RewardService.formatRewardLabel).join(' · ')
        : a.xpReward > 0
            ? '${a.xpReward} XP'
            : '';
    return Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: p.darkCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
                color: a.isUnlocked
                    ? p.gold
                    : Theme.of(context).colorScheme.outlineVariant,
                width: a.isUnlocked ? 1.5 : 1)),
        child: Padding(
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (a.isUnlocked ? p.gold : p.textSecondary)
                            .withValues(alpha: .12),
                        border: Border.all(
                            color: a.isUnlocked ? p.gold : p.textSecondary,
                            width: 2)),
                    child: Icon(secret ? Icons.lock_outline : familyIcon(a),
                        size: 30,
                        color: a.isUnlocked ? p.gold : p.textSecondary)),
                const Spacer(),
                Icon(
                    a.isUnlocked ? Icons.verified_outlined : Icons.lock_outline,
                    color: a.isUnlocked ? p.gold : p.textSecondary)
              ]),
              const SizedBox(height: 16),
              Text(
                  a.isUnlocked
                      ? 'EARNED · ${a.displayRarity.toUpperCase()}'
                      : 'TO EXPLORE',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: a.isUnlocked ? p.gold : p.textSecondary)),
              const SizedBox(height: 8),
              Text(secret ? 'A discovery ahead' : a.displayName,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Text(secret
                  ? 'Keep exploring Scripture to reveal this accomplishment.'
                  : a.description),
              if (!secret &&
                  !a.isUnlocked &&
                  a.progress > 0 &&
                  (a.target > 0 || a.requirement > 0)) ...[
                const SizedBox(height: 14),
                LinearProgressIndicator(value: a.progressPercent),
                const SizedBox(height: 6),
                Text(
                    '${a.progress} / ${a.target > 0 ? a.target : a.requirement} recorded')
              ],
              if (a.unlockedAt != null)
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                        'Earned ${a.unlockedAt!.toLocal().toIso8601String().split('T').first}',
                        style: Theme.of(context).textTheme.labelMedium)),
              if (!secret && reward.isNotEmpty)
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text('Reward · $reward',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: p.accent))),
            ])));
  }
}
