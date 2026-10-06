import '../../widgets/sessions/passage_learning_panel.dart';
import '../../widgets/sessions/session_ending.dart';
import '../../models/connected/passage_reference.dart';
import '../../widgets/connected/next_action_panel.dart';
import '../../data/connected/connected_catalog.dart';
import '../../widgets/product/product_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../data/exploration/catalog.dart';
import '../../services/exploration/exploration_service.dart';
import '../../widgets/reading_v2/reading_design.dart';
import '../../widgets/connected/journey_content.dart';
import '../../widgets/exploration/exploration_art.dart';
import 'journeys_screen.dart';

/// Shared error boundary for saved exploration data: never resets unreadable records.
class ExplorationPage extends StatelessWidget {
  final String title;
  final double maxWidth;
  final List<Widget> Function(BuildContext, AppProvider) content;
  const ExplorationPage(
      {super.key,
      required this.title,
      required this.content,
      this.maxWidth = 680});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    try {
      app.explorationState;
      return ConnectedPage(
          title: title, maxWidth: maxWidth, children: content(context, app));
    } catch (_) {
      return ConnectedPage(title: title, children: const [
        Text(
            'Your exploration history could not be read. It has been kept unchanged. Please return after restarting the app; do not clear saved data.')
      ]);
    }
  }
}

Widget explorationLink(
        BuildContext c, String title, String subtitle, String route,
        {IconData icon = Icons.arrow_forward}) =>
    ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(icon),
        onTap: () => c.push(route));

class CodexScreen extends StatelessWidget {
  final String? id;
  const CodexScreen({super.key, this.id});
  @override
  Widget build(BuildContext context) => ExplorationPage(
      title: 'Codex — Discoveries',
      content: (c, app) {
        final records = app.discoveryRecords;
        final selected =
            id == null ? discoveries : discoveries.where((d) => d.id == id);
        return [
          Text(
              id == null
                  ? 'Read. Notice. Keep exploring.'
                  : 'A discovery to return to.',
              style: Theme.of(c).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(
              '${records.length} ${records.length == 1 ? 'discovery' : 'discoveries'} kept · Reading guides, not additional Scripture.'),
          const SizedBox(height: 20),
          for (final d in selected)
            Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: ReadingSurface(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      ExplorationArt(
                          scene: d.scene,
                          illustrated: app.illustratedExploration),
                      const SizedBox(height: 16),
                      Text(
                          records.containsKey(d.id)
                              ? 'IN YOUR CODEX'
                              : 'AN INVITATION TO DISCOVER',
                          style: Theme.of(c).textTheme.labelMedium),
                      const SizedBox(height: 8),
                      Text(d.title, style: Theme.of(c).textTheme.headlineSmall),
                      Text(d.reference),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                          onPressed: () =>
                              c.push(JourneyContent.route(d.reference)),
                          icon: const Icon(Icons.menu_book_outlined),
                          label: Text('Read ${d.reference}')),
                      if (id != null) Text(d.explanation),
                      const SizedBox(height: 12),
                      Text(records.containsKey(d.id)
                          ? 'Kept through: ${records[d.id]['source']}. This discovery stays when you return.'
                          : 'Complete this chapter after 45 seconds of reading to keep the discovery. The guide is available now.'),
                      if (id == null)
                        TextButton(
                            onPressed: () => c.push('/discoveries/${d.id}'),
                            child: const Text('Open discovery guide')),
                      if (id != null)
                        ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: const Text('Explore this discovery'),
                            children: [
                              if (id != null)
                                explorationLink(c, 'Find it in the Passage',
                                    d.prompt, '/find-passage/${d.id}',
                                    icon: Icons.search),
                              if (id != null)
                                explorationLink(
                                    c,
                                    'Choose a verse to remember',
                                    d.memoryKey.replaceFirst(':', ' '),
                                    '/memorization-practice?key=${Uri.encodeComponent(d.memoryKey)}',
                                    icon: Icons.psychology_outlined),
                              if (id != null) ...[
                                for (final connection in ConnectedCatalog
                                    .current
                                    .connectionsFor(d))
                                  ConnectionCard(connection: connection),
                                for (final journey
                                    in ConnectedCatalog.current.journeysFor(d))
                                  explorationLink(
                                      c,
                                      journey.title,
                                      'Explore this passage in a Journey.',
                                      '/journeys/${journey.id}'),
                                explorationLink(
                                    c,
                                    'Your exploration, kept',
                                    'Return to your permanent Journey Board.',
                                    '/journey-board'),
                              ],
                            ]),
                    ]))),
          if (id == null)
            explorationLink(c, 'Earlier collections',
                'Your previous keepsakes remain available.', '/collection'),
        ];
      });
}

