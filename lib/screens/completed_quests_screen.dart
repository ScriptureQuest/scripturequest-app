import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/models/completed_board_quest.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/widgets/home_action_button.dart';

class CompletedQuestsScreen extends StatelessWidget {
  const CompletedQuestsScreen({super.key});

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'daily':
        return Icons.today;
      case 'weekly':
        return Icons.date_range;
      case 'reflection':
        return Icons.edit_note;
      case 'special':
      default:
        return Icons.local_activity;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, p, _) {
      final items = p.completedBoardQuests; // already sorted DESC by date
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: GamerColors.accent),
            onPressed: () => context.pop(),
          ),
          title: Text('Completed Tasks', style: Theme.of(context).textTheme.headlineSmall),
          centerTitle: true,
          actions: const [HomeActionButton()],
        ),
        body: items.isEmpty
            ? Center(
                child: Text(
                  'No completed tasks yet.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemBuilder: (context, index) {
                  final CompletedBoardQuestEntry e = items[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: GamerColors.darkCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GamerColors.accent.withValues(alpha: 0.2), width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(_iconForType(e.type), color: GamerColors.accent, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.title, style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 4),
                              Text('Completed • ${_formatDate(e.completedAt)}',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: GamerColors.textSecondary)),
                            ],
                          ),
                        ),
                        if (_categoryLabel(e.type).isNotEmpty) ...[
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _categoryColor(context, e.type).withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: _categoryColor(context, e.type).withValues(alpha: 0.35), width: 1),
                            ),
                            child: Text(_categoryLabel(e.type), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: GamerColors.textSecondary)),
                          ),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: GamerColors.darkSurface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: GamerColors.accent.withValues(alpha: 0.25), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt, color: GamerColors.accent, size: 16),
                              const SizedBox(width: 6),
                              Text('+${e.xpReward} XP', style: Theme.of(context).textTheme.labelMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: items.length,
              ),
      );
    });
  }
}

String _categoryLabel(String raw) {
  switch (raw) {
    case 'daily':
      return 'Daily';
    case 'weekly':
      return 'Weekly';
    case 'reflection':
      return 'Reflection';
    default:
      return '';
  }
}

Color _categoryColor(BuildContext context, String raw) {
  switch (raw) {
    case 'daily':
      return Theme.of(context).colorScheme.primary;
    case 'weekly':
      return Theme.of(context).colorScheme.secondary;
    case 'reflection':
      return Theme.of(context).colorScheme.tertiary;
    default:
      return Theme.of(context).colorScheme.outline;
  }
}
