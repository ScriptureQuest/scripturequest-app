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
  final ValueChanged<String>? onNavigate;
  const NextActionPanel(
      {super.key,
      this.reference,
      this.finishedJourney,
      this.learning = false,
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
              finishedJourney: finishedJourney);
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(action.reason, style: Theme.of(c).textTheme.bodyMedium),
                const SizedBox(height: 10),
                FilledButton(
                    onPressed: () => onNavigate != null
                        ? onNavigate!(action.destination.route)
                        : c.push(action.destination.route),
                    child: Text(action.title, textAlign: TextAlign.center)),
              ]);
        });
  }
}