class ConnectionCard extends StatelessWidget {
  final ScriptureConnection connection;
  const ConnectionCard({super.key, required this.connection});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(connection.kind.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Text('${connection.from} → ${connection.to}',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(connection.explanation),
        Wrap(spacing: 8, children: [
          for (final ref in [connection.from, connection.to])
            TextButton(
                onPressed: () => context.push(JourneyContent.route(ref)),
                child: Text('Read $ref'))
        ]),
      ]));
}

class LearnScreen extends StatelessWidget {
  final String? reference;
  const LearnScreen({super.key, this.reference});
  @override
  Widget build(BuildContext context) => ExplorationPage(
      title: 'Learn',
      maxWidth: 960,
      content: (c, app) {
        final passage =
            PassageReference.tryParse(reference ?? app.lastBibleReference);
        return [
          Text('Learn from Scripture',
              style: Theme.of(c).textTheme.headlineMedium),
          const SizedBox(height: 12),
          const Text('Stay with your passage, or browse the library below.'),
          const SizedBox(height: 20),
          if (passage != null) ...[
            PassageLearningPanel(passage: passage),
            const SizedBox(height: 24),
          ] else ...[
            const Text(
                'Choose a passage in the Bible, or begin with the learning library below.'),
            const NextActionPanel(learning: true),
            const SizedBox(height: 24),
          ],
          ExpansionTile(
              tilePadding: EdgeInsets.zero,
              initiallyExpanded: passage == null,
              title: const Text('Browse all learning'),
              children: [
                const SizedBox(height: 12),
                const ActivityShelf(children: [
                  ActivityCard(
                      title: 'Play & Learn',
                      description:
                          'Passage word searches, Scripture crosswords, matching, verse puzzles, book order and parables.',
                      route: '/play-learn',
                      icon: Icons.extension_outlined),
                  ActivityCard(
                      title: 'Remember Scripture',
                      description:
                          'Choose a passage to carry with you. Practice, use help, or recall independently.',
                      route: '/remembered',
                      icon: Icons.psychology_outlined),
                  ActivityCard(
                      title: 'Codex — Discoveries',
                      description:
                          'Return to discoveries, their meaning, and the Scripture that opened them.',
                      route: '/discoveries',
                      icon: Icons.auto_stories_outlined),
                ]),
                const SizedBox(height: 24),
                ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    initiallyExpanded: passage == null,
                    title: const Text('Passage challenges'),
                    children: [
                      for (final d in discoveries)
                        explorationLink(
                            c,
                            d.title,
                            '${d.reference} · ${(app.explorationState['learning'] as Map).containsKey(d.id) ? 'Evidence found · revisit' : 'Find it in the Passage'}',
                            '/find-passage/${d.id}',
                            icon: Icons.search),
                    ]),
                ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    initiallyExpanded: passage == null,
                    title: const Text('Chapter Learning'),
                    subtitle:
                        const Text('All five existing chapter challenges'),
                    children: [
                      for (final ref in ConnectedCatalog.chapterLearning)
                        explorationLink(
                            c,
                            ref.label,
                            'Quick, Standard or Deep · reflections are optional.',
                            '/chapter-quiz?book=${ref.book}&chapter=${ref.chapter}'),
                    ]),
                ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    initiallyExpanded: passage == null,
                    title: const Text('Scripture Connections'),
                    subtitle: const Text(
                        'Textual relationships and labeled editorial suggestions'),
                    children: [
                      for (final connection in scriptureConnections)
                        ConnectionCard(connection: connection),
                    ]),
              ]),
        ];
      });
}

/// A passage-backed observation, not a detached trivia question.
class FindPassageScreen extends StatefulWidget {
  final String id;
  const FindPassageScreen({super.key, required this.id});
  @override
  State<FindPassageScreen> createState() => _FindPassageScreenState();
}

