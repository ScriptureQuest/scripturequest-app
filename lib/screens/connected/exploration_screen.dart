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
  final List<Widget> Function(BuildContext, AppProvider) content;
  const ExplorationPage(
      {super.key, required this.title, required this.content});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    try {
      app.explorationState;
      return ConnectedPage(title: title, children: content(context, app));
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
      title: 'Codex',
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
                      if (id != null)
                        explorationLink(c, 'Find it in the Passage', d.prompt,
                            '/find-passage/${d.id}',
                            icon: Icons.search),
                      if (id != null)
                        explorationLink(
                            c,
                            'Choose a verse to remember',
                            d.memoryKey.replaceFirst(':', ' '),
                            '/memorization-practice?key=${Uri.encodeComponent(d.memoryKey)}',
                            icon: Icons.psychology_outlined),
                      if (id == null)
                        TextButton(
                            onPressed: () => c.push('/discoveries/${d.id}'),
                            child: const Text('Open discovery guide')),
                      if (id != null) ...[
                        for (final connection in scriptureConnections
                            .where((s) => s.from.startsWith(d.reference + ':')))
                          ConnectionCard(connection: connection),
                        explorationLink(
                            c,
                            'Follow the Journey',
                            'Read in context and continue exploring.',
                            '/journeys/${d.journey}'),
                        explorationLink(
                            c,
                            'Your exploration, kept',
                            'Return to your permanent Journey Board.',
                            '/journey-board'),
                      ],
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
  const LearnScreen({super.key});
  @override Widget build(BuildContext context) => ExplorationPage(title:'Learn',content:(c,app) {
    final candidates = discoveries.where((d)=>app.discoveryRecords.containsKey(d.id) && !(app.explorationState['learning'] as Map).containsKey(d.id));
    final next = candidates.isEmpty ? discoveries.first : candidates.first;
    return [
      Text('Explore. Practice. Discover.',style:Theme.of(c).textTheme.headlineMedium),
      const SizedBox(height:12),const Text('Look closely at Scripture, give your memory a challenge, or play with what you are learning.'),const SizedBox(height:20),
      const ProgressIdentity(),const SizedBox(height:24),
      Text('A challenge from your reading',style:Theme.of(c).textTheme.titleLarge),const SizedBox(height:12),
      ActivityCard(title:next.title,description:'${next.reference} · Find the evidence in the passage. ${candidates.isEmpty ? 'Open the Bible and explore.' : 'You have read this. Look closer.'}',route:'/find-passage/${next.id}',icon:Icons.search,featured:true),
      const SizedBox(height:24),Text('Choose how to learn',style:Theme.of(c).textTheme.titleLarge),const SizedBox(height:12),
      const ActivityShelf(children:[
        ActivityCard(title:'Play & Learn',description:'Matching, verse puzzles, Bible book order, and parables. Familiar games with a Scripture purpose.',route:'/play-learn',icon:Icons.extension_outlined),
        ActivityCard(title:'Remember Scripture',description:'Choose a passage to carry with you. Practice, use help, or recall independently.',route:'/remembered',icon:Icons.psychology_outlined),
        ActivityCard(title:'Explore the Codex',description:'Return to discoveries, their meaning, and the Scripture that opened them.',route:'/discoveries',icon:Icons.auto_stories_outlined),
      ]),const SizedBox(height:24),Text('Passage challenges',style:Theme.of(c).textTheme.titleLarge),
      for(final d in discoveries) explorationLink(c,d.title,'${d.reference} · ${(app.explorationState['learning'] as Map).containsKey(d.id)?'Evidence found · revisit':'Find it in the Passage'}','/find-passage/${d.id}',icon:Icons.search),
      const SizedBox(height:24),Text('Chapter Learning',style:Theme.of(c).textTheme.titleLarge),const SizedBox(height:8),const Text('Quick, Standard, and Deep challenges using the existing chapter library. Reflections stay optional and ungraded.'),
      for(final ref in [('John',3),('Romans',8),('Psalms',23)]) explorationLink(c,'${ref.$1} ${ref.$2}','Read in context, then try the chapter challenge.','/chapter-quiz?book=${ref.$1}&chapter=${ref.$2}'),
      const SizedBox(height:24),Text('Scripture Connections',style:Theme.of(c).textTheme.titleLarge),const Text('Compare passages with clear context. Thematic pairings are labeled as editorial suggestions.'),
      for(final connection in scriptureConnections) ConnectionCard(connection:connection),
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
        await scroll.animateTo(0,
            duration: MediaQuery.of(context).disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 220),
            curve: Curves.easeOut);
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
                  'Read in context. Tap the verse containing the evidence. First completion earns 10 base XP and can advance eligible learning quests.'),
              if (!s.hasData) const LinearProgressIndicator(),
              if (s.hasData && lines.isEmpty)
                const Text(
                    'The passage could not be loaded. No result has been recorded.'),
              TextButton(
                  onPressed: () => setState(() => hint = true),
                  child: const Text('Show a clue')),
              if (hint) Text('Look for “${d.evidence}”.'),
              if (feedback != null)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Semantics(
                        liveRegion: true,
                        child: Text(feedback!,
                            style: Theme.of(c).textTheme.titleMedium))),
              if (finished) ...[
                const AccomplishmentMark(icon: Icons.search),
                explorationLink(
                    c,
                    'Keep exploring this discovery',
                    'Context, connections, and the next Journey',
                    '/discoveries/${d.id}'),
                explorationLink(
                    c,
                    'Remember a verse from this passage',
                    'Practice at your own pace.',
                    '/memorization-practice?key=${Uri.encodeComponent(d.memoryKey)}'),
              ],
              for (final line in lines)
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
              'Practice is a personal record, not a measure of faith. Outcomes are self-reported. Earlier memorization records remain in your original library.'),
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
          explorationLink(c, 'Earlier memorization library',
              'Your existing learning records are preserved.', '/memorization'),
        ];
      });
}
