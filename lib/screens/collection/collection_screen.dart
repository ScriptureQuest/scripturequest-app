import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'package:level_up_your_faith/models/gear_item.dart';
import 'package:level_up_your_faith/services/gear_inventory_service.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/data/gear_seeds.dart';
import 'package:level_up_your_faith/data/book_reward_map.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/widgets/artifact_visuals.dart';
import 'package:level_up_your_faith/widgets/home_action_button.dart';
import 'artifact_detail_sheet.dart';
import 'package:level_up_your_faith/widgets/reward_toast.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  // 0: All (implemented), 1: By Book (stub), 2: By Slot (stub)
  int _tabIndex = 0;
  // Precomputed set of gear ids that can drop from quests
  Set<String> _questRewardIds = const <String>{};
  bool _loadingSources = true;

  @override
  void initState() {
    super.initState();
    _loadQuestRewardIds();
  }

  Future<void> _loadQuestRewardIds() async {
    try {
      final app = context.read<AppProvider>();
      final quests = await app.questService.getAllQuests();
      final ids = <String>{};
      for (final q in quests) {
        for (final id in q.possibleRewardGearIds) {
          ids.add(id);
        }
        final g = q.guaranteedFirstClearGearId;
        if (g != null && g.trim().isNotEmpty) ids.add(g.trim());
      }
      if (mounted) {
        setState(() {
          _questRewardIds = ids;
          _loadingSources = false;
        });
      }
    } catch (e) {
      debugPrint('CollectionScreen _loadQuestRewardIds error: $e');
      if (mounted) setState(() => _loadingSources = false);
    }
  }

  String? _bookForGearId(String gearId) {
    for (final entry in kBookRewardMap.entries) {
      if (entry.value.contains(gearId)) return entry.key;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gear = context.watch<GearInventoryService>();
    final ownedIds = gear.inventory.map((e) => e.id).toSet();

    // Canonical order from seeds
    final List<GearItem> allItems = List<GearItem>.from(kGearSeedList);

    // Uniform 3-column grid for calm, ordered browsing
    const crossAxisCount = 3;

    final totalCount = allItems.length;
    final ownedCount = allItems.where((g) => ownedIds.contains(g.id)).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Codex'),
        centerTitle: true,
        actions: const [
          HomeActionButton(),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: GamerColors.accent.withValues(alpha: 0.14), width: 1),
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0x1115C6F2),
                    Color(0x1100F0FF),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Codex',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: GamerColors.accent,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your biblical artifacts — discovered & undiscovered.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Artifacts discovered: $ownedCount / $totalCount',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Segmented controls (All / By Book / By Slot)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: GamerColors.accent.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  _Segment(
                    label: 'All',
                    selected: _tabIndex == 0,
                    onTap: () => setState(() => _tabIndex = 0),
                  ),
                  const SizedBox(width: 6),
                  _Segment(
                    label: 'By Book',
                    selected: _tabIndex == 1,
                    onTap: () => setState(() => _tabIndex = 1),
                  ),
                  const SizedBox(width: 6),
                  _Segment(
                    label: 'By Slot',
                    selected: _tabIndex == 2,
                    onTap: () => setState(() => _tabIndex = 2),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Content
          Expanded(
            child: Builder(
              builder: (context) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) {
                    final offset = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(anim);
                    return FadeTransition(opacity: anim, child: SlideTransition(position: offset, child: child));
                  },
                  child: _buildTabContent(context, theme, allItems, ownedIds, crossAxisCount),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, ThemeData theme, List<GearItem> allItems, Set<String> ownedIds, int crossAxisCount) {
    if (_tabIndex == 0) {
      return GridView.builder(
        key: const ValueKey('grid_all'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.80,
        ),
        itemCount: allItems.length,
        itemBuilder: (context, index) => _buildTile(context, theme, allItems[index], ownedIds),
      );
    }

    if (_tabIndex == 1) {
      // Group by Book
      final Map<String, List<GearItem>> groups = <String, List<GearItem>>{};
      for (final item in allItems) {
        final book = _bookForGearId(item.id) ?? 'Miscellaneous';
        groups.putIfAbsent(book, () => <GearItem>[]).add(item);
      }
      final entries = groups.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      return ListView.builder(
        key: const ValueKey('list_by_book'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final e = entries[i];
          return _AnimatedSection(
            child: _GroupSection(
              title: e.key,
              children: e.value.map((it) => _buildTile(context, theme, it, ownedIds)).toList(),
            ),
          );
        },
      );
    }

    // Group by Slot (Head / Chest / Hands / Relic + Other)
    final Map<String, List<GearItem>> slotGroups = <String, List<GearItem>>{
      'Head': <GearItem>[],
      'Chest': <GearItem>[],
      'Hands': <GearItem>[],
      'Relic': <GearItem>[],
      'Other': <GearItem>[],
    };
    for (final item in allItems) {
      switch (item.slot) {
        case GearSlot.head:
          slotGroups['Head']!.add(item);
          break;
        case GearSlot.chest:
          slotGroups['Chest']!.add(item);
          break;
        case GearSlot.hands:
        case GearSlot.hand:
          slotGroups['Hands']!.add(item);
          break;
        case GearSlot.artifact:
          slotGroups['Relic']!.add(item);
          break;
        default:
          slotGroups['Other']!.add(item);
      }
    }
    // Remove empty groups
    final slotEntries = slotGroups.entries.where((e) => e.value.isNotEmpty).toList();
    return ListView.builder(
      key: const ValueKey('list_by_slot'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: slotEntries.length,
      itemBuilder: (context, i) {
        final e = slotEntries[i];
        return _AnimatedSection(
          child: _GroupSection(
            title: e.key,
            children: e.value.map((it) => _buildTile(context, theme, it, ownedIds)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildTile(BuildContext context, ThemeData theme, GearItem item, Set<String> ownedIds) {
    final isOwned = ownedIds.contains(item.id);
    final rarityColor = gearRarityColor(item.rarity, theme);
    final book = _bookForGearId(item.id);
    final fromQuest = _questRewardIds.contains(item.id);
    return _ArtifactTile(
      item: item,
      isOwned: isOwned,
      rarityColor: rarityColor,
      bookSource: book,
      fromQuest: fromQuest,
      onTap: () {
        RewardToast.setBottomSheetOpen(true);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => ArtifactDetailSheet(
            item: item,
            isOwned: isOwned,
            bookSource: book,
            fromQuest: fromQuest,
          ),
        ).whenComplete(() => RewardToast.setBottomSheetOpen(false));
      },
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isStub;
  final VoidCallback onTap;
  const _Segment({required this.label, required this.selected, required this.onTap, this.isStub = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: selected ? GamerColors.darkBackground : theme.colorScheme.onSurfaceVariant,
    );
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [GamerColors.neonPurple, GamerColors.neonCyan],
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: textStyle),
                if (!selected)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    height: 2,
                    width: 22,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
              ],
            ),
            if (isStub) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.lock_clock,
                size: 14,
                color: (selected ? GamerColors.darkBackground : theme.colorScheme.onSurfaceVariant)
                    .withValues(alpha: 0.7),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ArtifactTile extends StatelessWidget {
  final GearItem item;
  final bool isOwned;
  final Color rarityColor;
  final String? bookSource;
  final bool fromQuest;
  final VoidCallback onTap;

  const _ArtifactTile({
    required this.item,
    required this.isOwned,
    required this.rarityColor,
    required this.bookSource,
    required this.fromQuest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = GamerColors.neonPurple.withValues(alpha: 0.12);
    final tileBg = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35);

    final nameText = (isOwned ? item.name : 'Unknown Artifact').toUpperCase();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.transparent,
          highlightColor: GamerColors.accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1),
              color: tileBg,
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      // Glow ring (owned) behind the icon
                      if (isOwned)
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  GamerColors.neonPurple.withValues(alpha: 0.28),
                                  GamerColors.neonCyan.withValues(alpha: 0.28),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: rarityColor.withValues(alpha: 0.20),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Artifact icon
                      Align(
                        alignment: Alignment.center,
                        child: Icon(
                          iconForVisualKey(item.visualKey),
                          size: 68,
                          color: isOwned
                              ? rarityColor
                              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
                        ),
                      ),
                      // Rarity micro-indicator (subtle dot)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: rarityDotColor(item.rarity, theme),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Lock for unowned
                      if (!isOwned)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(
                            Icons.lock,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  nameText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: isOwned
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // Title casing and source hint helpers removed for the polished V1.0 card.
}

class _GroupSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _GroupSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8, top: 6),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
              letterSpacing: 0.2,
            ),
          ),
        ),
        GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.80,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _AnimatedSection extends StatelessWidget {
  final Widget child;
  const _AnimatedSection({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, value, _) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 6),
          child: child,
        ),
      ),
    );
  }
}
