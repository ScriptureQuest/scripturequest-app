import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/models/questline.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/widgets/home_action_button.dart';
import 'package:level_up_your_faith/widgets/sacred/sacred_ui.dart';
import 'package:level_up_your_faith/widgets/common/status_chip.dart';
import 'package:level_up_your_faith/widgets/common/sacred_linear_progress.dart';

class QuestlinesScreen extends StatefulWidget {
  const QuestlinesScreen({super.key});

  @override
  State<QuestlinesScreen> createState() => _QuestlinesScreenState();
}

class _QuestlinesScreenState extends State<QuestlinesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: GamerColors.accent),
                onPressed: () => context.pop(),
              )
            : null,
        title: Text('Quests', style: Theme.of(context).textTheme.headlineSmall),
        centerTitle: true,
        actions: const [HomeActionButton()],
      ),
      body: Consumer<AppProvider>(builder: (context, app, _) {
        final active = app.activeQuestlines;
        return FutureBuilder<List<Questline>>(
          future: () async {
            final defs = await context.read<AppProvider>().getAvailableQuestlines();
            return defs.where((d) => d.isActive).toList();
          }(),
          builder: (context, snapshot) {
            final defs = snapshot.data ?? const <Questline>[];
            final byCategory = <String, List<Questline>>{};
            for (final d in defs) {
              byCategory.putIfAbsent(d.category, () => <Questline>[]).add(d);
            }
          return FadeSlideIn(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              children: [
                Text('Your spiritual journeys.', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 12),
                if (byCategory['book']?.isNotEmpty == true)
                  _CategorySection(
                    title: 'Book Quests',
                    icon: Icons.menu_book_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    questlines: byCategory['book']!,
                    active: active,
                  ),
                if (byCategory['onboarding']?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  _CategorySection(
                    title: 'Getting Started',
                    icon: Icons.rocket_launch_rounded,
                    color: Theme.of(context).colorScheme.secondary,
                    questlines: byCategory['onboarding']!,
                    active: active,
                  ),
                ],
                if (byCategory['seasonal']?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  _CategorySection(
                    title: 'Themed Journeys',
                    icon: Icons.auto_awesome_rounded,
                    color: Theme.of(context).colorScheme.tertiary,
                    questlines: byCategory['seasonal']!,
                    active: active,
                  ),
                ],
                if (byCategory['streak']?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  _CategorySection(
                    title: 'Streak Paths',
                    icon: Icons.local_fire_department_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    questlines: byCategory['streak']!,
                    active: active,
                  ),
                ],
              ],
            ));
          },
        );
      }),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Questline> questlines;
  final List<QuestlineProgressView> active;

  const _CategorySection({
    required this.title,
    required this.icon,
    required this.color,
    required this.questlines,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
        return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title, icon: icon),
        const SizedBox(height: 10),
        ...questlines.map((ql) {
          final view = active.where((v) => v.questline.id == ql.id).toList().firstOrNull;
              final isCompleted = view?.progress.isCompleted == true;
              final isActive = view != null && !isCompleted;
              final completedSteps = view?.completedSteps ?? 0;
              final totalSteps = view?.totalSteps ?? ql.steps.length;
              final ratio = totalSteps == 0 ? 0.0 : (completedSteps / totalSteps).clamp(0.0, 1.0);
              final progressLabel = 'Step ${isCompleted ? totalSteps : (completedSteps + (isActive ? 1 : 0)).clamp(0, totalSteps)} of $totalSteps';
              final statusLabel = isCompleted
                  ? 'Completed'
                  : isActive
                      ? 'In Progress'
                      : 'Not Started';
              final statusIcon = isCompleted
                  ? Icons.check_rounded
                  : isActive
                      ? Icons.play_arrow_rounded
                      : Icons.flag_rounded;
          return SacredCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                        Icon(icon, color: color, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(ql.title, style: Theme.of(context).textTheme.titleMedium)),
                        StatusChip(label: statusLabel, icon: statusIcon),
                  ],
                ),
                const SizedBox(height: 6),
                    Text(
                      ql.description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    SacredLinearProgress(value: ratio, minHeight: 6, fillColor: color),
                    const SizedBox(height: 6),
                    Text(progressLabel, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 10),
                if ((ql.themeTag ?? '').trim().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25), width: 1),
                    ),
                    child: Text(ql.themeTag!, style: Theme.of(context).textTheme.labelSmall),
                  ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(isActive ? Icons.play_arrow_rounded : Icons.auto_awesome_rounded, color: Theme.of(context).colorScheme.primary),
                       label: Text(isActive ? 'Continue' : 'Start Quest'),
                      onPressed: () async {
                        if (isActive) {
                           if (context.mounted) context.push('/quest/${ql.id}');
                        } else {
                          final provider = context.read<AppProvider>();
                          await provider.enrollInQuestline(ql.id);
                           if (context.mounted) context.push('/quest/${ql.id}');
                        }
                      },
                    ),
                  ),
                ]),
              ],
            ),
          );
        }),
      ],
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
