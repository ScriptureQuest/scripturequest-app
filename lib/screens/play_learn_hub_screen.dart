import 'package:flutter/material.dart';
import '../widgets/product/product_ui.dart';

class PlayLearnHubScreen extends StatelessWidget {
  const PlayLearnHubScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Play & Learn')),
      body: ProductWidth(
          child: ListView(padding: const EdgeInsets.all(24), children: [
        Text('A little challenge. A lasting connection.',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        const Text(
            'Play with Bible words, references, and stories. Take your time; these are opportunities to learn.'),
        const SizedBox(height: 20),
        const ActivityShelf(children: [
          ActivityCard(
              title: 'Matching Game',
              description:
                  'Pair Scripture with its reference. Notice what makes each passage distinct.',
              route: '/matching-game',
              icon: Icons.grid_view_rounded),
          ActivityCard(
              title: 'Verse Scramble',
              description:
                  'Put familiar words back in order, one passage at a time.',
              route: '/verse-scramble',
              icon: Icons.sort_by_alpha),
          ActivityCard(
              title: 'Book Order',
              description: 'Find your way through the books of the Bible.',
              route: '/book-order-game',
              icon: Icons.view_week_outlined),
          ActivityCard(
              title: 'Emoji Parables',
              description:
                  'Recognize the story, then return to its Scripture context.',
              route: '/emoji-parables',
              icon: Icons.emoji_objects_outlined),
          ActivityCard(
              title: 'Practice Verses',
              description:
                  'Your original practice library and saved favorites remain here.',
              route: '/memorization',
              icon: Icons.bookmarks_outlined),
          ActivityCard(
              title: 'Remembered Scripture',
              description: 'Keep a personal record of practice and recall.',
              route: '/remembered',
              icon: Icons.psychology_outlined),
        ]),
        const SizedBox(height: 24),
        const Text(
            'Looking for something you just read? Learn also connects your Codex discoveries with passage challenges and chapter learning.'),
      ])));
}
