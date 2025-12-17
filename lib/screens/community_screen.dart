import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/widgets/sacred/sacred_ui.dart';
import 'package:level_up_your_faith/config/build_flags.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1) Community header (calm, static)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Community', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Grow in faith together. More features are coming soon.',
                      style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 2) Primary actions
              const SectionHeader('Get involved', icon: Icons.handshake_outlined),
              _PrimaryActionCard(
                icon: Icons.menu_book_outlined,
                title: 'Reading Plans',
                subtitle: 'Explore guided reading journeys.',
                onTap: () => context.push('/reading-plans'),
              ),
              const SizedBox(height: 12),
              _PrimaryActionCard(
                icon: Icons.extension_outlined,
                title: 'Play & Learn',
                subtitle: 'Games to strengthen your journey.',
                onTap: () => context.push('/play-learn'),
              ),
              const SizedBox(height: 12),
              if (!kIsBetaBuild) ...[
                const SizedBox(height: 12),
                _PrimaryActionCard(
                  icon: Icons.share_outlined,
                  title: 'Share Scripture Quest',
                  subtitle: 'Invite others into the journey.',
                  onTap: () => context.push('/support'),
                ),
              ],

              const SizedBox(height: 24),

              // 3) Coming soon reassurance
              const SectionHeader('What’s ahead', icon: Icons.auto_awesome_outlined),
              SacredCard(
                background: cs.surfaceContainerHigh,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.primary.withValues(alpha: 0.35)),
                      ),
                      child: const Icon(Icons.favorite_border, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('More ways to connect are coming.', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Text(
                            'Community features will unfold over time. Stay tuned.',
                            style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Inspirational closing message (centered, calm)
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Scripture Quest will continue to grow with new features, new ways to learn, and new ways to connect. Thank you for being part of the journey.',
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _PrimaryActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

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
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
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
