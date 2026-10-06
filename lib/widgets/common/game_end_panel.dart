import '../sessions/session_ending.dart';
import 'package:go_router/go_router.dart';
import '../../models/connected/passage_reference.dart';
import 'package:flutter/material.dart';
import 'package:level_up_your_faith/widgets/sacred/sacred_ui.dart';
import '../../theme/scripture_theme.dart';

/// Unified end screen panel for Play & Learn mini-games.
/// Presentation only: saved summary, stopping point and optional exploration.
class GameEndPanel extends StatelessWidget {
  final String header; // e.g., "Great job!"
  final String summary; // e.g., "You matched all pairs."
  final int? xp; // already-awarded XP; if null or <= 0, hides the line
  final List<String> references;
  final VoidCallback? onRetrySave;
  final VoidCallback onPlayAgain;
  final VoidCallback onBackToHub;

  const GameEndPanel({
    super.key,
    required this.header,
    required this.summary,
    required this.onPlayAgain,
    required this.onBackToHub,
    this.xp,
    this.onRetrySave,
    this.references = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final passage = references
        .map(PassageReference.tryParse)
        .whereType<PassageReference>()
        .firstOrNull;
    return SacredCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.celebration, color: QuestPalette.of(context).success),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(header,
                      style: theme.textTheme.titleLarge ??
                          theme.textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
              liveRegion: xp != null,
              child: Text(
                summary,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              )),
          if ((xp ?? 0) > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.auto_awesome,
                    size: 18, color: QuestPalette.of(context).success),
                const SizedBox(width: 6),
                Text('+${(xp ?? 0)} XP', style: theme.textTheme.labelLarge),
              ],
            ),
          ],
          if (xp == 0) const Text('Practice complete · earlier reward kept.'),
          if (xp == null && onRetrySave != null)
            TextButton(
                onPressed: onRetrySave,
                child: const Text('Save result / retry')),
          if (xp != null)
            SessionEnding(passage: passage, more: [
              for (final ref in references.toSet())
                if (PassageReference.tryParse(ref) != null)
                  TextButton.icon(
                      onPressed: () => context.push(
                          PassageReference.tryParse(ref)!.destination.route),
                      icon: const Icon(Icons.menu_book),
                      label: Text('Explore $ref')),
              TextButton.icon(
                  onPressed: onPlayAgain,
                  icon: const Icon(Icons.replay),
                  label: const Text('Play Again')),
              TextButton.icon(
                  onPressed: onBackToHub,
                  icon: const Icon(Icons.extension),
                  label: const Text('Back to Play & Learn')),
            ])
          else
            TextButton(
                onPressed: onBackToHub,
                child: const Text('Back to Play & Learn')),
        ],
      ),
    );
  }
}
