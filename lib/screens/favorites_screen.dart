import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/widgets/home_action_button.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final items = [...provider.bookmarks]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return Scaffold(
          appBar: AppBar(
            title: Text('Favorite Scriptures', style: Theme.of(context).textTheme.headlineSmall),
            leading: Navigator.of(context).canPop()
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: GamerColors.accent),
                    onPressed: () => context.pop(),
                  )
                : null,
            centerTitle: true,
            actions: const [HomeActionButton()],
          ),
          body: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text('No favorites yet. Add one from the Bible tab ✨', style: Theme.of(context).textTheme.bodyLarge),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final bm = items[index];
                    return InkWell(
                      onTap: () => context.push('/verses?ref=${Uri.encodeComponent(bm.reference)}'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: GamerColors.darkCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: GamerColors.accent.withValues(alpha: 0.25), width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bookmark, color: GamerColors.accent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bm.reference,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatDate(bm.createdAt),
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove',
                              icon: const Icon(Icons.delete_outline, color: GamerColors.textSecondary),
                              onPressed: () async {
                                await provider.removeBookmark(bm.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: GamerColors.darkSurface,
                                      content: Text('Removed from Favorites'),
                                    ),
                                  );
                                }
                              },
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    // ISO-like short without seconds
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
