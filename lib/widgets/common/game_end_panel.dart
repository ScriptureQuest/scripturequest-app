import 'package:flutter/material.dart';
import 'package:level_up_your_faith/widgets/sacred/sacred_ui.dart';
import 'package:level_up_your_faith/theme.dart';

/// Unified end screen panel for Play & Learn mini-games.
/// Visual-only: shows a calm header, summary, optional XP line, and two actions.
class GameEndPanel extends StatelessWidget {
  final String header; // e.g., "Great job!"
  final String summary; // e.g., "You matched all pairs."
  final int? xp; // already-awarded XP; if null or <= 0, hides the line
  final VoidCallback onPlayAgain;
  final VoidCallback onBackToHub;

  const GameEndPanel({
    super.key,
    required this.header,
    required this.summary,
    required this.onPlayAgain,
    required this.onBackToHub,
    this.xp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return SacredCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.celebration, color: GamerColors.success),
              const SizedBox(width: 10),
              Expanded(child: Text(header, style: theme.textTheme.titleLarge ?? theme.textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          if ((xp ?? 0) > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 18, color: GamerColors.success),
                const SizedBox(width: 6),
                Text('+${(xp ?? 0)} XP', style: theme.textTheme.labelLarge),
              ],
            ),
          ],
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              final isWide = c.maxWidth > 420;
              final children = <Widget>[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onPlayAgain,
                    icon: const Icon(Icons.replay, color: GamerColors.darkBackground),
                    label: const Text('Play Again'),
                  ),
                ),
                SizedBox(width: isWide ? 12 : 0, height: isWide ? 0 : 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onBackToHub,
                    icon: Icon(Icons.extension, color: theme.colorScheme.primary),
                    label: const Text('Back to Play & Learn'),
                  ),
                ),
              ];
              if (isWide) {
                return Row(children: children);
              }
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
            },
          )
        ],
      ),
    );
  }
}
