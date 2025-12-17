import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/widgets/task_card.dart';
import 'package:level_up_your_faith/models/quest_model.dart';
import 'package:level_up_your_faith/widgets/sacred/sacred_ui.dart';

enum _QuestFilter { today, weekly, reflection, events }

class QuestHubScreen extends StatefulWidget {
  const QuestHubScreen({super.key});

  @override
  State<QuestHubScreen> createState() => _QuestHubScreenState();
}

class _QuestHubScreenState extends State<QuestHubScreen> {
  bool _onboardingChecked = false;
  _QuestFilter _filter = _QuestFilter.today;

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

  String get _todayLabel => _isDaytime() ? 'Today' : 'Tonight';

  /// Determines if a quest is action-oriented (doing/active tasks).
  /// Action quests: scripture_reading, routine, service, community
  bool _isActionQuest(TaskModel q) {
    final qt = q.questType.trim().toLowerCase();
    const actionTypes = {'scripture_reading', 'routine', 'service', 'community'};
    return actionTypes.contains(qt);
  }

  /// Determines if a quest is reflective (inner prompts, journaling, etc.).
  /// Reflection quests: reflection, prayer, journal, gratitude, memorization, memorize
  bool _isReflectionQuest(TaskModel q) {
    final qt = q.questType.trim().toLowerCase();
    final title = q.title.toLowerCase();
    const reflectionTypes = {'reflection', 'prayer', 'journal', 'gratitude', 'memorization', 'memorize'};
    if (reflectionTypes.contains(qt)) return true;
    if (title.contains('journal') || title.contains('gratitude') || 
        title.contains('memorize') || title.contains('forgiveness') ||
        title.contains('prayer reflection')) return true;
    return false;
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
      final List<TaskModel> allReflection = provider.getReflectionTasks();

      final List<TaskModel> timeQuests = _isDaytime() ? daily : nightly;
      final List<TaskModel> actionQuests = timeQuests.where(_isActionQuest).toList();

      final List<TaskModel> reflectionQuests = [
        ...timeQuests.where(_isReflectionQuest),
        ...allReflection.where((q) => !q.isCompleted),
      ].toSet().toList();

      final List<TaskModel> weeklyQuests = provider.quests
          .where((q) => q.isWeekly || q.category == 'weekly' || q.questFrequency == 'weekly')
          .where((q) => !q.isCompleted)
          .toList();

      final List<TaskModel> eventQuests = provider.quests
          .where((q) => q.category == 'event' || q.category == 'seasonal')
          .where((q) => !q.isCompleted)
          .toList();

      List<TaskModel> currentQuests() {
        switch (_filter) {
          case _QuestFilter.today:
            return actionQuests;
          case _QuestFilter.weekly:
            return weeklyQuests;
          case _QuestFilter.reflection:
            return reflectionQuests;
          case _QuestFilter.events:
            return eventQuests;
        }
      }

      String emptyMessage() {
        switch (_filter) {
          case _QuestFilter.today:
            return _isDaytime()
                ? "You've finished your action quests for today!"
                : "You've finished tonight's action quests!";
          case _QuestFilter.weekly:
            return 'No weekly quests available right now.';
          case _QuestFilter.reflection:
            return 'All reflection prompts completed.';
          case _QuestFilter.events:
            return 'No events or seasonal quests active.';
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

      final quests = currentQuests();
      final cs = Theme.of(context).colorScheme;

      // Debug logging for runtime quest metadata verification (debug builds only)
      if (kDebugMode && quests.isNotEmpty) {
        debugPrint('[QuestHub] Rendering ${quests.length} quests (filter: $_filter):');
        for (final q in quests.take(5)) { // Log first 5 to avoid spam
          debugPrint('  -> "${q.title}": type=${q.questType}, targetBook=${q.targetBook ?? "(none)"}, scriptureRef=${q.scriptureReference ?? "(none)"}');
        }
      }

      return Scaffold(
        appBar: AppBar(
          title: Text('Quest Hub', style: Theme.of(context).textTheme.headlineSmall),
          centerTitle: true,
        ),
        body: FadeSlideIn(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeHeader(context),
                      const SizedBox(height: 16),
                      _buildTodaysVerse(context, votdRef, featuredText),
                      const SizedBox(height: 16),
                      _buildContinueReading(context, provider, continueRef),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyFilterDelegate(
                  child: Container(
                    color: cs.surface,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: _buildFilterChips(context),
                  ),
                ),
              ),
            ],
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                if (quests.isEmpty)
                  _buildEmptyState(context, emptyMessage())
                else
                  ...quests.map<Widget>((q) => TaskCard(quest: q)),
                const SizedBox(height: 16),
                _buildQuestsLink(context),
              ],
            ),
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

  Widget _buildFilterChips(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget chip(_QuestFilter filter, String label) {
      final selected = _filter == filter;
      return GestureDetector(
        onTap: () => setState(() => _filter = filter),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? cs.primary.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? cs.primary.withValues(alpha: 0.5) : cs.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip(_QuestFilter.today, _todayLabel),
        chip(_QuestFilter.weekly, 'Weekly'),
        chip(_QuestFilter.reflection, 'Reflection'),
        chip(_QuestFilter.events, 'Events'),
      ],
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

  Widget _buildEmptyState(BuildContext context, String message) {
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

class _StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StickyFilterDelegate({required this.child});

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _StickyFilterDelegate oldDelegate) => false;
}
