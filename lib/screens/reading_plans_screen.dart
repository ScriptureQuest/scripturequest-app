import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/models/reading_plan.dart';
import 'package:level_up_your_faith/services/reading_plan_service.dart';
import 'package:level_up_your_faith/widgets/home_action_button.dart';
import 'package:level_up_your_faith/widgets/sacred/sacred_ui.dart';
import 'package:level_up_your_faith/widgets/common/status_chip.dart';
import 'package:level_up_your_faith/widgets/common/sacred_linear_progress.dart';

class ReadingPlansScreen extends StatelessWidget {
  const ReadingPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, app, _) {
      final active = app.activeReadingPlan;
      final seeds = ReadingPlanService.getSeeds();
      final others = seeds.where((p) => p.planId != active?.planId).toList();

      return Scaffold(
        appBar: AppBar(
          title: Text('Reading Plans', style: Theme.of(context).textTheme.headlineSmall),
          centerTitle: true,
          actions: const [HomeActionButton()],
        ),
        body: FadeSlideIn(
          child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          children: [
            if (active != null) ...[
              const SectionHeader('Your Plan', icon: Icons.auto_stories_rounded),
              const SizedBox(height: 12),
              _ActivePlanCard(plan: active),
              const SizedBox(height: 24),
              const SectionHeader('All Plans', icon: Icons.menu_book_rounded),
              const SizedBox(height: 12),
            ] else ...[
              const SectionHeader('Choose a Plan', icon: Icons.menu_book_rounded),
              const SizedBox(height: 12),
            ],
            for (final p in others) _PlanSeedCard(plan: p),
            if (others.isEmpty && active != null)
              SacredCard(
                child: Text('You have started the available plan. More plans will arrive soon.', style: Theme.of(context).textTheme.bodyMedium),
              ),
          ],
        ),
        ),
      );
    });
  }
}

class _PlanSeedCard extends StatelessWidget {
  final ReadingPlan plan;
  const _PlanSeedCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return SacredCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(plan.title, style: theme.textTheme.titleMedium)),
              const StatusChip(label: 'Not Started', icon: Icons.flag_rounded),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            plan.subtitle,
            style: theme.textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          SacredLinearProgress(value: 0),
          const SizedBox(height: 6),
          Text('Day 0 of ${plan.totalDays}', style: theme.textTheme.labelSmall),
          const SizedBox(height: 10),
          Row(
            children: [
              _Chip(text: '${plan.totalDays} days', icon: Icons.calendar_today),
              const SizedBox(width: 8),
              _Chip(text: 'Gentle pace', icon: Icons.self_improvement_rounded),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await app.activatePlan(plan.planId);
                  if (context.mounted) context.pop();
                },
                icon: Icon(Icons.play_circle_fill_rounded, color: cs.onPrimary),
                label: const Text('Start Plan'),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () {},
                child: const Text('Details'),
              )
            ],
          )
        ],
      ),
    );
  }
}

class _ActivePlanCard extends StatelessWidget {
  final ReadingPlan plan;
  const _ActivePlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, app, _) {
      final theme = Theme.of(context);
      final cs = theme.colorScheme;
      final pct = app.getPlanProgressPercent();
      final step = app.getCurrentPlanStep();
      final completed = step == null;
      String todayShortLabel = completed ? 'All readings complete' : _todayLabel(step);
      final daysDone = plan.days.where((s) => app.isPlanStepCompleted(plan, s.stepIndex)).length;
      final percentText = '${(pct * 100).round()}%';
      final currentDay = completed ? plan.totalDays : (daysDone + 1).clamp(1, plan.totalDays);
      final daysLabel = 'Day $currentDay of ${plan.totalDays}';

      return SacredCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_stories_rounded, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(plan.title, style: theme.textTheme.titleLarge)),
                Text(percentText, style: theme.textTheme.labelMedium),
              ],
            ),
            const SizedBox(height: 10),
            Text(plan.subtitle, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 10),
            SacredLinearProgress(value: pct, minHeight: 10),
            const SizedBox(height: 6),
            Text(daysLabel, style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: Text('Today: $todayShortLabel', style: theme.textTheme.bodyMedium)),
                if (completed) Icon(Icons.check_circle_rounded, color: cs.primary, size: 18),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: completed
                      ? null
                      : () {
                          final ref = app.getFirstUnreadReferenceForCurrentStep();
                          if (ref != null) {
                            final encoded = Uri.encodeComponent(ref);
                            context.go('/verses?ref=$encoded');
                          }
                        },
                  icon: Icon(Icons.play_arrow_rounded, color: cs.onPrimary),
                  label: const Text("Continue Today's Reading"),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    await app.clearActivePlan();
                  },
                  child: const Text('Clear Plan'),
                )
              ],
            ),
            const SizedBox(height: 12),
            _StepsList(plan: plan, maxItems: 10),
          ],
        ),
      );
    });
  }

  // Build a concise label like "John 3–4" or "Matthew 1, Mark 1"
  String _todayLabel(ReadingPlanStep step) {
    try {
      if (step.referenceList.isEmpty) return '(Rest)';
      final refs = step.referenceList;
      final first = refs.first;
      final last = refs.last;
      String bookA = first.split(' ').first;
      String bookB = last.split(' ').first;
      int? chA = int.tryParse(first.split(' ').last);
      int? chB = int.tryParse(last.split(' ').last);
      if (bookA == bookB && chA != null && chB != null && refs.length > 1) {
        return '$bookA $chA–$chB';
      }
      if (refs.length == 1) return refs.first;
      return refs.take(2).join(', ');
    } catch (_) {
      return step.friendlyLabel;
    }
  }
}

class _StepsList extends StatelessWidget {
  final ReadingPlan plan;
  final int maxItems;
  const _StepsList({required this.plan, this.maxItems = 10});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, app, _) {
      final cs = Theme.of(context).colorScheme;
      final doneSet = plan.days.map((s) => app.isPlanStepCompleted(plan, s.stepIndex) ? s.stepIndex : -1).where((i) => i >= 0).toSet();
      final items = plan.days.take(maxItems).toList();
      final current = app.getCurrentPlanStep()?.stepIndex;
      return Column(
        children: [
          for (final step in items)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: current == step.stepIndex ? cs.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: current == step.stepIndex
                    ? Border.all(color: cs.primary, width: 1)
                    : Border.all(color: Colors.transparent, width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    doneSet.contains(step.stepIndex) ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                    color: doneSet.contains(step.stepIndex) ? cs.primary : cs.outline,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Opacity(
                      opacity: doneSet.contains(step.stepIndex) ? 0.72 : 1.0,
                      child: Text(step.friendlyLabel, style: Theme.of(context).textTheme.labelMedium),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final IconData icon;
  const _Chip({required this.text, required this.icon});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
