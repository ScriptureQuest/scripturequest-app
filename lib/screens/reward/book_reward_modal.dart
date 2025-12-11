import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:level_up_your_faith/models/reward_event.dart';
import 'package:level_up_your_faith/data/gear_seeds.dart';
import 'package:level_up_your_faith/models/gear_item.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';

class BookRewardModal extends StatefulWidget {
  final RewardEvent event;
  final int index;
  final int total;

  const BookRewardModal({super.key, required this.event, required this.index, required this.total});

  @override
  State<BookRewardModal> createState() => _BookRewardModalState();
}

class _BookRewardModalState extends State<BookRewardModal> with SingleTickerProviderStateMixin {
  bool _revealed = false;
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  GearItem? get _item {
    try {
      for (final g in kGearSeedList) {
        if (g.id == widget.event.gearId) return g;
      }
    } catch (_) {}
    return null;
  }

  Color _rarityGlowColor(ThemeData theme) {
    final item = _item;
    if (item != null) return gearRarityColor(item.rarity, theme);
    switch (widget.event.rarity) {
      case 'legendary':
        return Colors.amberAccent.shade400;
      case 'epic':
        return Colors.purpleAccent.shade400;
      case 'rare':
        return Colors.blueAccent.shade400;
      case 'uncommon':
        return Colors.greenAccent.shade400;
      default:
        return theme.colorScheme.outline.withValues(alpha: 0.7);
    }
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
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onReveal() {
    if (_revealed) return;
    setState(() => _revealed = true);
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = _item;
    final glow = _rarityGlowColor(theme);
    final bookName = widget.event.bookId;
    final questId = widget.event.questId;
    String? questTitle;
    if (questId != null && questId.isNotEmpty) {
      try {
        final app = context.read<AppProvider>();
        questTitle = app.quests.firstWhere((q) => q.id == questId, orElse: () => app.quests.first).title;
      } catch (_) {
        questTitle = null;
      }
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: GamerColors.darkBackground,
        body: Stack(
          children: [
            // Dimmed backdrop
            Container(color: Colors.black.withValues(alpha: 0.6)),
            // Center content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    // Header
                    if (questId != null && questId.isNotEmpty) ...[
                      Text('Quest Complete', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
                      const SizedBox(height: 6),
                      Text(
                        questTitle ?? 'Quest Reward',
                        style: theme.textTheme.titleSmall,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else ...[
                      Text(
                        bookName == null || bookName.isEmpty ? 'Milestone Reward' : 'Book Complete: $bookName',
                        style: theme.textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'You’ve earned a story artifact',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (widget.total > 1)
                      Text(
                        'Artifact ${widget.index} of ${widget.total}',
                        style: theme.textTheme.labelSmall?.copyWith(color: GamerColors.accent),
                      ),
                    const Spacer(),
                    // Avatar silhouette glow behind
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: GamerColors.accent.withValues(alpha: 0.05),
                        boxShadow: [
                          BoxShadow(color: glow.withValues(alpha: 0.25), blurRadius: 28, spreadRadius: 2),
                        ],
                      ),
                      child: Icon(Icons.person_outline, size: 120, color: theme.colorScheme.onSurface.withValues(alpha: 0.18)),
                    ),
                    const SizedBox(height: 18),
                    // Reward card
                    GestureDetector(
                      onTap: _onReveal,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: GamerColors.darkCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: glow.withValues(alpha: _revealed ? 0.7 : 0.35), width: _revealed ? 2 : 1),
                        ),
                        width: double.infinity,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutBack,
                          switchOutCurve: Curves.easeIn,
                          child: _revealed
                              ? Column(
                                  key: const ValueKey('revealed'),
                                  children: [
                                    ScaleTransition(
                                      scale: _scale,
                                      child: Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: glow.withValues(alpha: 0.08),
                                          boxShadow: [
                                            BoxShadow(color: glow.withValues(alpha: 0.35), blurRadius: 30, spreadRadius: 2),
                                          ],
                                        ),
                                        child: Icon(_slotIcon(item), size: 70, color: glow),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      item?.name ?? 'Unknown Artifact',
                                      style: theme.textTheme.titleMedium,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    FadeTransition(
                                      opacity: _fade,
                                      child: Text(
                                        item?.description ?? 'A mysterious relic whose story is yet untold.',
                                        style: theme.textTheme.bodyMedium,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  key: const ValueKey('hidden'),
                                  children: [
                                    Container(
                                      width: 110,
                                      height: 110,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                                      ),
                                      child: const Icon(Icons.card_giftcard_outlined, color: GamerColors.textSecondary, size: 56),
                                    ),
                                    const SizedBox(height: 12),
                                    Text('Tap to reveal', style: theme.textTheme.labelSmall?.copyWith(color: GamerColors.textSecondary)),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Buttons
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _revealed ? () => Navigator.of(context).pop('claimed') : null,
                            child: const Text('Add to Collection'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _revealed
                                    ? () {
                                        // v1.0: redirect to Codex instead of Inventory/Equip
                                        Navigator.of(context).pop('view_codex');
                                        context.go('/collection');
                                      }
                                    : null,
                                child: const Text('View in Codex'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextButton(
                                onPressed: _revealed ? () => Navigator.of(context).pop('continue') : null,
                                child: const Text('Continue'),
                              ),
                            ),
                          ],
                        ),
                    ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RewardFullScreenRoute extends PageRouteBuilder {
  RewardFullScreenRoute({required int index, required int total, required RewardEvent event})
      : super(
          opaque: true,
          barrierDismissible: false,
          pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
            opacity: animation,
            child: BookRewardModal(event: event, index: index, total: total),
          ),
          transitionDuration: const Duration(milliseconds: 220),
        );
}
