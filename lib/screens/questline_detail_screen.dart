import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/models/questline.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/widgets/home_action_button.dart';
import 'package:level_up_your_faith/widgets/journal/journal_editor_sheet.dart';
import 'package:level_up_your_faith/widgets/reward_toast.dart';
import 'package:level_up_your_faith/widgets/sacred/sacred_ui.dart';
import 'package:level_up_your_faith/widgets/common/sacred_linear_progress.dart';

class QuestlineDetailScreen extends StatefulWidget {
  final String questlineId;
  const QuestlineDetailScreen({super.key, required this.questlineId});

  @override
  State<QuestlineDetailScreen> createState() => _QuestlineDetailScreenState();
}

class _QuestlineDetailScreenState extends State<QuestlineDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _stepKeys = <String, GlobalKey>{};
  bool _didAutoScroll = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Quest', style: Theme.of(context).textTheme.headlineSmall),
        centerTitle: true,
        actions: const [HomeActionButton()],
      ),
      body: FutureBuilder<QuestlineProgressView?>(
        future: () async {
          final app = context.read<AppProvider>();
          final list = await app.getAvailableQuestlines();
          final def = list.firstWhere((d) => d.id == widget.questlineId, orElse: () => list.first);
          final view = app.getQuestlineProgressView(widget.questlineId);
          if (view != null) return view;
          // if not enrolled, create a fake view for preview
          return QuestlineProgressView(
            questline: def,
            progress: QuestlineProgress(
              questlineId: def.id,
              activeStepIds: def.steps.isEmpty ? const [] : [def.steps.first.id],
              completedStepIds: const [],
              stepQuestIds: const {},
              dateStarted: DateTime.now(),
            ),
          );
        }(),
        builder: (context, snapshot) {
          final view = snapshot.data;
          if (view == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final ql = view.questline;
          final progress = view.progress;
          final ordered = [...ql.steps]..sort((a, b) => a.order.compareTo(b.order));
          final activeId = progress.activeStepIds.isEmpty ? null : progress.activeStepIds.first;
          final completed = progress.completedStepIds.length;
          final total = ordered.length;
          final pct = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
          final currentIndex = activeId == null
              ? total
              : (ordered.indexWhere((e) => e.id == activeId) + 1).clamp(1, total);

          // Prepare keys for ensureVisible
          for (final s in ordered) {
            _stepKeys.putIfAbsent(s.id, () => GlobalKey());
          }
          // Auto-scroll to active step once
          if (!_didAutoScroll && activeId != null) {
            _didAutoScroll = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final key = _stepKeys[activeId];
              final ctx = key?.currentContext;
              if (ctx != null) {
                Scrollable.ensureVisible(
                  ctx,
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeInOut,
                  alignment: 0.15,
                );
              }
            });
          }
          return FadeSlideIn(
            child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: Text(ql.title, style: Theme.of(context).textTheme.titleLarge)),
                  const SizedBox(width: 8),
                  if ((ql.category).isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25), width: 1),
                      ),
                      child: Text(_categoryBadge(ql.category), style: Theme.of(context).textTheme.labelSmall),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(ql.description, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              SacredLinearProgress(value: pct, minHeight: 10),
              const SizedBox(height: 6),
              Text('Step $currentIndex of $total', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 16),
              ...ordered.map((s) {
                final isDone = progress.completedStepIds.contains(s.id);
                final isActive = activeId == s.id;
                final meta = _parseTemplate(s.questId);
                final cs = Theme.of(context).colorScheme;
                return SacredCard(
                  key: _stepKeys[s.id],
                  margin: const EdgeInsets.only(bottom: 10),
                  borderSide: isActive
                      ? BorderSide(color: cs.primary, width: 1)
                      : null,
                  child: Opacity(
                    opacity: isDone ? 0.72 : 1.0,
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isDone
                                ? Icons.check_circle_rounded
                                : isActive
                                    ? Icons.play_circle_rounded
                                    : Icons.flag_rounded,
                            color: isDone
                                ? Theme.of(context).colorScheme.primary
                                : isActive
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Step ${ordered.indexOf(s) + 1}', style: Theme.of(context).textTheme.labelSmall),
                                Text(s.titleOverride ?? _deriveTitle(s), style: Theme.of(context).textTheme.titleSmall),
                                if ((s.descriptionOverride ?? '').isNotEmpty)
                                  Text(s.descriptionOverride!, style: Theme.of(context).textTheme.labelSmall),
                                if ((meta['ref'] as String).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(meta['ref'] as String, style: Theme.of(context).textTheme.labelSmall),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                       Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if ((meta['type'] == 'read' || meta['type'] == 'readChapter') && (meta['ref'] as String).isNotEmpty)
                            OutlinedButton.icon(
                              icon: Icon(Icons.menu_book_rounded, color: Theme.of(context).colorScheme.primary),
                              label: const Text('Go to passage'),
                              onPressed: () {
                                final app = context.read<AppProvider>();
                                app.recordQuestStepInteraction(ql.id, s.id, 'readOpened');
                                final encoded = Uri.encodeComponent(meta['ref'] as String);
                                context.go('/verses?ref=$encoded');
                              },
                            ),
                          if (meta['type'] == 'reflection')
                            OutlinedButton.icon(
                              icon: Icon(Icons.edit_note_rounded, color: Theme.of(context).colorScheme.primary),
                              label: const Text('Write in Journal'),
                              onPressed: () async {
                                RewardToast.setBottomSheetOpen(true);
                                await showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (ctx) {
                                    return JournalEditorSheet(
                                      initialTitle: 'Reflection — ${ql.title}',
                                      initialBody: (s.descriptionOverride ?? '').isNotEmpty
                                          ? s.descriptionOverride!
                                          : 'What did God highlight to you?',
                                       initialTags: const ['Quest'],
                                      // Questline context for auto-complete on save
                                      questlineId: ql.id,
                                      stepId: s.id,
                                    );
                                  },
                                );
                                RewardToast.setBottomSheetOpen(false);
                              },
                            ),
                           if (meta['type'] == 'pray')
                             OutlinedButton.icon(
                               icon: Icon(Icons.favorite_rounded, color: Theme.of(context).colorScheme.primary),
                               label: const Text('Open Prayer Guide'),
                               onPressed: () async {
                                 final app = context.read<AppProvider>();
                                 app.recordQuestStepInteraction(ql.id, s.id, 'prayerOpened');
                                 await _openPrayerGuide(context, title: ql.title, onDone: () async {
                                   await context.read<AppProvider>().markQuestlineStepDone(ql.id, s.id, stepXp: 25);
                                   if (mounted) RewardToast.showSuccess(context, title: 'Well done on completing your quest!', subtitle: '+25 XP');
                                 });
                               },
                             ),
                          if (meta['type'] == 'memorize')
                            OutlinedButton.icon(
                              icon: Icon(Icons.psychology_alt_rounded, color: Theme.of(context).colorScheme.primary),
                              label: const Text('Open Memorization'),
                              onPressed: () {
                                final app = context.read<AppProvider>();
                                app.recordQuestStepInteraction(ql.id, s.id, 'memorizeOpened');
                                context.push('/memorization');
                              },
                            ),
                          Consumer<AppProvider>(
                            builder: (ctx, app, _) {
                              final type = meta['type'];
                              final requiresRead = (type == 'read' || type == 'readChapter');
                              final requiresMem = (type == 'memorize');
                               final requiresPrayer = (type == 'pray');
                               final showManualDone = !isDone && !requiresMem && !requiresRead && type != 'reflection'
                                  ? true
                                   : !isDone && (requiresRead || requiresMem || requiresPrayer);

                              if (!showManualDone || type == 'reflection') {
                                return const SizedBox.shrink();
                              }

                              bool enabled = true;
                              String? helper;
                              if (requiresRead) {
                                enabled = app.hasQuestStepInteraction(ql.id, s.id, 'readOpened');
                                if (!enabled) helper = 'Open the passage before completing this step.';
                              } else if (requiresMem) {
                                enabled = app.hasQuestStepInteraction(ql.id, s.id, 'memorizeOpened');
                                if (!enabled) helper = 'Open Memorization before completing this step.';
                                } else if (requiresPrayer) {
                                  enabled = app.hasQuestStepInteraction(ql.id, s.id, 'prayerOpened');
                                  if (!enabled) helper = 'Open the prayer guide before completing this step.';
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ElevatedButton.icon(
                                    icon: Icon(Icons.check_rounded, color: Theme.of(context).colorScheme.onPrimary),
                                    label: const Text('Mark as done'),
                                    onPressed: enabled
                                        ? () async {
                                             await context.read<AppProvider>().markQuestStepDone(ql.id, s.id, stepXp: 25);
                                            if (context.mounted) {
                                              RewardToast.showSuccess(context, title: 'Well done on completing your quest!', subtitle: '+25 XP');
                                            }
                                          }
                                        : null,
                                  ),
                                  if (helper != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        helper,
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              Builder(builder: (ctx) {
                if (progress.isCompleted || activeId == null) {
                  return ElevatedButton.icon(
                    icon: Icon(Icons.explore_rounded, color: Theme.of(context).colorScheme.onPrimary),
                    label: const Text('Browse Quests'),
                    onPressed: () => context.push('/quests'),
                  );
                }
                final s = ordered.firstWhere((e) => e.id == activeId, orElse: () => ordered.first);
                final meta = _parseTemplate(s.questId);
                return ElevatedButton.icon(
                  icon: Icon(_iconForType(meta['type']), color: Theme.of(context).colorScheme.onPrimary),
                  label: const Text('Do this step'),
                  onPressed: () async {
                    final type = meta['type'];
                    if (type == 'read' || type == 'readChapter') {
                      final ref = meta['ref'] as String;
                      if (ref.isNotEmpty) {
                        context.read<AppProvider>().recordQuestStepInteraction(ql.id, s.id, 'readOpened');
                        final encoded = Uri.encodeComponent(ref);
                        if (context.mounted) context.go('/verses?ref=$encoded');
                      } else {
                        if (context.mounted) context.push('/quest/${ql.id}');
                      }
                    } else if (type == 'reflection') {
                      RewardToast.setBottomSheetOpen(true);
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) {
                          return JournalEditorSheet(
                            initialTitle: 'Reflection — ${ql.title}',
                            initialBody: (s.descriptionOverride ?? '').isNotEmpty ? s.descriptionOverride! : 'What did God highlight to you?',
                            initialTags: const ['Quest'],
                            questlineId: ql.id,
                            stepId: s.id,
                          );
                        },
                      );
                      RewardToast.setBottomSheetOpen(false);
                    } else if (type == 'memorize') {
                      context.read<AppProvider>().recordQuestStepInteraction(ql.id, s.id, 'memorizeOpened');
                      if (context.mounted) context.push('/memorization');
                    } else if (type == 'pray') {
                      final app = context.read<AppProvider>();
                      app.recordQuestStepInteraction(ql.id, s.id, 'prayerOpened');
                      await _openPrayerGuide(context, title: ql.title, onDone: () async {
                        await context.read<AppProvider>().markQuestlineStepDone(ql.id, s.id, stepXp: 25);
                        if (mounted) RewardToast.showSuccess(context, title: 'Well done on completing your quest!', subtitle: '+25 XP');
                      });
                    } else {
                      if (context.mounted) context.push('/quest/${ql.id}');
                    }
                  },
                );
              }),
            ],
          ));
        },
      ),
    );
  }

  Future<void> _openPrayerGuide(BuildContext context, {required String title, required Future<void> Function() onDone}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final cs = theme.colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.favorite, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Prayer — $title', style: theme.textTheme.titleLarge)),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: Icon(Icons.close, color: cs.onSurface.withValues(alpha: 0.7)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Take a quiet moment. Breathe. Speak to God about what you\'re reading and how it touches your life today. Close with “Amen.”',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.check, color: cs.onPrimary),
                  label: const Text('Amen'),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await onDone();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _categoryBadge(String category) {
    switch (category) {
      case 'book':
        return 'Book Quest';
      case 'onboarding':
        return 'Getting Started';
      case 'seasonal':
        return 'Theme';
      case 'streak':
        return 'Streak';
      default:
        return category[0].toUpperCase() + category.substring(1);
    }
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'read':
      case 'readChapter':
        return Icons.menu_book_rounded;
      case 'reflection':
        return Icons.edit_note_rounded;
      case 'memorize':
        return Icons.psychology_alt_rounded;
      case 'pray':
        return Icons.favorite_rounded;
      default:
        return Icons.play_arrow_rounded;
    }
  }

  String _deriveTitle(QuestlineStep s) {
    if (s.questId.startsWith('tpl:')) {
      final parts = s.questId.split(':');
      final kind = parts.length > 1 ? parts[1] : '';
      final payload = parts.length > 2 ? s.questId.substring('tpl:$kind:'.length) : '';
      switch (kind) {
        case 'read':
        case 'readChapter':
          return 'Read $payload';
        case 'reflection':
          return 'Write a Reflection';
        case 'pray':
          return 'Spend time in prayer';
        case 'memorize':
          return payload.isNotEmpty ? 'Memorize $payload' : 'Memorize a verse';
        default:
          return 'Questline Step';
      }
    }
    return 'Questline Step';
  }

  Map<String, String> _parseTemplate(String questId) {
    try {
      if (!questId.startsWith('tpl:')) return const {'type': '', 'ref': ''};
      final parts = questId.split(':');
      final kind = parts.length > 1 ? parts[1] : '';
      final payload = parts.length > 2 ? questId.substring('tpl:$kind:'.length) : '';
      if (kind == 'read' || kind == 'readChapter') {
        return {'type': kind, 'ref': payload};
      }
      if (kind == 'reflection') return {'type': 'reflection', 'ref': ''};
      if (kind == 'pray') return {'type': 'pray', 'ref': ''};
      if (kind == 'memorize') return {'type': 'memorize', 'ref': payload};
      return {'type': kind, 'ref': payload};
    } catch (_) {
      return const {'type': '', 'ref': ''};
    }
  }
}
