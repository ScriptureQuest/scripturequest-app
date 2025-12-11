import 'package:flutter/material.dart';
import 'package:level_up_your_faith/models/verse_model.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/services/bible_rendering_service.dart';

class VerseCard extends StatelessWidget {
  final VerseModel verse;
  final VoidCallback onTap;

  const VerseCard({
    super.key,
    required this.verse,
    required this.onTap,
  });

  Color _getCategoryColor() {
    switch (verse.category) {
      case 'faith':
        return GamerColors.neonCyan;
      case 'love':
        return GamerColors.neonPink;
      case 'strength':
        return GamerColors.neonPurple;
      case 'wisdom':
        return GamerColors.neonGreen;
      case 'courage':
        return const Color(0xFFFFAA00);
      default:
        return GamerColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: verse.isCompleted ? GamerColors.success.withValues(alpha: 0.5) : categoryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    verse.category.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: categoryColor, fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                if (verse.isCompleted)
                  const Icon(Icons.check_circle, color: GamerColors.success, size: 20)
                else
                  Row(
                    children: [
                      Icon(Icons.stars, color: Theme.of(context).colorScheme.primary, size: 16),
                      const SizedBox(width: 4),
                      Text('+${verse.xpReward} XP', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(verse.reference, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: categoryColor)),
            const SizedBox(height: 8),
            // Render verse content via global red-letter renderer
            BibleRenderingService.richText(
              context,
              reference: verse.reference,
              text: verse.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
