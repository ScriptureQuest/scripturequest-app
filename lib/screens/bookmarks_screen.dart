import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/theme.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final keys = context.watch<AppProvider>().bookmarkKeys;

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: GamerColors.accent),
                onPressed: () => context.pop(),
              )
            : null,
        title: const Text('Bookmarks'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: keys.isEmpty ? _emptyState(context) : _list(keys, context),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GamerColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GamerColors.accent.withValues(alpha: 0.20), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No bookmarks yet.', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 6),
            Text(
              'Bookmark a chapter or verse to find it quickly later.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: GamerColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(List<String> keys, BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      itemCount: keys.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final key = keys[index];
        final parsed = _parseKey(key);
        final title = parsed['title'] as String? ?? key;

        return ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: const Icon(Icons.bookmark, color: GamerColors.accent),
          title: Text(title),
          subtitle: const Text('Tap to open in Bible'),
          onTap: () {
            final ref = Uri.encodeComponent('${parsed['book']} ${parsed['chapter']}');
            context.push('/verses?ref=$ref');
          },
        );
      },
    );
  }

  Map<String, Object> _parseKey(String key) {
    final parts = key.split(':');
    if (parts.length < 2) return {'title': key, 'book': key, 'chapter': 1};
    final book = parts[0];
    final chapter = int.tryParse(parts[1]) ?? 1;
    if (parts.length == 2) {
      return {
        'book': book,
        'chapter': chapter,
        'title': '$book $chapter',
      };
    }
    final verse = int.tryParse(parts[2]) ?? 1;
    return {
      'book': book,
      'chapter': chapter,
      'verse': verse,
      'title': '$book $chapter:$verse',
    };
  }
}
