import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/models/book_mastery.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/screens/book_mastery_detail_sheet.dart';
import 'package:level_up_your_faith/widgets/home_action_button.dart';
import 'package:level_up_your_faith/widgets/reward_toast.dart';

class BookMasteryScreen extends StatelessWidget {
  const BookMasteryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, app, _) {
      final books = AppProvider.bookTotalChapters.keys.toList();
      return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Book Mastery', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 2),
              Text(
                'A lifetime view of your Scripture journey.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: GamerColors.textSecondary),
              ),
            ],
          ),
          centerTitle: true,
          actions: const [HomeActionButton()],
        ),
        body: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: books.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final book = books[index];
            final m = app.bookMasteryService.getOrCreate(book);
            return _BookRow(
              book: book,
              mastery: m,
              onTap: () async {
                RewardToast.setBottomSheetOpen(true);
                await showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => BookMasteryDetailSheet(book: book, mastery: m),
                ).whenComplete(() => RewardToast.setBottomSheetOpen(false));
              },
            );
          },
        ),
      );
    });
  }
}

class _BookRow extends StatelessWidget {
  final String book;
  final BookMastery mastery;
  final VoidCallback onTap;
  const _BookRow({required this.book, required this.mastery, required this.onTap});

  IconData _iconForTier(String tier) {
    switch (tier) {
      case 'lamp':
        return Icons.tips_and_updates;
      case 'olive':
        return Icons.eco;
      case 'dove':
        return Icons.emoji_nature;
      case 'scroll':
        return Icons.menu_book;
      case 'crown':
        return Icons.workspace_premium;
      case 'none':
      default:
        return Icons.circle_outlined;
    }
  }

  Color _colorForTier(String tier) {
    switch (tier) {
      case 'lamp':
        return GamerColors.neonCyan;
      case 'olive':
        return GamerColors.success;
      case 'dove':
        return GamerColors.neonPurple;
      case 'scroll':
        return GamerColors.accent;
      case 'crown':
        return GamerColors.neonPink;
      case 'none':
      default:
        return GamerColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForTier(mastery.masteryTier);
    final chaptersLine = 'Chapters: ${mastery.chaptersRead} / ${mastery.totalChapters} • Completions: ${mastery.timesCompleted}';
    return Material(
      color: GamerColors.darkCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        highlightColor: color.withValues(alpha: 0.06),
        splashColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: GamerColors.darkSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
                ),
                child: Icon(_iconForTier(mastery.masteryTier), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      chaptersLine,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: GamerColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 64,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: mastery.completionPercent,
                    backgroundColor: GamerColors.darkSurface,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
