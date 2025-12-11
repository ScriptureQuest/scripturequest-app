import 'package:flutter/material.dart';
import 'package:level_up_your_faith/models/quest_model.dart';
import 'package:level_up_your_faith/theme.dart';

Future<void> showTaskCompleteModal({
  required BuildContext context,
  required TaskModel quest,
  required VoidCallback onClaim,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return Dialog(
        backgroundColor: GamerColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events, color: GamerColors.accent, size: 22),
                  const SizedBox(width: 8),
                  Text('Task Complete!', style: Theme.of(ctx).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 8),
              Text(quest.title, textAlign: TextAlign.center, style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              // XP burst chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: GamerColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: GamerColors.accent.withValues(alpha: 0.4), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: GamerColors.accent, size: 18),
                    const SizedBox(width: 8),
                    Text('+${quest.xpReward} XP', style: Theme.of(ctx).textTheme.labelLarge?.copyWith(color: GamerColors.accent)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Rewards preview (icons only for now)
              if (quest.rewards.isNotEmpty) Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: quest.rewards.map((r) {
                  final isXp = r.type == 'xp';
                  final icon = isXp ? Icons.stars : Icons.auto_awesome;
                  final color = isXp ? GamerColors.accent : GamerColors.neonPurple;
                  final label = r.label.isNotEmpty ? r.label : (isXp ? '+${r.amount ?? 0} XP' : 'Reward');
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: GamerColors.darkSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: color, size: 18),
                        const SizedBox(width: 8),
                        Text(label, style: Theme.of(ctx).textTheme.labelMedium),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.redeem, color: GamerColors.darkBackground),
                  label: const Text('Claim Rewards'),
                  onPressed: () {
                    Navigator.of(ctx).maybePop();
                    onClaim();
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
