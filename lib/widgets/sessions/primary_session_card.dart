import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../reading_v2/reading_design.dart';
import '../connected/next_action_panel.dart';
import '../../services/continuity/next_action.dart';

class PrimarySessionCard extends StatelessWidget {
  const PrimarySessionCard({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return ReadingSurface(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('YOUR NEXT SCRIPTURE STEP',
          style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: 12),
      const NextActionPanel(
          sessionContext: SessionContext.today, prominent: true),
      if (app.focusedJourney != null) ...[
        const SizedBox(height: 12),
        Text(
            '${app.focusedJourney!.completedSteps} / ${app.focusedJourney!.totalSteps} Journey steps · progress is kept',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    ]));
  }
}
