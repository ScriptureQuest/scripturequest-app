import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/widgets/bible_reader_styles.dart';
import 'package:level_up_your_faith/theme.dart';

class HighlightsScreen extends StatelessWidget {
  const HighlightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        final keys = app.highlightedVerseKeysRecent;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Highlights'),
            centerTitle: true,
          ),
          body: SafeArea(
            child: (keys.isEmpty)
                ? _emptyState(context)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: keys.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final k = keys[index];
                      final colorKey = app.getHighlightColorKey(k) ?? 'sun';
                      final displayRef = _displayRefFor(k);
                      final navTarget = _chapterOnlyRef(k);
                      final color = BibleReaderStyles.highlightColor(colorKey);
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          // Navigate to the chapter; verse auto-scroll is out-of-scope for v1.0.1
                          context.push(Uri(path: '/verses', queryParameters: {'ref': navTarget}).toString());
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  displayRef,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: GamerColors.textSecondary),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.highlight_alt, size: 48, color: GamerColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'No highlights yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Long‑press a verse in the Bible to add a highlight.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Convert 'Book:Chapter:Verse' -> 'Book Chapter:Verse'
  String _displayRefFor(String verseKey) {
    final parts = verseKey.split(':');
    if (parts.length != 3) return verseKey;
    return '${parts[0]} ${parts[1]}:${parts[2]}';
  }

  // Chapter-only ref for navigation: 'Book Chapter'
  String _chapterOnlyRef(String verseKey) {
    final parts = verseKey.split(':');
    if (parts.length != 3) return verseKey;
    return '${parts[0]} ${parts[1]}';
  }
}
