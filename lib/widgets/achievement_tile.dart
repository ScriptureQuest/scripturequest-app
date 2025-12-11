import 'package:flutter/material.dart';
import 'package:level_up_your_faith/models/achievement_model.dart';
import 'package:level_up_your_faith/theme.dart';

class AchievementTile extends StatelessWidget {
  final AchievementModel achievement;

  const AchievementTile({super.key, required this.achievement});

  Color _getTierColor() {
    switch (achievement.tier) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'legendary':
        return GamerColors.neonPurple;
      default:
        return GamerColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tierColor = _getTierColor();
    final isLocked = !achievement.isUnlocked;
    final purple = Theme.of(context).extension<PurpleUi>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLocked ? GamerColors.darkSurface : GamerColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLocked
              ? (purple?.cardOutline ?? GamerColors.textTertiary.withValues(alpha: 0.3))
              : tierColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events,
            color: isLocked ? GamerColors.textTertiary : tierColor,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: isLocked ? GamerColors.textTertiary : GamerColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (isLocked) ...[
            const SizedBox(height: 8),
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: purple?.progressTrack ?? GamerColors.darkBackground,
                borderRadius: BorderRadius.circular(2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: FractionallySizedBox(
                  widthFactor: achievement.progressPercent,
                  alignment: Alignment.centerLeft,
                  child: Container(color: purple?.progressFill ?? tierColor),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${achievement.progress}/${achievement.requirement}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ] else
            Text(
              'UNLOCKED',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: tierColor, fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }
}
