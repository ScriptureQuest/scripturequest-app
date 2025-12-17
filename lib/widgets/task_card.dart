import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:level_up_your_faith/models/quest_model.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/services/gear_inventory_service.dart';
import 'package:level_up_your_faith/data/gear_seeds.dart';
import 'package:level_up_your_faith/models/gear_item.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:level_up_your_faith/modals/task_complete_modal.dart';
import 'package:level_up_your_faith/widgets/reward_toast.dart';

class TaskCard extends StatelessWidget {
  final TaskModel quest;

  const TaskCard({super.key, required this.quest});

  IconData _getQuestIcon() {
    switch (quest.type) {
      case 'daily':
        return Icons.today_rounded;
      case 'weekly':
        return Icons.date_range_rounded;
      case 'challenge':
        return Icons.emoji_events_rounded;
      default:
        return Icons.flag_rounded;
    }
  }

  Color _getQuestColor() {
    final cat = quest.category.isNotEmpty ? quest.category : quest.type;
    switch (cat) {
      case 'daily':
        return GamerColors.neonCyan;
      case 'weekly':
        return GamerColors.neonPurple;
      case 'beginner':
        return GamerColors.success;
      case 'event':
        return GamerColors.accentSecondary;
      default:
        return GamerColors.accent;
    }
  }

