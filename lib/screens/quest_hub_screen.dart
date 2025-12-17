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

enum _TaskBoardTab { daily, nightly, reflection }

class _QuestHubScreenState extends State<QuestHubScreen> {
  _TaskBoardTab _selected = _TaskBoardTab.daily;
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
            return "You've finished your Daily Tasks for today. Well done.";
          case _TaskBoardTab.nightly:
            return 'Nightly Tasks unlock later in the day. Keep walking with God.';
          case _TaskBoardTab.reflection:
            return 'All Reflection tasks are completed. You can revisit them anytime in your journey.';
        }
      }

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
              const SectionHeader('Your Tasks', icon: Icons.check_circle_outline),
              const SizedBox(height: 8),
              _buildSegmentedControl(),
              const SizedBox(height: 12),
              if (currentList().isEmpty)
                _buildEmptyState(context, emptyCopy())
              else
                ...currentList().map<Widget>((q) => TaskCard(quest: q)),
              const SizedBox(height: 16),
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
    return SacredCard(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
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
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome Back, Warrior', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  "Let's take one more step today.",
                  style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildSegmentedControl() {
    return SegmentedButton<_TaskBoardTab>(
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
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
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
          EmptyState(message: message),
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
