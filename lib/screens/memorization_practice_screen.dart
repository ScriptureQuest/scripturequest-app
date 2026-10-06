import '../widgets/sessions/session_ending.dart';
import '../models/connected/passage_reference.dart';
import '../widgets/exploration/exploration_art.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../services/exploration/exploration_service.dart';
import '../widgets/connected/journey_content.dart';
import '../widgets/reading_v2/reading_design.dart';
import 'connected/journeys_screen.dart';

class MemorizationPracticeScreen extends StatefulWidget {
  final String verseKey;
  const MemorizationPracticeScreen({super.key, required this.verseKey});
  @override
  State<MemorizationPracticeScreen> createState() => _MemoryState();
}

class _MemoryState extends State<MemorizationPracticeScreen> {
  late final Future<String> verse =
      context.read<AppProvider>().loadMemoryVerse(widget.verseKey);
  final session = const Uuid().v4();
  bool hidden = false, helped = false, busy = false, saved = false;
  String? result;
  String get reference => widget.verseKey.replaceFirst(':', ' ');
  Future<void> record(RecallOutcome outcome) async {
    if (busy || saved) return;
    setState(() => busy = true);
    try {
      final r = await context
          .read<AppProvider>()
          .recordRecallEvidence(widget.verseKey, outcome, session);
      if (mounted)
        setState(() {
          saved = true;
          result =
              '${recallLabel(outcome.name)} · saved\n${r.xp > 0 ? '+${r.xp} XP earned.' : 'Practice kept. No new XP on this attempt.'}\n${r.changes.join('\n')}';
        });
    } catch (_) {
      if (mounted)
        setState(
            () => result = 'Could not save your practice. Please try again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
      future: verse,
      builder: (c, s) => ConnectedPage(title: 'Remember Scripture', children: [
            Text(reference, style: Theme.of(c).textTheme.headlineMedium),
            const SizedBox(height: 12),
            const Text(
                'Study the words, then hide them and recall privately. Record how it went.'),
            const SizedBox(height: 20),
            if (s.connectionState != ConnectionState.done)
              const LinearProgressIndicator(),
            if (s.hasError)
              const Text(
                  'This verse could not be loaded. No practice has been recorded.'),
            if (s.hasData) ...[
              ReadingSurface(
                  child: Text(
                      hidden && !helped && !saved
                          ? 'The passage is hidden. Take your time.'
                          : s.data!,
                      style: Theme.of(c)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(height: 1.7))),
              const SizedBox(height: 16),
              if (!hidden && !saved)
                FilledButton(
                    onPressed: () => setState(() => hidden = true),
                    child: const Text('Hide the verse and try recalling')),
              if (hidden && !saved)
                TextButton(
                    onPressed:
                        busy ? null : () => setState(() => helped = true),
                    child: const Text('Show the passage for help')),
              if (!saved) ...[
                TextButton(
                    onPressed:
                        busy ? null : () => record(RecallOutcome.practiced),
                    child: const Text('I practiced today')),
                if (hidden)
                  FilledButton(
                      onPressed: busy
                          ? null
                          : () => record(helped
                              ? RecallOutcome.helped
                              : RecallOutcome.independent),
                      child: Text(helped
                          ? 'I recalled it with help'
                          : 'I recalled it independently')),
              ],
              if (saved)
                const AccomplishmentMark(icon: Icons.psychology_outlined),
              if (result != null)
                Semantics(
                    liveRegion: true,
                    child: Text(
                        saved
                            ? result!.split('\n').take(2).join('\n')
                            : result!,
                        style: Theme.of(c).textTheme.titleMedium)),
              if (saved) ...[
                SessionEnding(
                    passage: PassageReference.tryParse(reference)!,
                    more: [
                      TextButton(
                          onPressed: () =>
                              c.push(JourneyContent.route(reference)),
                          child: const Text('Read this verse in context')),
                      TextButton(
                          onPressed: () => c.push('/remembered'),
                          child: const Text('My remembered Scripture')),
                    ]),
                SavedDetails(children: [Text(result!)]),
              ],
            ],
            if (!saved)
              TextButton(
                  onPressed: () => c.push(JourneyContent.route(reference)),
                  child: const Text('Read this verse in context')),
            ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('About practice and recall'),
                children: const [
                  Text(
                      'Outcomes are self-reported, not a measure of faith. Independent recall can earn the existing daily verse reward. Practicing and recall with help are kept separately and can advance eligible learning quests.')
                ]),
          ]));
}
