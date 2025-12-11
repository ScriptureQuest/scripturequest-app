import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/models/book_mastery.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/theme.dart';

class BookMasteryDetailSheet extends StatelessWidget {
  final String book;
  final BookMastery mastery;
  const BookMasteryDetailSheet({super.key, required this.book, required this.mastery});

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

  String _tierLabel(String tier) {
    switch (tier) {
      case 'lamp':
        return 'Lamp';
      case 'olive':
        return 'Olive';
      case 'dove':
        return 'Dove';
      case 'scroll':
        return 'Scroll';
      case 'crown':
        return 'Crown';
      default:
        return 'None';
    }
  }

  String _encouragement(String tier) {
    switch (tier) {
      case 'none':
        return 'Begin gently—read a chapter when you feel ready.';
      case 'lamp':
        return 'Lovely start. Let this book light the path ahead.';
      case 'olive':
        return 'Peaceful progress. Finishing or reflecting can deepen your roots.';
      case 'dove':
        return 'A calm depth is forming. A small quest can enrich this journey.';
      case 'scroll':
        return 'Your understanding is unfolding. Discovering an artifact adds texture.';
      case 'crown':
        return 'A lifetime friendship with this book. Beautiful.';
      default:
        return '';
    }
  }

  List<String> _nextSteps(String tier, BookMastery m) {
    final steps = <String>[];
    if (m.chaptersRead < m.totalChapters) {
      steps.add('Finish remaining chapters to reach the next tier.');
    }
    if (m.artifactsOwned <= 0) {
      steps.add('Discover an artifact tied to this book in Collection.');
    }
    if (m.questsCompleted <= 0) {
      steps.add('Complete a related quest to deepen your mastery.');
    }
    return steps;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final color = GamerColors.accent;
    final next = _nextSteps(mastery.masteryTier, mastery);
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border.all(color: GamerColors.accent.withValues(alpha: 0.15), width: 1),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: GamerColors.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: GamerColors.darkSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
                    ),
                    child: Icon(_iconForTier(mastery.masteryTier), color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(book, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 2),
                        Text('${_tierLabel(mastery.masteryTier)} Tier', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: GamerColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Metric(label: 'Chapters read', value: '${mastery.chaptersRead} / ${mastery.totalChapters}'),
              const SizedBox(height: 8),
              _Metric(label: 'Times completed', value: '${mastery.timesCompleted}'),
              const SizedBox(height: 8),
              _Metric(label: 'Artifacts discovered', value: '${mastery.artifactsOwned}'),
              const SizedBox(height: 8),
              _Metric(label: 'Related quests completed', value: '${mastery.questsCompleted}'),
              const SizedBox(height: 16),
              Text(_encouragement(mastery.masteryTier), style: Theme.of(context).textTheme.bodyMedium),
              if (next.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...next.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.chevron_right, color: GamerColors.accent, size: 18),
                          const SizedBox(width: 6),
                          Expanded(child: Text(s, style: Theme.of(context).textTheme.labelMedium)),
                        ],
                      ),
                    )),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: GamerColors.accent),
                      label: const Text('Close'),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: GamerColors.darkCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GamerColors.accent.withValues(alpha: 0.15), width: 1),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: GamerColors.textSecondary))),
          const SizedBox(width: 8),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: GamerColors.accent, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
