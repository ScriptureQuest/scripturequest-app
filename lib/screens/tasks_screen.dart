import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/widgets/task_card.dart';
import 'package:level_up_your_faith/widgets/home_action_button.dart';
import 'package:level_up_your_faith/models/quest_model.dart';
import 'package:level_up_your_faith/widgets/sacred/sacred_ui.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

enum _TaskBoardTab { daily, nightly, reflection }

class _TasksScreenState extends State<TasksScreen> {
  _TaskBoardTab _selected = _TaskBoardTab.daily;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, provider, _) {
      final List<TaskModel> daily = provider.getDailyTasksForToday();
      final List<TaskModel> nightly = provider.getNightlyTasksForToday();
      final List<TaskModel> reflection = provider.getReflectionTasks();

      List<TaskModel> currentList() {
        switch (_selected) {
          case _TaskBoardTab.daily:
            return daily;
          case _TaskBoardTab.nightly:
            return nightly;
          case _TaskBoardTab.reflection:
            return reflection;
        }
      }

      String emptyCopy() {
        switch (_selected) {
          case _TaskBoardTab.daily:
            return 'You’ve finished your Daily Tasks for today. Well done.';
          case _TaskBoardTab.nightly:
            return 'Nightly Tasks unlock later in the day. Keep walking with God.';
          case _TaskBoardTab.reflection:
            return 'All Reflection tasks are completed. You can revisit them anytime in your journey.';
        }
      }

      return Scaffold(
        appBar: AppBar(
          title: Text('Task Board', style: Theme.of(context).textTheme.headlineSmall),
          centerTitle: true,
          actions: const [HomeActionButton()],
        ),
        body: FadeSlideIn(
          child: ListView(
          children: [
            // Reading Plan entry (compact, non-intrusive)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader('Reading Plan', icon: Icons.auto_stories_rounded),
                  const SizedBox(height: 8),
                  _ReadingPlanEntryCard(),
                ],
              ),
            ),
            // Segmented control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SegmentedButton<_TaskBoardTab>(
                segments: const <ButtonSegment<_TaskBoardTab>>[
                  ButtonSegment(label: Text('Daily'), value: _TaskBoardTab.daily, icon: Icon(Icons.wb_sunny_rounded)),
                  ButtonSegment(label: Text('Nightly'), value: _TaskBoardTab.nightly, icon: Icon(Icons.nights_stay_rounded)),
                  ButtonSegment(label: Text('Reflection'), value: _TaskBoardTab.reflection, icon: Icon(Icons.psychology_alt_rounded)),
                ],
                selected: <_TaskBoardTab>{_selected},
                onSelectionChanged: (s) {
                  setState(() => _selected = s.first);
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (currentList().isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Icon(
                      _selected == _TaskBoardTab.daily
                          ? Icons.wb_sunny_rounded
                          : _selected == _TaskBoardTab.nightly
                              ? Icons.nights_stay_rounded
                              : Icons.psychology_alt_rounded,
                      color: Theme.of(context).colorScheme.outline,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    EmptyState(message: emptyCopy()),
                  ],
                ),
              )
            else ...currentList().map<Widget>((q) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TaskCard(quest: q),
                )),
            const SizedBox(height: 16),
          ],
        ),
        ),
      );
    });
  }
}

class _ReadingPlanEntryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, app, _) {
      final plan = app.activeReadingPlan;
      final hasActive = plan != null;
      final pct = hasActive ? app.getPlanProgressPercent() : 0.0;
      final step = hasActive ? app.getCurrentPlanStep() : null;
      final subtitle = hasActive
          ? plan!.title
          : 'Gentle guidance for your daily rhythm';
      final helper = hasActive
          ? (step == null ? 'Completed' : step.friendlyLabel)
          : null;

      void openPlans() => context.push('/reading-plans');

      return SacredCard(
        onTap: openPlans,
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                hasActive ? Icons.auto_stories_rounded : Icons.flag_circle_rounded,
                color: hasActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            hasActive ? 'Your Reading Plan' : 'Start a Reading Plan',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (hasActive)
                          Text(
                            '${(pct * 100).round()}%',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    if (helper != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        helper,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: openPlans,
                          icon: Icon(Icons.menu_book_rounded, color: Theme.of(context).colorScheme.onPrimary),
                          label: Text(hasActive ? 'View Plan' : 'Browse Plans'),
                        ),
                        const SizedBox(width: 8),
                        if (hasActive)
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 6,
                                backgroundColor: Theme.of(context).colorScheme.surface,
                                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
      );
    });
  }
}
