import '../widgets/sessions/primary_session_card.dart';
import '../widgets/sessions/startup_gate.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:level_up_your_faith/widgets/connected/progress_summary.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/services/bible_service.dart';
import 'package:level_up_your_faith/widgets/task_card.dart';
import 'package:level_up_your_faith/models/quest_model.dart';

enum _QuestFilter { reflection, events }

class QuestHubScreen extends StatefulWidget {
  const QuestHubScreen({super.key});

  @override
  State<QuestHubScreen> createState() => _QuestHubScreenState();
}

class _QuestHubScreenState extends State<QuestHubScreen>
    with WidgetsBindingObserver {
  bool _onboardingChecked = false;
  _QuestFilter _filter = _QuestFilter.reflection;
  String? _votdText;
  String _lastVotdRef = '';
  bool _votdLoadAttempted = false;

  DateTime _visibleDay = DateTime.now();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    final now = DateTime.now();
    final changedDay = _visibleDay.year != now.year ||
        _visibleDay.month != now.month ||
        _visibleDay.day != now.day;
    _visibleDay = now;
    final app = context.read<AppProvider>();
    if (changedDay && app.isInitialized) app.checkDailyTasks();
    setState(
        () {}); // Refresh stopping guidance even without a progression event.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_onboardingChecked) {
      final provider = Provider.of<AppProvider?>(context, listen: false);
      if (provider != null &&
          provider.isInitialized &&
          provider.shouldShowOnboarding) {
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
    _votdLoadAttempted = false;

    BibleService.instance.getVerseText(votdRef).then((text) {
      if (mounted) {
        setState(() {
          _votdLoadAttempted = true;
          _votdText = text;
        });
      }
      if (kDebugMode) {
        debugPrint(
          '[QuestHub] VOTD lookup: ref="$votdRef", text=${text != null ? "found (${text.length} chars)" : "NOT FOUND"}',
        );
      }
    }).catchError((e) {
      if (mounted) {
        setState(() {
          _votdLoadAttempted = true;
          _votdText = null;
        });
      }
      if (kDebugMode) {
        debugPrint('[QuestHub] VOTD lookup error: $e');
      }
    });
  }

  /// Determines if a quest is action-oriented (doing/active tasks).
  /// Action quests: scripture_reading, routine, service, community
  bool _isActionQuest(TaskModel q) {
    final qt = q.questType.trim().toLowerCase();
    const actionTypes = {
      'scripture_reading',
      'learning',
      'quiz',
      'routine',
      'service',
      'community',
    };
    return actionTypes.contains(qt);
  }

  /// Determines if a quest is reflective (inner prompts, journaling, etc.).
  /// Reflection quests: reflection, prayer, journal, gratitude, memorization, memorize
  bool _isReflectionQuest(TaskModel q) {
    final qt = q.questType.trim().toLowerCase();
    final title = q.title.toLowerCase();
    const reflectionTypes = {
      'reflection',
      'prayer',
      'journal',
      'gratitude',
      'memorization',
      'memorize',
    };
    if (reflectionTypes.contains(qt)) return true;
    if (title.contains('journal') ||
        title.contains('gratitude') ||
        title.contains('memorize') ||
        title.contains('forgiveness') ||
        title.contains('prayer reflection')) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        if (app.initializationError != null)
          return const StartupGate(child: SizedBox.shrink());
        if (app.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (app.currentUser == null) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Your reading space could not be loaded. Please reopen the app.',
              ),
            ),
          );
        }
        final now = DateTime.now();
        final scheduled = app.quests
            .where((q) =>
                q.resolvedCategory == TaskCategory.daily &&
                !q.isExpired &&
                !q.startDate.isAfter(now) &&
                (q.endDate == null || q.endDate!.isAfter(now)))
            .toList();
        bool weekly(TaskModel q) =>
            q.isWeekly ||
            q.category == 'weekly' ||
            q.questFrequency == 'weekly';
        bool event(TaskModel q) =>
            q.category == 'event' || q.category == 'seasonal';
        final today = scheduled.where((q) => !weekly(q) && !event(q)).toList();
        // De-duplicate by stable task ID, never by title or object identity.
        final reflectionById = <String, TaskModel>{
          for (final q in [
            ...today.where(_isReflectionQuest),
            ...app.getReflectionTasks(),
          ])
            if (!weekly(q) && !event(q) && !q.isCompleted) q.id: q,
        };
        final weeklyTasks = app.quests
            .where((q) =>
                weekly(q) &&
                !q.isExpired &&
                q.status != 'expired' &&
                (q.endDate == null || q.endDate!.isAfter(DateTime.now())))
            .toList();
        final events =
            app.quests.where((q) => event(q) && !q.isCompleted).toList();
        final votd = app.getVerseOfTheDay();
        _triggerVotdLoad(votd);
        final completed = today.where((q) => q.isCompleted).length;
        final allDone = today.isNotEmpty && completed == today.length;
        List<TaskModel> selected;
        switch (_filter) {
          case _QuestFilter.reflection:
            selected = reflectionById.values.toList();
            break;
          case _QuestFilter.events:
            selected = events;
            break;
        }
        return Scaffold(
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_stories_outlined,
                          color: cs.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'SCRIPTURE QUEST',
                            style: theme.textTheme.labelMedium?.copyWith(
                              letterSpacing: 1.8,
                            ),
                          ),
                        ),
                        if (app.currentBibleStreak > 0)
                          Tooltip(
                            message: 'Current reading streak',
                            child: Text(
                              '${app.currentBibleStreak} day streak',
                              style: theme.textTheme.labelMedium,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Today',
                      style: theme.textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      allDone
                          ? 'You have made space for Scripture. Take that with you.'
                          : 'Begin with Scripture. Let the rest follow.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 26),
                    const PrimarySessionCard(),
                    const SizedBox(height: 24),
                    const ProgressSummary(compact: true),
                    const SizedBox(height: 12),
                    ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Daily Quests'),
                        subtitle: Text(
                            '$completed / ${today.length} complete · goals around your Scripture'),
                        children: [
                          for (final q in today.where(_isActionQuest))
                            TaskCard(
                                key: ValueKey('daily-${q.id}'),
                                quest: q,
                                readingV2: true),
                          if (today.isEmpty)
                            const Text(
                                'No daily goals are available right now. You can read freely.'),
                        ]),
                    ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Weekly Quests'),
                        subtitle: Text(
                            '${weeklyTasks.where((q) => q.isCompleted).length} / ${weeklyTasks.length} complete · longer goals'),
                        children: [
                          for (final q in weeklyTasks)
                            TaskCard(
                                key: ValueKey('weekly-${q.id}'),
                                quest: q,
                                readingV2: true),
                          if (weeklyTasks.isEmpty)
                            const Text(
                                'Weekly goals will appear when the next set is available. Your earned progress is kept.'),
                        ]),
                    const SizedBox(height: 30),
                    Text(
                      'Room to reflect',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Keep a thought, a question, or a verse you want to return to.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/journal'),
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Open my journal'),
                    ),
                    const SizedBox(height: 24),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(top: 8),
                      title: Text(
                        'Optional activities',
                        style: theme.textTheme.titleMedium,
                      ),
                      subtitle: const Text(
                          'Reflection, evening quests, and other activities'),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _filterChip(
                                _QuestFilter.reflection,
                                'Reflection',
                              ),
                              if (events.isNotEmpty)
                                _filterChip(_QuestFilter.events, 'Events'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (selected.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Text(
                              'Nothing else to do here. Read freely, or save a thought in your journal.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        for (final q in app.getNightlyTasksForToday())
                          TaskCard(
                              key: ValueKey('night-${q.id}'),
                              quest: q,
                              readingV2: true),
                        for (final q in selected)
                          TaskCard(
                            key: ValueKey(q.id),
                            quest: q,
                            readingV2: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.route_outlined, color: cs.primary),
                      title: const Text('Explore Journeys'),
                      subtitle: const Text(
                        'A little direction for your next steps',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/journeys'),
                    ),
                    const SizedBox(height: 24),
                    Divider(color: cs.outlineVariant),
                    const SizedBox(height: 24),
                    _eyebrow(context, 'A VERSE TO CARRY WITH YOU'),
                    const SizedBox(height: 14),
                    if (_votdText != null)
                      Text(
                        _votdText!,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 20,
                          height: 1.6,
                        ),
                      )
                    else
                      Text(
                        _votdLoadAttempted
                            ? 'Open today’s passage in the Bible.'
                            : 'Loading today’s verse…',
                        style: theme.textTheme.bodyMedium,
                      ),
                    TextButton(
                      onPressed: votd.isEmpty
                          ? null
                          : () => _openReading(context, votd),
                      child: Text(votd.isEmpty ? 'Today’s verse' : '$votd  →'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _eyebrow(BuildContext context, String text) => Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
      );

  Widget _filterChip(_QuestFilter value, String label) => ChoiceChip(
        label: Text(label),
        selected: _filter == value,
        onSelected: (_) => setState(() => _filter = value),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      );

  void _openReading(BuildContext context, String reference) {
    final match = RegExp(r':(\d+)').firstMatch(reference);
    context.go(
      Uri(
        path: '/verses',
        queryParameters: {
          'ref': reference,
          if (match != null) 'focus': match.group(1)!,
        },
      ).toString(),
    );
  }
}