  Color _difficultyColor() {
    switch (quest.difficulty.toLowerCase()) {
      case 'easy':
        return GamerColors.success;
      case 'medium':
        return GamerColors.accent;
      case 'hard':
        return GamerColors.accentSecondary;
      default:
        return GamerColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final questColor = _getQuestColor();
    final progress = quest.progress;
    final isManual = !quest.isAutoTracked;
    // Theme references available via Theme.of(context)
    final purple = Theme.of(context).extension<PurpleUi>();

    return AnimatedScale(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      scale: quest.isCompleted ? 0.98 : 1.0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: quest.isCompleted ? 0.75 : 1.0,
        child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          // Unify card outline for Purple theme; keep success highlight when completed
          color: quest.isCompleted
              ? GamerColors.success.withValues(alpha: 0.5)
              : (purple?.cardOutline ?? questColor.withValues(alpha: 0.3)),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Title
          Row(
            children: [
              Icon(_getQuestIcon(), color: questColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  quest.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration: quest.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                        decorationColor: GamerColors.textTertiary,
                      ),
                ),
              ),
              if (quest.isCompleted)
                const Icon(Icons.check_circle_rounded, color: GamerColors.success, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          // Secondary description: max 2 lines, ellipsis
          Text(
            quest.description,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Streak Recovery badge & countdown if applicable
          Consumer<AppProvider>(builder: (context, provider, _) {
            final isRecovery = provider.activeStreakRecoveryQuestId != null &&
                provider.activeStreakRecoveryQuestId == quest.id &&
                provider.hasActiveStreakRecoveryQuest;
            if (!isRecovery) return const SizedBox.shrink();
            final exp = provider.streakRecoveryExpiresAt;
            String timeLeft = '';
            if (exp != null) {
              final now = DateTime.now();
              final diff = exp.difference(now);
              if (diff.inDays >= 2) {
                timeLeft = 'Expires in ${diff.inDays} days';
              } else if (diff.inDays == 1) {
                timeLeft = 'Expires tomorrow';
              } else if (diff.inHours > 0) {
                timeLeft = 'Expires in ${diff.inHours}h';
              } else {
                final mins = diff.inMinutes.clamp(0, 59);
                timeLeft = 'Expires today (${mins}m)';
              }
            }
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: GamerColors.accentSecondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: GamerColors.accentSecondary.withValues(alpha: 0.45), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite, size: 14, color: GamerColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('Streak Recovery', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: GamerColors.textSecondary)),
                      ],
                    ),
                  ),
                  if (timeLeft.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Row(children: [
                      const Icon(Icons.timer_outlined, size: 14, color: GamerColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(timeLeft, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: GamerColors.textTertiary)),
                    ])
                  ]
                ],
              ),
            );
          }),
          if ((quest.scriptureReference ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.menu_book_rounded, size: 14, color: GamerColors.textTertiary),
                const SizedBox(width: 6),
                Text(
                  quest.scriptureReference!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: GamerColors.textTertiary),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // Bottom row: Left — task category chip; Right — XP reward text with icon
          Row(
            children: [
              _buildCategoryPillStrong(context),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stars_rounded, color: purple?.accent ?? Theme.of(context).colorScheme.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '+${quest.xpReward} XP',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.info_rounded),
              label: const Text('Details'),
              onPressed: () => _showDetailsSheet(context),
            ),
          ),

          const SizedBox(height: 4),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: (quest.isInProgress || quest.isCompleted) ? 1 : 0.0,
            child: (quest.isInProgress || quest.isCompleted)
                ? Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: purple?.progressTrack ?? GamerColors.darkSurface,
                            borderRadius: BorderRadius.circular(purple != null ? 8 : 4),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(purple != null ? 8 : 4),
                            child: FractionallySizedBox(
                              widthFactor: progress,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: (purple == null)
                                      ? LinearGradient(
                                          colors: quest.isCompleted
                                              ? [GamerColors.success, GamerColors.success]
                                              : [questColor, questColor.withValues(alpha: 0.6)],
                                        )
                                      : null,
                                  color: purple?.progressFill,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('${quest.currentProgress}/${quest.targetCount}', style: Theme.of(context).textTheme.labelMedium),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 12),
          Consumer<AppProvider>(
            builder: (context, provider, _) {
              if (quest.isCompleted) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: GamerColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: GamerColors.success.withValues(alpha: 0.4), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           const Icon(Icons.check_circle_rounded, color: GamerColors.success, size: 18),
                          const SizedBox(width: 8),
                          Text('Completed', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: GamerColors.success)),
                        ],
                      ),
                    ),
                    if (quest.completedAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Completed on ${_formatDate(quest.completedAt!)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: GamerColors.textTertiary),
                      ),
                    ]
                  ],
                );
              }

              if (quest.isNotStarted) {
                return SizedBox(
                  width: double.infinity,
                    child: ElevatedButton.icon(
                    icon: Icon(Icons.play_arrow_rounded, color: Theme.of(context).colorScheme.onPrimary),
                    label: const Text('Start Task'),
                    onPressed: () async {
                      await provider.startQuest(quest.id);
                      if (context.mounted) {
                        _navigateForQuestType(context, provider);
                      }
                    },
                  ),
                );
              }

              // In progress controls
              return Builder(builder: (ctx) {
                final requiresScripture = (quest.scriptureReference ?? '').isNotEmpty;
                final hasOpened = context.read<AppProvider>().hasOpenedScriptureForQuest(quest.id);
                final scriptureLocked = requiresScripture && !hasOpened;
                final hasMetTarget = quest.currentProgress >= quest.targetCount;
                // Auto-tracked: only allow completion from UI after progress meets target
                final canCompleteAuto = !scriptureLocked && hasMetTarget;
                // Manual: allow gentle one-tap completion when user has done the task
                final canCompleteManual = !scriptureLocked;

                final enabled = isManual ? canCompleteManual : canCompleteAuto;
                final label = isManual ? 'Mark Complete' : 'Complete';

                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.check_rounded, color: Theme.of(context).colorScheme.onPrimary),
                    label: Text(label),
                    onPressed: enabled ? () => _handleComplete(context) : null,
                  ),
                );
              });
            },
          ),
          // Helper hint when completion is locked until scripture opened
          Consumer<AppProvider>(
            builder: (context, provider, _) {
              final requiresScripture = (quest.scriptureReference ?? '').isNotEmpty;
              final hasOpened = provider.hasOpenedScriptureForQuest(quest.id);
              if (!(requiresScripture && !hasOpened) || quest.isCompleted) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_clock_rounded, size: 16, color: GamerColors.textTertiary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Open the scripture for this task before completing.',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: GamerColors.textTertiary),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
        ),
      ),
    );
  }

  // ---------------------- Chips & Labels ----------------------
  // Strong category pill used in the bottom row per spec
  Widget _buildCategoryPillStrong(BuildContext context) {
    late final String label;
    late final Color color;

    if (quest.isWeekly || quest.category == 'weekly' || quest.questFrequency == 'weekly') {
      label = 'WEEKLY QUEST';
      color = GamerColors.neonPurple;
    } else if (quest.category == 'event' || quest.category == 'seasonal') {
      label = 'EVENT QUEST';
      color = GamerColors.accentSecondary;
    } else {
      final TaskCategory cat = quest.resolvedCategory;
      switch (cat) {
        case TaskCategory.daily:
          label = 'DAILY QUEST';
          color = Theme.of(context).colorScheme.primary;
          break;
        case TaskCategory.nightly:
          label = 'NIGHTLY QUEST';
          color = Theme.of(context).colorScheme.secondary;
          break;
        case TaskCategory.reflection:
          label = 'REFLECTION';
          color = Theme.of(context).colorScheme.tertiary;
          break;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: GamerColors.textSecondary,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
  Widget _buildCategoryChip(BuildContext context) {
    final TaskCategory cat = quest.resolvedCategory;
    late final String label;
    late final Color color;
    switch (cat) {
      case TaskCategory.daily:
        label = 'Daily';
        color = Theme.of(context).colorScheme.primary;
        break;
      case TaskCategory.nightly:
        label = 'Nightly';
        color = Theme.of(context).colorScheme.secondary;
        break;
      case TaskCategory.reflection:
        label = 'Reflection';
        color = Theme.of(context).colorScheme.tertiary;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: GamerColors.textSecondary)),
    );
  }
  Widget _buildTypeChip(BuildContext context) {
    final color = _typeColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_typeIcon(), size: 14, color: GamerColors.textSecondary),
          const SizedBox(width: 6),
          Text(_typeLabel(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: GamerColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildFocusChip(BuildContext context) {
    final color = GamerColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.label_important_outline, size: 14, color: GamerColors.textSecondary),
          const SizedBox(width: 6),
          Text(quest.spiritualFocus!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: GamerColors.textSecondary)),
        ],
      ),
    );
  }

  String _typeLabel() {
    switch (quest.questType) {
      case 'prayer':
        return 'Prayer';
      case 'reflection':
        return 'Reflection';
      case 'service':
        return 'Service';
      case 'community':
        return 'Community';
      default:
        return 'Reading';
    }
  }

  IconData _typeIcon() {
    switch (quest.questType) {
      case 'prayer':
        return Icons.self_improvement_rounded;
      case 'reflection':
        return Icons.edit_note_rounded;
      case 'service':
        return Icons.volunteer_activism_rounded;
      case 'community':
        return Icons.groups_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  Color _typeColor() {
    switch (quest.questType) {
      case 'prayer':
        return GamerColors.accentSecondary;
      case 'reflection':
        return GamerColors.textSecondary;
      case 'service':
        return GamerColors.success;
      case 'community':
        return GamerColors.danger;
      default:
        return GamerColors.accent;
    }
  }

  // ---------------------- Quest Type Navigation ----------------------
  /// Navigates to the appropriate screen based on quest type.
  /// 
  /// Safety guarantee (v2.1):
  /// - EVERY quest type ALWAYS resolves to a non-null Start action
  /// - Unknown/missing quest types fallback to Details sheet
  /// - Defensive warning logged in debug builds if fallback is used
  void _navigateForQuestType(BuildContext context, AppProvider provider) {
    final qt = quest.questType.trim().toLowerCase();
    final ref = (quest.scriptureReference ?? '').trim();

    // Track if we used the fallback path
    bool usedFallback = false;

    switch (qt) {
      case 'scripture_reading':
        if (ref.isNotEmpty) {
          provider.markQuestScriptureOpened(quest.id);
          final encoded = Uri.encodeComponent(ref);
          context.go('/verses?ref=$encoded');
        } else {
          final lastRef = provider.lastBibleReference ?? 'John 1';
          final encoded = Uri.encodeComponent(lastRef);
          context.go('/verses?ref=$encoded');
        }
        break;
      case 'reflection':
      case 'journal':
      case 'gratitude':
      case 'prayer':
        context.push('/journal');
        break;
      case 'memorization':
      case 'memorize':
        context.push('/favorites');
        break;
      case 'service':
      case 'community':
        _showDetailsSheet(context);
        break;
      case 'routine':
        context.go('/verses');
        break;
      default:
        // Safety fallback: unknown quest types always get Details sheet
        usedFallback = true;
        _showDetailsSheet(context);
        break;
    }

    // Defensive debug warning for unknown quest types (debug builds only)
    if (usedFallback && kDebugMode) {
      debugPrint('[TaskCard] WARNING: Unknown quest type "$qt" for quest "${quest.title}" - using fallback Details sheet');
    }
  }

  // ---------------------- Details Sheet ----------------------
  Future<void> _showDetailsSheet(BuildContext context) async {
    RewardToast.setBottomSheetOpen(true);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GamerColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getQuestIcon(), color: _getQuestColor(), size: 22),
                  const SizedBox(width: 10),
                  Expanded(child: Text(quest.title, style: Theme.of(ctx).textTheme.titleLarge)),
                ],
              ),
              const SizedBox(height: 8),
              Text(quest.description, style: Theme.of(ctx).textTheme.bodyMedium),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _buildTypeChip(ctx),
                if ((quest.spiritualFocus ?? '').isNotEmpty) _buildFocusChip(ctx),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _difficultyColor().withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _difficultyColor().withValues(alpha: 0.4), width: 1),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.bolt, size: 14, color: GamerColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(quest.difficulty, style: Theme.of(ctx).textTheme.labelSmall?.copyWith(color: GamerColors.textSecondary)),
                  ]),
                ),
              ]),
              if ((quest.scriptureReference ?? '').isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(children: [
                  const Icon(Icons.menu_book_rounded, size: 16, color: GamerColors.textTertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(quest.scriptureReference!, style: Theme.of(ctx).textTheme.labelMedium?.copyWith(color: GamerColors.textTertiary)),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Open Scripture'),
                    onPressed: () {
                      // Mark that user opened the scripture for this task (gate for completion)
                      try {
                        context.read<AppProvider>().markQuestScriptureOpened(quest.id);
                      } catch (e) {
                        debugPrint('markQuestScriptureOpened from TaskCard sheet failed: $e');
                      }
                      final ref = Uri.encodeComponent(quest.scriptureReference!);
                      Navigator.of(ctx).pop();
                      context.go('/verses?ref=$ref');
                    },
                  ),
                ]),
              ],
              // ================= Possible Rewards preview =================
              if (quest.possibleRewardGearIds.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Possible Rewards', style: Theme.of(ctx).textTheme.titleSmall),
                const SizedBox(height: 8),
                _PossibleRewardsPreview(gearIds: quest.possibleRewardGearIds),
                const SizedBox(height: 6),
                Text(
                  (quest.guaranteedFirstClearGearId != null && quest.guaranteedFirstClearGearId!.trim().isNotEmpty)
                      ? 'First clear guarantees one of these artifacts.'
                      : 'Artifacts you may earn by completing this task.',
                  style: Theme.of(ctx).textTheme.labelSmall?.copyWith(color: GamerColors.textTertiary),
                ),
              ],
              if ((quest.reflectionPrompt ?? '').isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('Reflection', style: Theme.of(ctx).textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(quest.reflectionPrompt!, style: Theme.of(ctx).textTheme.bodySmall),
              ],
              const SizedBox(height: 18),
              Consumer<AppProvider>(builder: (context, provider, _) {
                final isManual = !quest.isAutoTracked;
                final requiresScripture = (quest.scriptureReference ?? '').isNotEmpty;
                final hasOpened = context.read<AppProvider>().hasOpenedScriptureForQuest(quest.id);
                final scriptureLocked = requiresScripture && !hasOpened;
                final hasMetTarget = quest.currentProgress >= quest.targetCount;
                final canComplete = isManual ? !scriptureLocked : (!scriptureLocked && hasMetTarget);
                final label = isManual ? 'Mark Complete' : 'Complete';
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                    icon: Icon(Icons.play_arrow_rounded, color: Theme.of(context).colorScheme.primary),
                        label: const Text('Start'),
                        onPressed: () async {
                          await provider.startQuest(quest.id);
                          if (context.mounted) {
                            Navigator.of(ctx).pop();
                            _navigateForQuestType(context, provider);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: Icon(Icons.check_rounded, color: Theme.of(context).colorScheme.onPrimary),
                      label: Text(label),
                      onPressed: canComplete
                          ? () async {
                              if (context.mounted) Navigator.of(ctx).pop();
                              await _handleComplete(context);
                            }
                          : null,
                    ),
                  ],
                );
              })
            ],
          ),
        );
      },
    ).whenComplete(() => RewardToast.setBottomSheetOpen(false));
  }

  // ---------------------- Completion Flow ----------------------
  Future<void> _handleComplete(BuildContext context) async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    if ((quest.reflectionPrompt ?? '').isNotEmpty) {
      final controller = TextEditingController();
      RewardToast.setBottomSheetOpen(true);
      final result = await showModalBottomSheet<String?>(
        context: context,
        isScrollControlled: true,
        backgroundColor: GamerColors.darkCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick Reflection', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(quest.reflectionPrompt!, style: Theme.of(ctx).textTheme.bodyMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Type a quick thought (optional)...',
                    filled: true,
                    fillColor: GamerColors.darkSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: GamerColors.accent.withValues(alpha: 0.2), width: 1),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(null),
                        child: const Text('Skip'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
                        child: const Text('Done'),
                      ),
                    )
                  ],
                )
              ],
            ),
          );
        },
      ).whenComplete(() => RewardToast.setBottomSheetOpen(false));
      // If reflection text provided, save to Journal via provider
      if (result != null && result.isNotEmpty) {
        try {
          final unlockedFromJournal = await provider.addJournalEntryFromReflection(quest: quest, reflectionText: result);
          if (context.mounted && unlockedFromJournal.isNotEmpty) {
            final a = unlockedFromJournal.first;
            final xp = a.xpReward;
            RewardToast.showAchievementUnlocked(
              context,
              title: a.title,
              subtitle: xp > 0 ? '+$xp XP' : null,
            );
          }
        } catch (e) {
          debugPrint('Failed to add journal entry: $e');
        }
      }
    }

    // Mark complete without auto-claim; then present the modal to claim.
    await provider.completeQuest(quest.id, claimRewards: false);
    if (!context.mounted) return;

    // Gentle feedback: small snackbar with XP amount, per spec (does not change XP logic)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.stars_rounded, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text('Task complete! +${quest.xpReward} XP'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1600),
      ),
    );
    await showTaskCompleteModal(
      context: context,
      quest: quest,
      onClaim: () async {
        await provider.claimQuestRewards(quest.id);
        if (!context.mounted) return;
        RewardToast.showClaimed(context, title: 'Great job! +XP');
      },
    );
  }
}

