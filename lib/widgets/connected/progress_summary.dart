import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/widgets/reading_v2/reading_design.dart';
import 'journey_content.dart';

class ProgressSummary extends StatelessWidget {
  const ProgressSummary({super.key});
  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppProvider>().currentUser;
    if (u == null) return const SizedBox.shrink();
    return Semantics(
        label:
            'Level ${u.currentLevel}, ${u.currentXP} of ${u.xpToNextLevel} XP toward next level',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 24,
              runSpacing: 4,
              children: [
                Text('Level ${u.currentLevel}',
                    style: Theme.of(context).textTheme.titleMedium),
                Text('${u.currentXP} / ${u.xpToNextLevel} XP'),
                Text('${u.totalXP} XP earned'),
              ]),
          const SizedBox(height: 10),
          LinearProgressIndicator(
              value: u.xpProgress.clamp(0.0, 1.0),
              minHeight: 6,
              borderRadius: BorderRadius.circular(8)),
        ]));
  }
}

class TodayJourney extends StatelessWidget {
  const TodayJourney({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final journey = app.focusedJourney;
    final step = journey?.currentStep;
    final ref = JourneyContent.reference(step);
    final theme = Theme.of(context);
    return ReadingSurface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(journey == null ? 'YOUR SCRIPTURE QUEST' : 'YOUR CURRENT JOURNEY',
          style: theme.textTheme.labelMedium),
      const SizedBox(height: 12),
      Text(journey?.questline.title ?? 'Start somewhere meaningful.',
          style: theme.textTheme.headlineMedium),
      const SizedBox(height: 8),
      Text(journey == null
          ? 'Choose a short guided Journey, or read freely. Your exploration and accomplishments stay with you.'
          : JourneyContent.purposes[journey.questline.id] ??
              journey.questline.description),
      if (journey != null) ...[
        const SizedBox(height: 18),
        LinearProgressIndicator(value: journey.completionRatio, minHeight: 5),
        const SizedBox(height: 8),
        Text(
            '${journey.completedSteps} of ${journey.totalSteps} steps · Continue at your pace'),
        const SizedBox(height: 14),
        Text(ref ?? 'An optional moment to reflect',
            style: theme.textTheme.titleLarge),
      ],
      const SizedBox(height: 18),
      SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.route_outlined),
            label: Text(
                journey == null ? 'Choose my Journey' : 'Continue Journey'),
            onPressed: () => context.push(journey == null
                ? '/journeys'
                : '/journeys/${journey.questline.id}'),
          )),
      if (app.activeReadingPlan != null)
        TextButton.icon(
            onPressed: () => context.push('/reading-plans'),
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(
                'Reading plan · ${(app.getPlanProgressPercent() * 100).round()}% complete')),
    ]));
  }
}
