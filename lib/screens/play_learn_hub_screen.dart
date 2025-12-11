import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:level_up_your_faith/widgets/sacred/sacred_ui.dart';

/// Minimal Play & Learn hub that lists all available mini‑games.
/// UI-only: routes for individual games remain unchanged.
class PlayLearnHubScreen extends StatelessWidget {
  const PlayLearnHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Play & Learn'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            // Calm subtitle under the title
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 12),
              child: Text(
                "Games and practice to help you remember God’s Word.",
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),

            const SectionHeader('Mini‑games', icon: Icons.extension_outlined),
            _GameTile(
              icon: Icons.sports_esports_outlined,
              title: 'Matching Game',
              subtitle: 'Match verses and references.',
              onTap: () => context.push('/matching-game'),
            ),
            const SizedBox(height: 12),
            _GameTile(
              icon: Icons.format_quote_rounded,
              title: 'Verse Scramble',
              subtitle: 'Unscramble key Bible verses.',
              onTap: () => context.push('/verse-scramble'),
            ),
            const SizedBox(height: 12),
            _GameTile(
              icon: Icons.menu_book_rounded,
              title: 'Book Order',
              subtitle: 'Practice the order of Bible books.',
              onTap: () => context.push('/book-order-game'),
            ),
            const SizedBox(height: 12),
            _GameTile(
              icon: Icons.emoji_emotions_outlined,
              title: 'Emoji Parables',
              subtitle: 'Guess the parables from emojis.',
              onTap: () => context.push('/emoji-parables'),
            ),
            const SizedBox(height: 16),
            const SectionHeader('Practice & Memory', icon: Icons.bookmark_border),
            _GameTile(
              icon: Icons.bookmark_border,
              title: 'Practice Verses',
              subtitle: 'Review and memorize your favorite verses.',
               // Open the main Memorization screen; it will handle favorites/curated defaults
               onTap: () => context.push('/memorization'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _GameTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return SacredCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.primary.withValues(alpha: 0.4), width: 1),
            ),
            child: Icon(icon, color: cs.onPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}
