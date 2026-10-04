import '../connected/next_action_panel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/connected/passage_reference.dart';
import '../../services/continuity/continuity_reader.dart';
import '../../services/continuity/next_action.dart';
import '../../services/sessions/passage_learning.dart';
import '../reading_v2/reading_design.dart';

class PassageLearningPanel extends StatelessWidget {
  final PassageReference passage;
  const PassageLearningPanel({super.key, required this.passage});
  @override
  Widget build(BuildContext context) => FutureBuilder<ContinuitySnapshot>(
      future: ContinuityReader.read(context.watch<AppProvider>()),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return const Text(
              'Passage progress could not be read. Your saved records have not been changed.');
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final s = snapshot.data!;
        final view = PassageLearning.build(passage,
            learned: s.learned,
            quizzes: s.quizzes,
            activities: s.activities,
            remembered: s.remembered,
            earnedDiscoveries: s.discoveries);
        Widget links(List<LearningOpportunity> items) => Column(children: [
              for (final o in items)
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(o.title),
                    subtitle: Text('${o.status}\n${o.detail}'),
                    isThreeLine: false,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(o.route))
            ]);
        return ReadingSurface(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Text('YOUR PASSAGE',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              Text(passage.label,
                  style: Theme.of(context).textTheme.headlineMedium),
              TextButton.icon(
                  onPressed: () => context.push(passage.destination.route),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('Read in context')),
              Semantics(
                  liveRegion: true,
                  child: Text(view.caughtUp
                      ? 'You’re caught up with the available challenges here. Replays are optional.'
                      : view.opportunities.isEmpty
                          ? 'No authored challenges are available for this chapter yet.'
                          : 'Choose a way to look closer at this passage.')),
              links(view.opportunities),
              if (s.activeJourney != null &&
                  view.journeys.any((j) =>
                      j.route ==
                      '/journeys/${s.activeJourney!.questline.id}') &&
                  s.activeJourney!.currentStep != null &&
                  s.activeJourney!.currentStep!.questId
                      .startsWith('tpl:reflect'))
                NextActionPanel(sessionContext: SessionContext.journey),
              if (view.connections.isNotEmpty)
                ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Connections & discoveries'),
                    children: [links(view.connections)]),
              if (view.remembering.isNotEmpty)
                ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Remember these words'),
                    children: [links(view.remembering)]),
              if (view.remembering.isEmpty)
                const Text(
                    'To remember words from this chapter, open Scripture and choose a verse.'),
              if (view.journeys.isNotEmpty)
                ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Related Journeys · optional'),
                    children: [links(view.journeys)]),
            ]));
      });
}
