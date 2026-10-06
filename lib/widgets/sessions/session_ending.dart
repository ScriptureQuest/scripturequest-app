import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/connected/passage_reference.dart';
import '../../providers/app_provider.dart';
import '../../services/continuity/next_action.dart';
import '../connected/next_action_panel.dart';
import 'done_for_now.dart';

/// Presentation only: a successful stopping action, one optional continuation,
/// and deliberate access to depth. No completion or reward writes occur here.
class SessionEnding extends StatelessWidget {
  final PassageReference? passage;
  final SessionContext contextKind;
  final VoidCallback? onDone;
  final ValueChanged<String>? onNavigate;
  final List<Widget> more;
  const SessionEnding(
      {super.key,
      required this.passage,
      this.contextKind = SessionContext.learningResult,
      this.onDone,
      this.onNavigate,
      this.more = const []});
  @override
  Widget build(BuildContext context) {
    void navigate(String route) {
      if (onNavigate != null) {
        onNavigate!(route);
      } else {
        context.push(route);
      }
    }

    final journey = context.watch<AppProvider>().focusedJourney;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (passage != null)
        DoneForNow(passage: passage!, onDone: onDone)
      else
        FilledButton.icon(
            onPressed: onDone ?? () => context.go('/'),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Done for now')),
      const SizedBox(height: 12),
      if (passage != null) ...[
        const Text('If you’d like to continue'),
        NextActionPanel(
            reference: passage!.label,
            sessionContext: contextKind,
            subdued: true,
            onNavigate: navigate),
      ],
      if (more.isNotEmpty || journey != null)
        ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Explore more'),
            children: [
              ...more,
              if (journey?.currentStep?.questId.startsWith('tpl:reflect') ==
                  true)
                const Text(
                    'Optional Journey response · continue with or without writing.'),
              if (journey != null)
                TextButton(
                    onPressed: () =>
                        navigate('/journeys/${journey.questline.id}'),
                    child: Text(
                        'Return to ${journey.questline.title} · optional')),
            ]),
    ]);
  }
}

/// Full saved receipts stay reachable, below the immediate session ending.
class SavedDetails extends StatelessWidget {
  final List<Widget> children;
  const SavedDetails({super.key, required this.children});
  @override
  Widget build(BuildContext context) => children.isEmpty
      ? const SizedBox.shrink()
      : ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Saved progress details'),
          children: children);
}