class _PossibleRewardsPreview extends StatelessWidget {
  final List<String> gearIds;
  const _PossibleRewardsPreview({required this.gearIds});

  GearItem? _findItem(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return null;
    // exact
    for (final g in kGearSeedList) {
      if (g.id == trimmed) return g;
    }
    // suffix alias
    for (final g in kGearSeedList) {
      if (g.id.endsWith(trimmed)) return g;
    }
    return null;
  }

  IconData _slotIcon(GearItem? item) {
    if (item == null) return Icons.inventory_2_outlined;
    switch (item.slot) {
      case GearSlot.head:
        return Icons.emoji_people_outlined;
      case GearSlot.chest:
        return Icons.checkroom_outlined;
      case GearSlot.hands:
        return Icons.pan_tool_alt_outlined;
      case GearSlot.legs:
        return Icons.hiking_outlined;
      case GearSlot.feet:
        return Icons.directions_walk_outlined;
      case GearSlot.hand:
        return Icons.auto_awesome;
      case GearSlot.charm:
        return Icons.token_outlined;
      case GearSlot.artifact:
        return Icons.auto_awesome_mosaic;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gear = context.read<GearInventoryService?>();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final id in gearIds)
          Builder(builder: (ctx) {
            final item = _findItem(id);
            final owned = (item != null && gear != null) ? gear.containsItem(item.id) : false;
            if (item == null) {
              // Unknown entry
              return _RewardChipUnknown(theme: theme);
            }
            final color = gearRarityColor(item.rarity, theme);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: GamerColors.darkSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_slotIcon(item), color: color, size: 18),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        owned ? item.name : 'Unknown Artifact',
                        style: theme.textTheme.labelMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        owned ? _rarityLabel(item.rarity) : 'Unseen',
                        style: theme.textTheme.labelSmall?.copyWith(color: GamerColors.textTertiary),
                      ),
                    ],
                  )
                ],
              ),
            );
          }),
      ],
    );
  }

  String _rarityLabel(GearRarity r) {
    switch (r) {
      case GearRarity.legendary:
        return 'Legendary';
      case GearRarity.epic:
        return 'Epic';
      case GearRarity.rare:
        return 'Rare';
      case GearRarity.uncommon:
        return 'Uncommon';
      case GearRarity.common:
        return 'Common';
    }
  }
}

class _RewardChipUnknown extends StatelessWidget {
  final ThemeData theme;
  const _RewardChipUnknown({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: GamerColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
           Icon(Icons.help_rounded, color: theme.colorScheme.outline, size: 18),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Unknown Artifact', style: theme.textTheme.labelMedium),
              Text('Unseen', style: theme.textTheme.labelSmall?.copyWith(color: GamerColors.textTertiary)),
            ],
          )
        ],
      ),
    );
  }
}

String _formatDate(DateTime dt) {
  // e.g., Jan 5, 2025
  final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  final m = months[dt.month - 1];
  return '$m ${dt.day}, ${dt.year}';
}
