import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/services/bible_service.dart';
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
  String? _votdText;
  String _lastVotdRef = '';

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

  void _triggerVotdLoad(String votdRef) {
    if (votdRef.isEmpty || votdRef == _lastVotdRef) return;
    _lastVotdRef = votdRef;
    
    BibleService.instance.getVerseText(votdRef).then((text) {
      if (mounted && text != null) {
        setState(() => _votdText = text);
      }
      if (kDebugMode) {
        debugPrint('[QuestHub] VOTD lookup: ref="$votdRef", text=${text != null ? "found (${text.length} chars)" : "NOT FOUND"}');
      }
    });
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
      /// Helper to check if quest belongs to weekly category
      bool isWeeklyQuest(TaskModel q) =>
          q.isWeekly || q.category == 'weekly' || q.questFrequency == 'weekly';
      
      /// Helper to check if quest belongs to event/seasonal category
      bool isEventQuest(TaskModel q) =>
          q.category == 'event' || q.category == 'seasonal';
      
      // Exclude weekly/event quests from today/tonight action list to prevent overlap
      final List<TaskModel> actionQuests = timeQuests
          .where(_isActionQuest)
          .where((q) => !isWeeklyQuest(q) && !isEventQuest(q))
          .toList();

      // Exclude weekly/event quests from reflection list to prevent overlap
      final List<TaskModel> reflectionQuests = [
        ...timeQuests.where(_isReflectionQuest)
            .where((q) => !isWeeklyQuest(q) && !isEventQuest(q)),
        ...allReflection.where((q) => !q.isCompleted)
            .where((q) => !isWeeklyQuest(q) && !isEventQuest(q)),
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
        // Debug logging: print counts for each filter list when filter changes (debug builds only)
        if (kDebugMode) {
          debugPrint('[QuestHub] Filter counts: todayAction=${actionQuests.length}, weekly=${weeklyQuests.length}, reflection=${reflectionQuests.length}, events=${eventQuests.length}');
          debugPrint('[QuestHub] Selected filter: $_filter');
        }
        
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
            return "You're done for now. Check back later.";
          case _QuestFilter.weekly:
            return 'No weekly quests right now.';
          case _QuestFilter.reflection:
            return 'No reflection prompts right now.';
          case _QuestFilter.events:
            return 'No events active right now.';
        }
      }

      // Today's Verse: Single source of truth for reference + text
      final votdRef = provider.getVerseOfTheDay();
      // Trigger async VOTD text lookup (will setState when complete)
      _triggerVotdLoad(votdRef);
      // Use state-managed VOTD text (loaded via BibleService)
      // Defensive: If no matching text found, show safe placeholder (never mismatched text)
      final featuredText = _votdText ?? 'Tap to read this verse';

      // Continue Reading: separate source (last-read reference, fallback to VOTD)
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
          child: RefreshIndicator(
            onRefresh: () async {
              // Re-read quests and state from provider (no regeneration)
              await Future.delayed(const Duration(milliseconds: 350));
              if (mounted) {
                // Force re-read of VOTD text
                _lastVotdRef = '';
                _triggerVotdLoad(votdRef);
                setState(() {});
              }
            },
            color: cs.primary,
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
                        const SizedBox(height: 16),
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
        ),
      );
    });
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final provider = context.watch<AppProvider>();
    final streak = provider.currentBibleStreak;
    final userName = (provider.currentUser?.username ?? '').trim();
    final displayName = userName.isNotEmpty ? userName : 'Warrior';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Welcome, '),
                  TextSpan(
                    text: displayName,
                    style: TextStyle(color: cs.primary),
                  ),
                ],
              ),
              style: theme.textTheme.headlineSmall,
            ),
            if (streak >= 1)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department, color: Colors.orange, size: 22),
                  const SizedBox(width: 4),
                  Text(
                    '$streak',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "Today's path is simple. Stay faithful in small steps.",
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget chip(_QuestFilter filter, String label) {
      final selected = _filter == filter;
      return GestureDetector(
        onTap: () {
          if (_filter != filter) {
            HapticFeedback.selectionClick();
            setState(() => _filter = filter);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          constraints: const BoxConstraints(minHeight: 40),
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

  Widget _buildTodaysVerse(BuildContext context, String reference, String? text) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLoading = text == null;
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          final focus = _extractVerseNumber(reference);
          final uri = Uri(path: '/verses', queryParameters: {
            'ref': reference,
            if (focus != null) 'focus': '$focus',
          });
          context.go(uri.toString());
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
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
              if (isLoading)
                Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Loading verse...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  text,
                  style: theme.textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
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
