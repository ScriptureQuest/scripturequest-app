import '../../data/connected/connected_catalog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/connected/passage_reference.dart';
import '../../services/continuity/continuity_reader.dart';
import '../../services/continuity/next_action.dart';

/// One contextual continuation; navigation is a push, not a reward action.
class NextActionPanel extends StatelessWidget {
  final String? reference, finishedJourney;
  final bool learning;
  final SessionContext? sessionContext;
  final bool secondaryJourney;
  final bool subdued, prominent;
  final ValueChanged<String>? onNavigate;
  const NextActionPanel(
      {super.key,
      this.reference,
      this.finishedJourney,
      this.learning = false,
      this.sessionContext,
      this.secondaryJourney = false,
      this.subdued = false,
      this.prominent = false,
      this.onNavigate});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return FutureBuilder<ContinuitySnapshot>(
        future: ContinuityReader.read(app),
        builder: (c, s) {
          if (s.hasError)
            return const Text(
                'Your continuation could not be read. Saved progress has not been changed. You can still open the Bible.');
          if (!s.hasData)
            return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator());
          final action = NextActionGuidance().resolve(s.data!,
              passage: PassageReference.tryParse(reference),
              learning: learning,
              finishedJourney: finishedJourney,
              context: sessionContext ??
                  (reference != null
                      ? (learning
                          ? SessionContext.passageLearning
                          : SessionContext.freeReading)
                      : learning
                          ? SessionContext.passageLearning
                          : SessionContext.today));
          final j = s.data!.activeJourney;
          final p = PassageReference.tryParse(reference);
          final related = j != null &&
              p != null &&
              ConnectedCatalog.current.forJourney(j.questline.id).any((d) =>
                  PassageReference.tryParse(d.reference)!.sameChapter(p));
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (action.optionalReplay && !subdued)
                  const Text('OPTIONAL REVISIT'),
                Text(action.reason, style: Theme.of(c).textTheme.bodyMedium),
                const SizedBox(height: 10),
                if (action.optionalReplay || subdued)
                  OutlinedButton(
                      onPressed: () => onNavigate != null
                          ? onNavigate!(action.destination.route)
                          : c.push(action.destination.route),
                      child: Text(action.title,
                          textAlign: TextAlign.center,
                          style: prominent
                              ? Theme.of(c).textTheme.titleLarge
                              : null))
                else
                  FilledButton(
                      onPressed: () => onNavigate != null
                          ? onNavigate!(action.destination.route)
                          : c.push(action.destination.route),
                      child: Text(action.title,
                          textAlign: TextAlign.center,
                          style: prominent
                              ? Theme.of(c).textTheme.titleLarge
                              : null)),
                if (secondaryJourney &&
                    related &&
                    j.currentStep != null &&
                    ConnectedCatalog.current.passage(j.currentStep) == null)
                  const Text(
                      'Optional Journey response · continue with or without writing.'),
                if (secondaryJourney && s.data!.activeJourney != null)
                  TextButton(
                      onPressed: () {
                        final route =
                            '/journeys/${s.data!.activeJourney!.questline.id}';
                        if (onNavigate != null) {
                          onNavigate!(route);
                        } else {
                          c.push(route);
                        }
                      },
                      child: Text(related
                          ? 'Continue ${j.questline.title}'
                          : 'Return to my Journey · optional')),
              ]);
        });
  }
}
