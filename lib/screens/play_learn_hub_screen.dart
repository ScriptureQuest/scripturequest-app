import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/product/product_ui.dart';
import '../widgets/connected/next_action_panel.dart';
import '../data/activities/activity_catalog.dart';
import '../models/activities/activity.dart';
import '../providers/app_provider.dart';

class PlayLearnHubScreen extends StatefulWidget {
  const PlayLearnHubScreen({super.key});
  @override
  State<PlayLearnHubScreen> createState() => _PlayLearnHubScreenState();
}

class _PlayLearnHubScreenState extends State<PlayLearnHubScreen> {
  ActivityKind? filter;
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    Map<String, dynamic> records = {};
    bool unreadable = false;
    try {
      if (app.currentUser != null) records = app.activityRecords;
    } catch (_) {
      unreadable = true;
    }
    return Scaffold(
        appBar: AppBar(title: const Text('Play & Learn')),
        body: ProductWidth(
            child: ListView(padding: const EdgeInsets.all(24), children: [
          Text('Read it. Notice it. Play with it.',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          const Text(
              'Find words in their passage, solve Scripture clues, or return to a familiar challenge. Every puzzle leads back to the Bible.'),
          const SizedBox(height: 20),
          Text('Level ${app.currentUser?.currentLevel ?? 1} · ${app.currentUser?.totalXP ?? 0} XP', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          if (unreadable)
            const Text(
                'Activity history could not be read. It has been preserved; restart before saving new results.')
          else
            Text(
                '${records.length} / ${ActivityCatalog.all.length} activities explored · replays welcome'),
          const SizedBox(height: 12),
          const Text(
              'Rewards are earned once per activity. Try fewer hints on a replay; there is no timer or pressure to keep a streak.'),
          const SizedBox(height: 20),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ChoiceChip(
                label: const Text('All activities'),
                selected: filter == null,
                onSelected: (_) => setState(() => filter = null)),
            for (final kind in ActivityKind.values)
              ChoiceChip(
                  label: Text(switch (kind) {
                    ActivityKind.wordSearch => 'Word Search',
                    ActivityKind.crossword => 'Crosswords',
                    ActivityKind.legacy => 'Classics'
                  }),
                  selected: filter == kind,
                  onSelected: (_) => setState(() => filter = kind)),
          ]),
          const SizedBox(height: 20),
          ActivityShelf(children: [
            for (final a in ActivityCatalog.all
                .where((a) => filter == null || a.kind == filter))
              ActivityCard(
                  title: a.title,
                  description:
                      '${a.family}${a.passage == null ? '' : ' · ${a.passage!.label}'}\n${a.description}\n${records[a.id] == null ? 'Not yet completed · ${a.xp} base XP' : a.kind == ActivityKind.legacy ? 'Completed · replay for practice' : 'Completed · best: ${(records[a.id] as Map)['bestHints']} hints'}',
                  route: a.route,
                  icon: switch (a.kind) {
                    ActivityKind.wordSearch => Icons.grid_on,
                    ActivityKind.crossword => Icons.edit_note,
                    ActivityKind.legacy => Icons.extension_outlined
                  },
                  featured: a.kind != ActivityKind.legacy)
          ]),
          const SizedBox(height: 24),
          Text('Remember and keep exploring',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          const ActivityShelf(children: [
            ActivityCard(
                title: 'Practice Verses',
                description:
                    'Your original practice library and saved favorites.',
                route: '/memorization',
                icon: Icons.bookmarks_outlined),
            ActivityCard(
                title: 'Remembered Scripture',
                description: 'Keep honest records of practice and recall.',
                route: '/remembered',
                icon: Icons.psychology_outlined),
          ]),
          const SizedBox(height: 24),
          const NextActionPanel(learning: true),
        ])));
  }
}
