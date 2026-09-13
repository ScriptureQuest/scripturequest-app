import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/models/reading_completion.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/widgets/journal/journal_editor_sheet.dart';
import 'journey_content.dart';

Future<void> showReadingResult(
    BuildContext context, ReadingCompletion result) async {
  final destination = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => ReadingResultSheet(result: result));
  if (!context.mounted || destination == null) return;
  if (destination == 'reflect') {
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => JournalEditorSheet(
            initialLinkedRef: result.reference,
            initialLinkedRefRoute: JourneyContent.route(result.reference)));
  } else {
    context.push(destination);
  }
}

class ReadingResultSheet extends StatelessWidget {
  final ReadingCompletion result;
  const ReadingResultSheet({super.key, required this.result});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = context.read<AppProvider>();
    final achievements =
        app.achievements.where((a) => result.achievementIds.contains(a.id));
    return ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .88),
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    const Icon(Icons.check_circle_outline),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text('Reading saved',
                            style: theme.textTheme.headlineSmall)),
                    IconButton(
                        tooltip: 'Close reading result',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close))
                  ]),
                  const SizedBox(height: 10),
                  Text(result.reference, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Text(
                      result.xp > 0
                          ? '+${result.xp} XP earned in this reading'
                          : 'Your reading is recorded. Previously earned XP is kept.',
                      style: theme.textTheme.titleMedium),
                  if (result.levelAfter > result.levelBefore)
                    Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('Level ${result.levelAfter} reached',
                            style: theme.textTheme.titleLarge)),
                  if (!result.qualified)
                    const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                            'Chapter progress saved. Journey steps, reading quests, and streak credit require 45 seconds in the reader. Keep reading, then complete again; chapter XP will not repeat.')),
                  for (final change in result.changes)
                    Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(change))
                            ])),
                  for (final a in achievements)
                    Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text('Achievement · ${a.title}')),
                  if (result.keepsakes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                        'Collection additions · ${result.keepsakes.join(', ')}'),
                    TextButton(
                        onPressed: () => Navigator.pop(context, '/collection'),
                        child: const Text('View my collection')),
                  ],
                  if (result.discovered) ...[
                    const Divider(height: 32),
                    const Text('DISCOVERY ADDED'),
                    const SizedBox(height: 8),
                    Text('The Shepherd’s Care',
                        style: theme.textTheme.titleLarge),
                    const Text(
                        'Psalm 23 now has a permanent place in your Codex.'),
                    TextButton(
                        onPressed: () => Navigator.pop(context, '/discoveries'),
                        child: const Text('Open my discovery'))
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                      onPressed: () => Navigator.pop(
                          context,
                          result.nextJourneyId == null
                              ? '/journeys'
                              : '/journeys/${result.nextJourneyId}'),
                      child: Text(result.nextJourneyId == null
                          ? 'Explore what comes next'
                          : 'See my next Journey step')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, 'reflect'),
                      child: const Text('Keep a reflection · optional')),
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Keep reading')),
                ])));
  }
}
