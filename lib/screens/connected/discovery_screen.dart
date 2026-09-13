import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/widgets/reading_v2/reading_design.dart';
import 'package:level_up_your_faith/widgets/connected/journey_content.dart';
import 'journeys_screen.dart';

class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final discovery = context.watch<AppProvider>().shepherdDiscovery;
    return ConnectedPage(title: 'Codex', children: [
      Text('Discoveries worth returning to.',
          style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 10),
      const Text(
          'Keep a lasting connection between what you read and what you notice.'),
      const SizedBox(height: 24),
      ReadingSurface(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(
            discovery == null
                ? Icons.explore_outlined
                : Icons.auto_stories_outlined,
            size: 40,
            color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(discovery == null ? 'AN INVITATION TO DISCOVER' : 'IN YOUR CODEX',
            style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 10),
        Text('The Shepherd’s Care',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text('Psalm 23 · Images of care, presence, and welcome'),
        const SizedBox(height: 20),
        const Text('Follow the psalm’s images'),
        const SizedBox(height: 8),
        const Text(
            'Verses 1–3 picture a shepherd providing rest, refreshment, and guidance. Verse 4 moves into a dark valley, where the speaker addresses the Lord directly. Verses 5–6 turn toward a prepared table, goodness, mercy, and dwelling with the Lord.'),
        const SizedBox(height: 16),
        const Text(
            'Notice the movement: the setting changes, but the language of care continues. Return to the passage and look for each image yourself.'),
        const SizedBox(height: 16),
        const Text(
            'Reading guide, not additional Scripture. Read the Bible text in context and keep your own questions.'),
        const Divider(height: 32),
        Text(discovery == null
            ? 'Complete Psalm 23 in the reader after the reading-time threshold to add this discovery permanently. You can read this guide now.'
            : 'Added through: ${discovery['source']}. Your discovery stays with you when you return.'),
        const SizedBox(height: 16),
        FilledButton.icon(
            onPressed: () => context.push(JourneyContent.route('Psalms 23')),
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('Return to Psalm 23')),
        TextButton(
            onPressed: () => context.push('/journeys/psalms_of_peace'),
            child: const Text('Explore Psalms of Peace')),
        TextButton(
            onPressed: () => context.push(JourneyContent.route('Psalms 46')),
            child: const Text('Explore next: refuge in Psalm 46')),
      ])),
      const SizedBox(height: 16),
      ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Existing collections'),
          subtitle: const Text(
              'Your previously earned collection remains available.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/collection')),
    ]);
  }
}
