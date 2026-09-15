import '../../widgets/exploration/exploration_art.dart';
import '../../data/exploration/catalog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/models/questline.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/widgets/reading_v2/reading_design.dart';
import 'package:level_up_your_faith/widgets/connected/journey_content.dart';
import 'package:level_up_your_faith/widgets/connected/progress_summary.dart';
import 'package:level_up_your_faith/widgets/journal/journal_editor_sheet.dart';

class ConnectedPage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final ScrollController? controller;
  const ConnectedPage({super.key, required this.title, required this.children, this.controller});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  children: children))));
}

class JourneysScreen extends StatefulWidget {
  final bool board;
  const JourneysScreen({super.key, this.board = false});
  @override
  State<JourneysScreen> createState() => _JourneysScreenState();
}

class _JourneysScreenState extends State<JourneysScreen> {
  late Future<(List<Questline>, List<QuestlineProgressView>)> _data;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final app = context.read<AppProvider>();
    _data = (() async {
      if (widget.board) app.discoveryRecords; // Surface read failure in the existing error state.
      return (await app.getAvailableQuestlines(), await app.journeyHistory());
    })();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<
          (List<Questline>, List<QuestlineProgressView>)>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return ConnectedPage(title: 'Journeys', children: [
            const Text(
                'Your saved Journeys could not be read. They have not been replaced.'),
            TextButton(
                onPressed: () => setState(_load),
                child: const Text('Try again'))
          ]);
        if (!snapshot.hasData)
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        final (definitions, history) = snapshot.data!;
        final items = widget.board
            ? history.map((v) => v.questline).toList()
            : definitions
                .where((d) => AppProvider.connectedJourneyIds.contains(d.id))
                .toList();
        return ConnectedPage(
            title: widget.board ? 'Journey Board' : 'Journeys',
            children: [
              Text(
                  widget.board
                      ? 'Where your reading has taken you.'
                      : 'What would you like to explore?',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 10),
              Text(widget.board
                  ? 'A lasting record of what you have begun and completed. Time away does not erase it.'
                  : 'Guided Journeys follow a question through Scripture. Reading plans give your reading a schedule.'),
              const SizedBox(height: 24),
              if (items.isEmpty)
                ReadingSurface(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Icon(Icons.route_outlined, size: 32),
                      const SizedBox(height: 12),
                      const Text(
                          'Your first chapter of exploration is ahead of you.'),
                      TextButton(
                          onPressed: () => context.go('/journeys'),
                          child: const Text('Find a Journey'))
                    ])),
              for (final d in items)
                Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Builder(builder: (context) {
                      final saved =
                          history.where((v) => v.questline.id == d.id);
                      final v = saved.isEmpty ? null : saved.first;
                      return ReadingSurface(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            ExplorationArt(scene: d.id == 'knowing_jesus' ? 'light' : d.id == 'psalms_of_peace' ? 'peace' : 'night', illustrated: context.watch<AppProvider>().illustratedExploration),
                            const SizedBox(height: 14),
                            Row(children: [
                              Icon(v?.progress.isCompleted == true
                                  ? Icons.check_circle_outline
                                  : Icons.route_outlined),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(d.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge))
                            ]),
                            const SizedBox(height: 10),
                            Text(
                                JourneyContent.purposes[d.id] ?? d.description),
                            const SizedBox(height: 14),
                            if (v != null) ...[
                              LinearProgressIndicator(value: v.completionRatio),
                              const SizedBox(height: 8),
                              Text(v.progress.isCompleted
                                  ? 'Completed · ${_date(v.progress.dateCompleted!)}'
                                  : '${v.completedSteps}/${v.totalSteps} steps · Begun ${_date(v.progress.dateStarted)}')
                            ] else
                              Text('${d.steps.length} steps · At your pace'),
                            if (widget.board)
                              for (final discovery in discoveries.where((entry) => d.steps.any((step) => (JourneyContent.reference(step) == entry.reference || (JourneyContent.reference(step) ?? '').startsWith('${entry.reference}:'))) && context.read<AppProvider>().discoveryRecords.containsKey(entry.id)))
                                _link(context, Icons.auto_stories_outlined, discovery.title,
                                  (context.read<AppProvider>().explorationState['learning'] as Map).containsKey(discovery.id) ? 'Discovery kept · passage evidence found' : 'Discovery kept · look closer in the passage', '/discoveries/${discovery.id}'),
                            TextButton(
                                onPressed: () async {
                                  await context.push(AppProvider
                                          .connectedJourneyIds
                                          .contains(d.id)
                                      ? '/journeys/${d.id}'
                                      : '/questline/${d.id}');
                                  if (mounted) setState(_load);
                                },
                                child: Text(v?.progress.isCompleted == true
                                    ? 'Revisit this Journey'
                                    : v == null
                                        ? 'Explore Journey'
                                        : 'Continue Journey')),
                          ]));
                    })),
              if (!widget.board) ...[
                const SizedBox(height: 8),
                _link(
                    context,
                    Icons.calendar_today_outlined,
                    'Reading Plans',
                    'A schedule for what to read next. Your existing enrollment is preserved.',
                    '/reading-plans'),
                _link(context, Icons.explore_outlined, 'More guided quests',
                    'Explore the existing guided-quest library.', '/quests'),
                _link(context, Icons.route_outlined, 'Journey Board',
                    'Your exploration, kept permanently.', '/journey-board'),
              ],
              _link(
                  context,
                  Icons.auto_stories_outlined,
                  'Codex discoveries',
                  'Return to what you have discovered in Scripture.',
                  '/discoveries'),
            ]);
      });
  String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