class _FindPassageScreenState extends State<FindPassageScreen> {
  late final Discovery d = discoveryById(widget.id);
  late final Future<String> passage =
      context.read<AppProvider>().loadKjvPassage(d.reference);
  final scroll = ScrollController();
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  bool busy = false, finished = false, hint = false;
  String? feedback;
  Future<void> choose(int verse) async {
    if (busy || finished) return;
    setState(() => busy = true);
    try {
      final r =
          await context.read<AppProvider>().recordPassageFinding(d.id, verse);
      if (mounted)
        setState(() {
          finished = r.correct;
          feedback = r.correct
              ? 'Evidence found in ${d.reference}:$verse. ${r.xp > 0 ? '+${r.xp} XP saved.' : 'Your earlier reward is kept.'}\n${r.changes.join('\n')}'
              : 'Look again in the passage. Try another verse, or use the clue.';
        });
      if (mounted && r.correct && scroll.hasClients) {
        scroll.jumpTo(0);
      }
    } catch (_) {
      if (mounted)
        setState(
            () => feedback = 'Could not save your result. Please try again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
      future: passage,
      builder: (c, s) {
        final lines = (s.data ?? '')
            .split('\n')
            .where((l) => RegExp(r'^\d+\s').hasMatch(l.trim()))
            .toList();
        return ConnectedPage(
            title: 'Find it in the Passage',
            controller: scroll,
            children: [
              Text(d.prompt, style: Theme.of(c).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text('${d.reference} · KJV'),
              const SizedBox(height: 8),
              const Text(
                  'Read the passage. Tap the verse containing the evidence.'),
              if (!s.hasData) const LinearProgressIndicator(),
              if (s.hasData && lines.isEmpty)
                const Text(
                    'The passage could not be loaded. No result has been recorded.'),
              TextButton(
                  onPressed: () => setState(() => hint = true),
                  child: const Text('Show a clue')),
              if (hint) Text('Look for “${d.evidence}”.'),
              if (!finished && feedback != null)
                Semantics(liveRegion: true, child: Text(feedback!)),
              for (final line in lines.where(
                  (line) => !finished || line.startsWith('${d.answerVerse} ')))
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.all(16)),
                        onPressed: busy || finished
                            ? null
                            : () => choose(int.parse(RegExp(r'^\d+')
                                .firstMatch(line.trim())!
                                .group(0)!)),
                        child: Text(line,
                            style: Theme.of(c)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(height: 1.7)))),
              if (finished && feedback != null)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Semantics(
                        liveRegion: true,
                        child: Text(feedback!.split('\n').first,
                            style: Theme.of(c).textTheme.titleMedium))),
              if (finished) ...[
                SessionEnding(
                    passage: PassageReference.tryParse(d.reference)!,
                    more: [
                      explorationLink(c, 'Keep exploring this discovery',
                          'Context and connections', '/discoveries/${d.id}'),
                      explorationLink(
                          c,
                          'Remember a verse from this passage',
                          'Practice at your own pace.',
                          '/memorization-practice?key=${Uri.encodeComponent(d.memoryKey)}'),
                    ]),
                SavedDetails(children: [Text(feedback ?? '')]),
              ],
              TextButton(
                  onPressed: () => c.push(JourneyContent.route(d.reference)),
                  child: const Text('Open the full Bible reader')),
            ]);
      });
}

class RememberedScreen extends StatelessWidget {
  const RememberedScreen({super.key});
  @override
  Widget build(BuildContext context) => ExplorationPage(
      title: 'Remembered Scripture',
      content: (c, app) {
        final memory = app.explorationState['memory'] as Map;
        final keys = {...memory.keys.cast<String>(), ...app.favoriteVerseKeys};
        return [
          Text('Words you choose to carry.',
              style: Theme.of(c).textTheme.headlineMedium),
          const SizedBox(height: 12),
          const Text(
              'Choose a verse to practice. Your practice and recall outcomes are kept separately.'),
          if (keys.isEmpty)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                    'Choose “Memorize this verse” in the Bible reader, or begin with a discovery.')),
          for (final key in keys)
            Builder(builder: (_) {
              final sessions =
                  (memory[key]?['sessions'] as Map?)?.values.toList() ?? [];
              final counts = [
                for (final o in RecallOutcome.values)
                  '${sessions.where((s) => s['outcome'] == o.name).length} ${recallLabel(o.name).toLowerCase()}'
              ];
              return explorationLink(
                  c,
                  key.replaceFirst(':', ' '),
                  sessions.isEmpty
                      ? 'Saved verse · begin practice'
                      : counts.join(' · '),
                  '/memorization-practice?key=${Uri.encodeComponent(key)}',
                  icon: Icons.psychology_outlined);
            }),
          explorationLink(
              c,
              'Discover a passage to remember',
              'Choose something meaningful from what you read.',
              '/discoveries'),
          ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Earlier memorization library'),
              children: [
                explorationLink(c, 'Open earlier records',
                    'Your original library and saved history.', '/memorization')
              ]),
        ];
      });
}
