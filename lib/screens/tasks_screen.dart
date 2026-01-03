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

class _TasksScreenState extends State<TasksScreen> {

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, provider, _) {
      final List<TaskModel> daily = provider.getDailyTasksForToday();
      final List<TaskModel> nightly = provider.getNightlyTasksForToday();

      final hour = DateTime.now().hour;
      final isDaytime = hour >= 6 && hour < 18;
      final activeQuests = isDaytime ? daily : nightly;
      final questLabel = isDaytime ? 'Daily Quests' : 'Nightly Quests';
      final questIcon = isDaytime ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded;

      return Scaffold(
        appBar: AppBar(
          title: Text('Quest Hub', style: Theme.of(context).textTheme.headlineSmall),
          centerTitle: true,
          actions: const [HomeActionButton()],
        ),
        body: FadeSlideIn(
          child: ListView(
          children: [
            _TasksHeader(provider: provider),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(questIcon, color: Theme.of(context).colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(questLabel, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (activeQuests.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Icon(questIcon, color: Theme.of(context).colorScheme.outline, size: 40),
                    const SizedBox(height: 12),
                    EmptyState(message: isDaytime ? 'You\'ve finished your Daily Quests for today. Well done.' : 'You\'ve finished your Nightly Quests for today. Well done.'),
                  ],
                ),
              )
            else ...activeQuests.map<Widget>((q) => Padding(
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

class _TasksHeader extends StatelessWidget {
  final AppProvider provider;

  const _TasksHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    final user = provider.currentUser;
    final userName = user?.username ?? 'Friend';
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: theme.textTheme.titleLarge,
              children: [
                const TextSpan(text: 'Welcome, '),
                TextSpan(
                  text: userName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _TodaysVerseCard(provider: provider),
          const SizedBox(height: 12),
          _ContinueReadingCard(provider: provider),
        ],
      ),
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  final AppProvider provider;

  const _ContinueReadingCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final votdRef = provider.getVerseOfTheDay();
    final last = (provider.lastBibleReference ?? '').trim();
    final ref = last.isNotEmpty ? last : votdRef.isNotEmpty ? votdRef : 'John 1';

    String friendlyTitle(String r) {
      try {
        if (r.contains(':')) {
          return r.split(':').first;
        }
        return r;
      } catch (_) {
        return r;
      }
    }

    final title = friendlyTitle(ref);

    return SacredCard(
      onTap: () {
        final encoded = Uri.encodeComponent(ref);
        context.go('/verses?ref=$encoded');
      },
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.primary.withValues(alpha: 0.35)),
            ),
            child: Icon(Icons.menu_book_rounded, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Continue in $title',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  'Pick up where you left off',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 20),
        ],
      ),
    );
  }
}

class _TodaysVerseCard extends StatelessWidget {
  final AppProvider provider;

  const _TodaysVerseCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final votdRef = provider.getVerseOfTheDay();
    String featuredText = 'For God so loved the world...';

    if (provider.verses.isNotEmpty) {
      try {
        final verse = provider.verses.firstWhere((v) => v.reference == votdRef);
        featuredText = verse.text.isNotEmpty ? verse.text : featuredText;
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: cs.secondary, size: 16),
              const SizedBox(width: 6),
              Text(
                "Today's Verse",
                style: theme.textTheme.labelLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            featuredText,
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: cs.onSurface.withValues(alpha: 0.75),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            votdRef,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.primary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