Widget _link(BuildContext context, IconData icon, String title, String subtitle,
        String route) =>
    ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(route));

class GuidedJourneyScreen extends StatefulWidget {
  final String id;
  const GuidedJourneyScreen({super.key, required this.id});
  @override
  State<GuidedJourneyScreen> createState() => _GuidedJourneyScreenState();
}

class _GuidedJourneyScreenState extends State<GuidedJourneyScreen> {
  late Future<(Questline, QuestlineProgressView?)> _data;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final app = context.read<AppProvider>();
    _data = () async {
      final d = (await app.getAvailableQuestlines())
          .firstWhere((d) => d.id == widget.id);
      final h = (await app.journeyHistory())
          .where((v) => v.questline.id == widget.id);
      return (d, h.isEmpty ? null : h.first);
    }();
  }

  Future<void> _act(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not save this step. Please try again.')));
    } finally {
      if (mounted)
        setState(() {
          _busy = false;
          _load();
        });
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<
          (Questline, QuestlineProgressView?)>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return ConnectedPage(title: 'Journey', children: [
            const Text(
                'This Journey could not be loaded. Your history has been kept.'),
            TextButton(
                onPressed: () => setState(_load),
                child: const Text('Try again'))
          ]);
        if (!snapshot.hasData)
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        final (d, v) = snapshot.data!;
        final app = context.read<AppProvider>();
        final complete = v?.progress.isCompleted == true;
        final current = v?.currentStep;
        return ConnectedPage(title: d.title, children: [
          Text(JourneyContent.purposes[d.id] ?? d.description,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(complete
              ? 'This Journey is part of your story. Revisit any passage, or choose what comes next.'
              : 'Read in context. Notice what stands out. Reflections are optional, private, and never graded.'),
          const SizedBox(height: 20),
          if (v != null) ...[
            LinearProgressIndicator(value: v.completionRatio),
            const SizedBox(height: 8),
            Text(
                '${v.completedSteps}/${v.totalSteps} steps${complete ? ' · Complete' : ''}'),
            const SizedBox(height: 20)
          ],
          if (v == null)
            FilledButton(
                onPressed:
                    _busy ? null : () => _act(() => app.focusJourney(d.id)),
                child: const Text('Begin this Journey')),
          if (v != null && !complete)
            TextButton(
                onPressed:
                    _busy ? null : () => _act(() => app.focusJourney(d.id)),
                child: const Text('Make this my current Journey')),
          for (final step in d.steps)
            Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Builder(builder: (context) {
                  final ref = JourneyContent.reference(step);
                  final response = JourneyContent.reflection(step);
                  final done =
                      v?.progress.completedStepIds.contains(step.id) == true;
                  final active = current?.id == step.id;
                  final skipped =
                      v?.progress.skippedStepIds.contains(step.id) == true;
                  final canRead = ref !=
                      null; // Scripture is always available, even before enrollment.
                  return ReadingSurface(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(
                            '${skipped ? 'Passed · ' : done ? '✓ ' : ''}STEP ${step.order}${response ? ' · OPTIONAL RESPONSE' : active ? ' · UP NEXT' : ''}',
                            style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 10),
                        Text(ref ?? 'Pause and respond',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(JourneyContent.orientations[step.id] ??
                            (response
                                ? 'What stayed with you? Keep a thought or question, or continue without writing.'
                                : d.description)),
                        if (canRead)
                          TextButton.icon(
                              icon: const Icon(Icons.menu_book_outlined),
                              label: Text(done
                                  ? 'Revisit Scripture'
                                  : 'Read in the Bible'),
                              onPressed: () async {
                                await context.push(JourneyContent.route(ref));
                                if (mounted) setState(_load);
                              }),
                        if (response && active) ...[
                          TextButton.icon(
                              icon: const Icon(Icons.edit_note),
                              label: const Text('Keep a reflection'),
                              onPressed: _busy
                                  ? null
                                  : () async {
                                      final previous = d.steps
                                          .where((s) =>
                                              s.order < step.order &&
                                              JourneyContent.reference(s) !=
                                                  null)
                                          .toList();
                                      final linked = previous.isEmpty
                                          ? null
                                          : JourneyContent.reference(
                                              previous.last);
                                      await showModalBottomSheet<void>(
                                          context: context,
                                          isScrollControlled: true,
                                          useSafeArea: true,
                                          builder: (_) => JournalEditorSheet(
                                              initialTitle: d.title,
                                              initialLinkedRef: linked,
                                              initialLinkedRefRoute:
                                                  linked == null
                                                      ? null
                                                      : JourneyContent.route(
                                                          linked),
                                              questlineId: d.id,
                                              stepId: step.id));
                                      if (mounted) setState(_load);
                                    }),
                          TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _act(() => app.markQuestlineStepDone(
                                      d.id, step.id,
                                      stepXp: 0, skipReflection: true)),
                              child: const Text('Continue without writing')),
                        ],
                        if (active && ref != null)
                          const Text(
                              'Complete this chapter in the reader after 45 seconds to advance this step.',
                              style: TextStyle(fontSize: 13)),
                      ]));
                })),
          for (final discovery in discoveries.where((e) => e.journey == d.id))
            _link(
                context,
                Icons.auto_stories_outlined,
                'A discovery along the way',
                '${discovery.title} · ${discovery.reference}',
                '/discoveries/${discovery.id}'),
          if (complete)
            FilledButton.icon(
                onPressed: () => context.go('/journeys'),
                icon: const Icon(Icons.explore_outlined),
                label: const Text('Explore another Journey')),
          _link(context, Icons.route_outlined, 'Keep the accomplishment',
              'See your Journey Board.', '/journey-board'),
          _link(context, Icons.edit_note, 'Your journal',
              'Return to thoughts and linked passages.', '/journal'),
        ]);
      });
}

