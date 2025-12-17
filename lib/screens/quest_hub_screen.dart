import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/widgets/task_card.dart';
import 'package:level_up_your_faith/models/quest_model.dart';
import 'package:level_up_your_faith/widgets/sacred/sacred_ui.dart';

class QuestHubScreen extends StatefulWidget {
  const QuestHubScreen({super.key});

  @override
  State<QuestHubScreen> createState() => _QuestHubScreenState();
}

class _QuestHubScreenState extends State<QuestHubScreen> {
  bool _onboardingChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_onboardingChecked) {
      final provider = Provider.of<AppProvider?>(context, listen: false);
      if (provider != null && provider.isInitialized && provider.shouldShowOnboarding) {
        _onboardingChecked = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/onboarding');
        });
      }
    }
  }

  bool _isDaytime() {
    final hour = DateTime.now().hour;
    return hour >= 6 && hour < 18;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, provider, _) {
      if (provider.isLoading) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: GamerColors.accent)),
        );
      }

      final user = provider.currentUser;
      if (user == null) {
        return const Scaffold(body: Center(child: Text('Error loading user')));
      }

      final List<TaskModel> daily = provider.getDailyTasksForToday();
      final List<TaskModel> nightly = provider.getNightlyTasksForToday();
      final List<TaskModel> reflection = provider.getReflectionTasks();

      final List<TaskModel> todayQuests = _isDaytime() ? daily : nightly;
      final String todayLabel = _isDaytime() ? 'Today' : 'Tonight';

      final List<TaskModel> weeklyQuests = provider.quests
          .where((q) => q.isWeekly || q.category == 'weekly' || q.questFrequency == 'weekly')
          .where((q) => !q.isCompleted)
          .toList();

      final List<TaskModel> eventQuests = provider.quests
          .where((q) => q.category == 'event' || q.category == 'seasonal')
          .where((q) => !q.isCompleted)
          .toList();

      final votdRef = provider.getVerseOfTheDay();
      String featuredText = 'For God so loved the world that he gave his one and only Son...';
      if (provider.verses.isNotEmpty) {
        try {
          final verse = provider.verses.firstWhere((v) => v.reference == votdRef);
          featuredText = verse.text.isNotEmpty ? verse.text : featuredText;
        } catch (_) {}
      }

      final last = (provider.lastBibleReference ?? '').trim();
      final continueRef = last.isNotEmpty ? last : (votdRef.isNotEmpty ? votdRef : 'John 1');

      return Scaffold(
        appBar: AppBar(
          title: Text('Quest Hub', style: Theme.of(context).textTheme.headlineSmall),
          centerTitle: true,
        ),
        body: FadeSlideIn(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _buildWelcomeHeader(context),
              const SizedBox(height: 16),
              _buildTodaysVerse(context, votdRef, featuredText),
              const SizedBox(height: 16),
              _buildContinueReading(context, provider, continueRef),
              const SizedBox(height: 24),
              if (todayQuests.isNotEmpty) ...[
                _buildSectionHeader(context, todayLabel),
                const SizedBox(height: 8),
                ...todayQuests.map<Widget>((q) => TaskCard(quest: q)),
                const SizedBox(height: 16),
              ],
              if (reflection.isNotEmpty) ...[
                _buildSectionHeader(context, 'Reflection'),
                const SizedBox(height: 8),
                ...reflection.map<Widget>((q) => TaskCard(quest: q)),
                const SizedBox(height: 16),
              ],
              if (weeklyQuests.isNotEmpty) ...[
                _buildSectionHeader(context, 'This Week'),
                const SizedBox(height: 8),
                ...weeklyQuests.map<Widget>((q) => TaskCard(quest: q)),
                const SizedBox(height: 16),
              ],
              if (eventQuests.isNotEmpty) ...[
                _buildSectionHeader(context, 'Seasonal / Events'),
                const SizedBox(height: 8),
                ...eventQuests.map<Widget>((q) => TaskCard(quest: q)),
                const SizedBox(height: 16),
              ],
              if (todayQuests.isEmpty && reflection.isEmpty && weeklyQuests.isEmpty && eventQuests.isEmpty)
                _buildEmptyState(context),
              _buildQuestsLink(context),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'Welcome, '),
          TextSpan(
            text: 'Warrior',
            style: TextStyle(color: cs.primary),
          ),
        ],
      ),
      style: theme.textTheme.headlineSmall,
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }

  Widget _buildTodaysVerse(BuildContext context, String reference, String text) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return GestureDetector(
      onTap: () {
        final focus = _extractVerseNumber(reference);
        final uri = Uri(path: '/verses', queryParameters: {
          'ref': reference,
          if (focus != null) 'focus': '$focus',
        });
        context.go(uri.toString());
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withValues(alpha: 0.15), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's Verse", style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            Text(reference, style: theme.textTheme.titleMedium?.copyWith(color: GamerColors.neonCyan)),
            const SizedBox(height: 10),
            Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  int? _extractVerseNumber(String reference) {
    try {
      final m = RegExp(r':(\d+)').firstMatch(reference);
      if (m != null) return int.tryParse(m.group(1) ?? '');
      return null;
    } catch (_) {
      return null;
    }
  }

  Widget _buildContinueReading(BuildContext context, AppProvider app, String ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    String friendlyTitle(String r) {
      try {
        if (r.contains(':')) {
          final base = r.split(':').first;
          return base;
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.primary.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.menu_book, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Continue in $title', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Tap to return to your last reading spot.',
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

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Theme.of(context).colorScheme.outline,
            size: 40,
          ),
          const SizedBox(height: 12),
          EmptyState(message: "You're all caught up. Well done!"),
        ],
      ),
    );
  }

  Widget _buildQuestsLink(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return SacredCard(
      onTap: () => context.push('/quests'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.primary.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.explore_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Guided Quests', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Follow longer journeys through Scripture.',
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
