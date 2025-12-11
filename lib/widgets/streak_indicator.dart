import 'package:flutter/material.dart';
import 'package:level_up_your_faith/theme.dart';

class StreakIndicator extends StatelessWidget {
  final int streakDays;
  final int longestStreak;

  const StreakIndicator({
    super.key,
    required this.streakDays,
    required this.longestStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GamerColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GamerColors.danger.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: GamerColors.danger.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: GamerColors.danger.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_fire_department, color: GamerColors.danger, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('$streakDays', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: GamerColors.danger)),
                    const SizedBox(width: 4),
                    Text('Day Streak', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Longest: $longestStreak days', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