class YouScreen extends StatelessWidget {
  const YouScreen({super.key});
  @override
  Widget build(BuildContext context) => ConnectedPage(title: 'You', children: [
        Text('Your Scripture story.',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        const Text('What you have explored, discovered, and chosen to keep.'),
        const SizedBox(height: 24),
        const ProgressSummary(),
        const SizedBox(height: 20),
        _link(
            context,
            Icons.route_outlined,
            'Journey Board',
            'Where you have been and what you are working toward',
            '/journey-board'),
        _link(context, Icons.auto_stories_outlined, 'Codex',
            'What you have discovered and what it means', '/discoveries'),
        _link(context, Icons.psychology_outlined, 'Remembered Scripture', 'Chosen verses, practice and recall history', '/remembered'),
        _link(context, Icons.workspace_premium_outlined, 'Achievements',
            'Milestones of engagement and learning', '/achievements'),
        _link(context, Icons.edit_note, 'Journal',
            'Private reflections and questions', '/journal'),
        _link(context, Icons.bookmark_outline, 'Bookmarks',
            'Passages to return to', '/bookmarks'),
        _link(context, Icons.highlight_outlined, 'Highlights',
            'Words you chose to keep', '/highlights'),
        _link(context, Icons.history, 'Reading history', 'Your reading record',
            '/reading-stats'),
        _link(context, Icons.person_outline, 'Profile',
            'Your existing profile and preferences', '/profile'),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Illustrated exploration'), subtitle: const Text('Gentle Journey and Codex landscapes. Scripture stays on a plain reading surface.'), value: context.watch<AppProvider>().illustratedExploration, onChanged: (value) async { try { await context.read<AppProvider>().setIllustratedExploration(value); } catch (_) { if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preference could not be saved.'))); } }),
        _link(context, Icons.settings_outlined, 'Settings',
            'Reading comfort and app preferences', '/settings'),
      ]);
}
