import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/widgets/sacred/sacred_ui.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/models/questline.dart';
// (No quest model needed for the lightweight progress glance)
// NOTE: Journey Board is currently not exposed in the UI. Kept for potential future use.

class JourneyBoardScreen extends StatelessWidget {
  const JourneyBoardScreen({super.key});

  // Removed heavy breakdown helpers to keep Board as a calm glance.

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer<AppProvider>(builder: (context, app, _) {
      final totalChaptersRead = app.totalChaptersRead; // may be used for empty state

      return Scaffold(
        appBar: AppBar(
          title: const Text('Journey Board'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              // Header + subtitle
              Text('Journey Board', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                'See the paths you’re walking right now.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),

              const SizedBox(height: 18),

              // Your current journey glance
              FutureBuilder<Map<String, int>>(
                future: app.getUserStats(),
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const SizedBox(height: 64, child: Center(child: CircularProgressIndicator()));
                  }
                  final stats = snap.data ?? const <String, int>{};
                  final chapters = stats['totalChaptersCompleted'] ?? 0;
                  final qSteps = stats['questStepsCompleted'] ?? 0;
                  final quizzes = stats['totalQuizzesCompleted'] ?? 0;
                  final summary = "You’ve completed $chapters chapters and $qSteps quest steps so far. Keep going!";
                  return FadeSlideIn(
                    child: SacredCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [Icon(Icons.flag_rounded, color: cs.primary), const SizedBox(width: 8), Text('Your current journey', style: Theme.of(context).textTheme.titleMedium)]),
                          const SizedBox(height: 8),
                          Text(summary, style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.menu_book_outlined, color: cs.primary, size: 18),
                              const SizedBox(width: 6),
                              Text('Chapters so far: $chapters', style: Theme.of(context).textTheme.labelMedium),
                              const SizedBox(width: 14),
                              Icon(Icons.fact_check_outlined, color: cs.primary, size: 18),
                              const SizedBox(width: 6),
                              Text('Quizzes: $quizzes', style: Theme.of(context).textTheme.labelMedium),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              const SectionHeader('Active quests', icon: Icons.explore_rounded),
              const SizedBox(height: 8),

              Builder(
                builder: (context) {
                  final views = app.activeQuestlines;
                  if (views.isEmpty) {
                    return FadeSlideIn(
                      child: SacredCard(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.explore_outlined, color: cs.onSurfaceVariant, size: 40),
                            const SizedBox(height: 10),
                            Text('No active quests yet.', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 6),
                            Text(
                              'You can start a quest from Tasks, Reading Plans, or other guided journeys.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              icon: Icon(Icons.menu_book_rounded, color: cs.primary),
                              label: const Text('Browse quests'),
                              onPressed: () => context.push('/quests'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final v in views)
                        FadeSlideIn(
                          child: _ActiveQuestCard(view: v),
                        ),
                    ],
                  );
                },
              ),

              // Optional: Completed section (header only when we have any completed flag)
              if (app.hasCompletedAnyQuestline) ...[
                const SizedBox(height: 28),
                const SectionHeader('Completed quests', icon: Icons.check_circle_outline_rounded),
                const SizedBox(height: 8),
                // Calm placeholder; full list is optional and may be added later when we surface completed data
                SacredCard(
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events_rounded, color: cs.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your completed quests will appear here. Keep going! ✨',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),
              if (totalChaptersRead == 0)
                const EmptyState(message: 'Keep reading and your journey will begin to bloom.'),
            ],
          ),
        ),
      );
    });
  }
}


// =============== Active Quest Card ===============
class _ActiveQuestCard extends StatelessWidget {
  final QuestlineProgressView view;
  const _ActiveQuestCard({required this.view});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ql = view.questline;
    final progress = view.progress;
    final ordered = [...ql.steps]..sort((a, b) => a.order.compareTo(b.order));
    final activeId = progress.activeStepIds.isEmpty ? null : progress.activeStepIds.first;
    final completed = view.completedSteps;
    final total = view.totalSteps;
    final pct = view.completionRatio;
    int stepIndex = 0;
    if (activeId != null) {
      final idx = ordered.indexWhere((e) => e.id == activeId);
      stepIndex = (idx >= 0 ? idx : 0) + 1; // 1-based for display
    } else {
      // Fallback: next step is completed + 1 (still 1-based)
      stepIndex = (completed + 1).clamp(1, total);
    }

    String subtitle = ql.description.trim().isNotEmpty ? ql.description.trim() : _subtitleForCategory(ql.category, ql.themeTag);
    if (subtitle.length > 64) subtitle = subtitle.substring(0, 64).trimRight() + '…';

    final nearingEnd = total > 0 && (completed >= total - 1) && !progress.isCompleted;
    final bottomLeftText = progress.isCompleted
        ? 'Completed'
        : (completed == 0 ? 'Not started yet.' : (nearingEnd ? 'Almost complete.' : 'You’re currently on Step $stepIndex.'));

    final pillBg = cs.primary.withValues(alpha: 0.12);
    final pillText = cs.primary;

    return SacredCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconForQuestline(ql.iconKey, ql.category), color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ql.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
                ),
                child: Text('Step $stepIndex of $total', style: theme.textTheme.labelSmall?.copyWith(color: pillText, fontWeight: FontWeight.w600)),
              ),
            ],
          ),

          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Builder(builder: (context) {
              final purple = Theme.of(context).extension<PurpleUi>();
              if (purple == null) {
                return LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  backgroundColor: cs.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                );
              }
              return LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: purple.progressTrack,
                valueColor: AlwaysStoppedAnimation<Color>(purple.progressFill),
              );
            }),
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  bottomLeftText,
                  style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => context.push('/quest/${ql.id}'),
                child: Text(completed == 0 ? 'Begin' : 'Continue'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _subtitleForCategory(String category, String? tag) {
    switch (category) {
      case 'book':
        return 'A guided journey through Scripture.';
      case 'onboarding':
        return 'Start your gentle first steps.';
      case 'seasonal':
        return tag != null && tag.trim().isNotEmpty ? tag : 'A themed, calm walk.';
      case 'streak':
        return 'Keep a kind rhythm over days.';
      default:
        return 'A gentle path forward.';
    }
  }

  IconData _iconForQuestline(String? iconKey, String category) {
    final k = (iconKey ?? '').toLowerCase().trim();
    switch (k) {
      case 'rocket':
        return Icons.rocket_launch_rounded;
      case 'book':
        return Icons.menu_book_rounded;
      case 'peace':
        return Icons.self_improvement_rounded;
      case 'christ':
        return Icons.favorite_rounded; // gentle faith symbol
      case 'star':
        return Icons.star_rounded;
      default:
        // Category-based fallback
        switch (category) {
          case 'book':
            return Icons.menu_book_rounded;
          case 'onboarding':
            return Icons.flag_rounded;
          case 'seasonal':
            return Icons.eco_rounded;
          case 'streak':
            return Icons.local_fire_department_rounded;
          default:
            return Icons.explore_rounded;
        }
    }
  }
}
