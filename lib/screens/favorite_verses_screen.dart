import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/widgets/home_action_button.dart';

class FavoriteVersesScreen extends StatelessWidget {
  const FavoriteVersesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, app, _) {
      final keys = app.favoriteVerseKeys;
      return Scaffold(
        appBar: AppBar(
          title: Text('Favorite Verses', style: Theme.of(context).textTheme.headlineSmall),
          centerTitle: true,
          leading: Navigator.of(context).canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: GamerColors.accent),
                  onPressed: () => context.pop(),
                )
              : null,
          actions: const [HomeActionButton()],
        ),
        body: keys.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite_border, color: GamerColors.textSecondary, size: 36),
                      const SizedBox(height: 12),
                      Text("You haven't favorited any verses yet.", style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 6),
                      Text('Tap the heart next to a verse while reading to save it here.', style: Theme.of(context).textTheme.labelMedium),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: keys.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _FavoriteVerseTile(verseKey: keys[index]),
              ),
      );
    });
  }
}

class _FavoriteVerseTile extends StatelessWidget {
  final String verseKey; // DisplayBook:Chapter:Verse
  const _FavoriteVerseTile({required this.verseKey});

  (String ref, String book, int ch, int v)? _parse() {
    try {
      final parts = verseKey.split(':');
      if (parts.length != 3) return null;
      final book = parts[0];
      final ch = int.tryParse(parts[1]) ?? 0;
      final v = int.tryParse(parts[2]) ?? 0;
      if (book.trim().isEmpty || ch <= 0 || v <= 0) return null;
      final ref = '$book $ch:$v';
      return (ref, book, ch, v);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parse();
    final app = context.read<AppProvider>();
    final ref = parsed?.$1 ?? verseKey;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GamerColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GamerColors.accent.withValues(alpha: 0.22), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bookmark, color: GamerColors.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ref, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                FutureBuilder<String>(
                  future: app.loadKjvPassage(ref),
                  builder: (context, snapshot) {
                    final txt = snapshot.data ?? '';
                    final lines = txt.split('\n');
                    final body = lines.length > 1 ? lines[1] : txt;
                    final excerpt = body.trim();
                    return Text(
                      excerpt.isEmpty ? 'Verse text not available.' : excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: GamerColors.textSecondary, height: 1.4),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => context.push('/memorization-practice?key=${Uri.encodeComponent(verseKey)}'),
                      icon: const Icon(Icons.self_improvement, size: 18, color: GamerColors.accent),
                      label: const Text('Practice'),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: 'Unfavorite',
                      icon: const Icon(Icons.favorite, color: GamerColors.neonPurple),
                      onPressed: () => context.read<AppProvider>().toggleFavoriteVerse(verseKey),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
