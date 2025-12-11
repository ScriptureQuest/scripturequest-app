import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/models/inventory_item.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/services/gear_inventory_service.dart';
import 'package:level_up_your_faith/models/gear_item.dart';
import 'package:level_up_your_faith/widgets/gear_item_detail_sheet.dart';
import 'package:level_up_your_faith/widgets/artifact_visuals.dart';
import 'package:level_up_your_faith/widgets/home_action_button.dart';
import 'package:level_up_your_faith/providers/equipment_provider.dart';
import 'package:level_up_your_faith/services/equipment_service.dart';
import 'package:level_up_your_faith/widgets/reward_toast.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Phase 1 Part 2: Layout-only, Destiny-style inventory with top avatar/equip slots
    // and bottom 4-column placeholder grid. No logic wiring in this phase.
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            context.go('/inventory');
          },
        ),
        title: Text('Inventory', style: Theme.of(context).textTheme.headlineSmall),
        centerTitle: true,
        actions: const [HomeActionButton()],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: _InventoryGridSection(),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<InventoryItem> items;
  const _Section({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final p = context.read<AppProvider>();
    final eq = p.playerInventory.equipped;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.label_important_outline, color: GamerColors.accent),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        ...items.map((item) {
          final equipped = item.type == 'gear'
              ? eq.gearSlots.values.contains(item.id)
              : item.type == 'cosmetic'
                  ? eq.cosmetics.values.contains(item.id)
                  : item.type == 'title'
                      ? (eq.titleId == item.id)
                      : false;
          return InkWell(
            onTap: () => _showItemSheet(context, item),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GamerColors.darkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: GamerColors.accent.withValues(alpha: 0.2), width: 1),
              ),
              child: Row(
                children: [
                  _iconFor(item),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(item.name, style: Theme.of(context).textTheme.titleMedium)),
                            _rarityChip(item.rarity),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(item.description.isNotEmpty ? item.description : item.type.toUpperCase(),
                            style: Theme.of(context).textTheme.labelMedium),
                      ],
                    ),
                  ),
                  if (equipped)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: GamerColors.success.withValues(alpha: 0.12),
                        border: Border.all(color: GamerColors.success.withValues(alpha: 0.6), width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: GamerColors.success),
                          const SizedBox(width: 6),
                          Text('Equipped', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: GamerColors.success)),
                        ],
                      ),
                    ),
                  const Icon(Icons.chevron_right, color: GamerColors.textSecondary),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _rarityChip(String rarity) {
    Color c;
    switch (rarity.toLowerCase()) {
      case 'legendary':
        c = Colors.amber;
        break;
      case 'epic':
        c = Colors.purpleAccent;
        break;
      case 'rare':
        c = Colors.lightBlueAccent;
        break;
      default:
        c = GamerColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.6)),
      ),
      child: Text(rarity.toUpperCase(), style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _iconFor(InventoryItem item) {
    IconData icon;
    switch (item.type) {
      case 'gear':
        icon = Icons.security;
        break;
      case 'cosmetic':
        icon = Icons.auto_awesome;
        break;
      case 'title':
        icon = Icons.stars;
        break;
      case 'token':
      case 'item':
      default:
        icon = Icons.extension;
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: GamerColors.darkSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GamerColors.accent.withValues(alpha: 0.2)),
      ),
      child: Icon(icon, color: GamerColors.accent),
    );
  }

  void _showItemSheet(BuildContext context, InventoryItem item) {
    final p = context.read<AppProvider>();
    final eq = p.playerInventory.equipped;
    final slot = (item.meta['slot']?.toString() ?? '').trim();
    final isEquipped = item.type == 'gear'
        ? (slot.isNotEmpty && eq.gearSlots[slot] == item.id)
        : item.type == 'cosmetic'
            ? (slot.isNotEmpty && eq.cosmetics[slot] == item.id)
            : item.type == 'title'
                ? (eq.titleId == item.id)
                : false;

    RewardToast.setBottomSheetOpen(true);
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: GamerColors.darkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _iconFor(item),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(item.description, style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                        Row(children: [
                          _rarityChip(item.rarity),
                          const SizedBox(width: 8),
                          if (item.meta['slot'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: GamerColors.textSecondary.withValues(alpha: 0.5)),
                              ),
                              child: Text('Slot: ${item.meta['slot']}', style: const TextStyle(fontSize: 12)),
                            ),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (item.type == 'title') {
                          await p.equipItem(slotType: 'title', slotKey: 'title', itemId: item.id);
                        } else if (slot.isNotEmpty) {
                          await p.equipItem(slotType: item.type == 'gear' ? 'gear' : 'cosmetic', slotKey: slot, itemId: item.id);
                        }
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.check, color: GamerColors.darkBackground),
                      label: Text(isEquipped ? 'Re-Equip' : 'Equip'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (isEquipped)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          if (item.type == 'title') {
                            await p.unequipItem(slotType: 'title', slotKey: 'title');
                          } else if (slot.isNotEmpty) {
                            await p.unequipItem(slotType: item.type == 'gear' ? 'gear' : 'cosmetic', slotKey: slot);
                          }
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close, color: GamerColors.accent),
                        label: const Text('Unequip'),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    ).whenComplete(() => RewardToast.setBottomSheetOpen(false));
  }

  // Note: avatar sheet helpers are defined once at the bottom of this file
}

// ------------------------------------------------------------
// Top Half — Avatar + Equip Slot Layout (layout-only)
// ------------------------------------------------------------
// (Avatar/equip UI removed — this screen is now list-only)

// ------------------------------------------------------------
// Bottom Half — Inventory Grid (placeholder items)
// ------------------------------------------------------------
class _InventoryGridSection extends StatefulWidget {
  const _InventoryGridSection();

  @override
  State<_InventoryGridSection> createState() => _InventoryGridSectionState();
}

class _InventoryGridSectionState extends State<_InventoryGridSection> {
  final ScrollController _scroll = ScrollController();
  final Map<String, GlobalKey> _itemKeys = <String, GlobalKey>{};
  String? _highlightGearId;
  bool _didAutoScroll = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Parse highlight param once
    if (_highlightGearId == null) {
      try {
        final uri = GoRouterState.of(context).uri;
        _highlightGearId = uri.queryParameters['highlight'];
      } catch (_) {}
    }
  }

  Future<void> _scrollToHighlightedIfNeeded(List<GearItem> items) async {
    if (_didAutoScroll) return;
    final id = _highlightGearId;
    if (id == null || id.isEmpty) return;
    // Ensure key exists
    final key = _itemKeys[id];
    if (key == null) return;
    _didAutoScroll = true; // prevent re-entrance
    try {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final ctx = key.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 380),
          alignment: 0.2,
          curve: Curves.easeOut,
        );
        // Keep a gentle highlight glow for a moment
        if (mounted) {
          setState(() {});
          Future.delayed(const Duration(milliseconds: 1600), () {
            if (!mounted) return;
            setState(() => _highlightGearId = null);
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gear = context.watch<GearInventoryService>();
    final app = context.read<AppProvider>();
    final items = gear.getSortedInventory();

    // Recompute keys for visible items
    for (final it in items) {
      _itemKeys.putIfAbsent(it.id, () => GlobalKey());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToHighlightedIfNeeded(items));

    final count = items.isEmpty ? 12 : (items.length < 12 ? 12 : items.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Inventory', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        if (items.isEmpty)
          Text('Complete quests to discover Biblical artifacts.', style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            controller: _scroll,
            itemCount: count,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              if (index < items.length) {
                final item = items[index];
                final isEquipped = gear.isEquipped(item);
                final isHighlighted = _highlightGearId == item.id;

                return KeyedSubtree(
                  key: _itemKeys[item.id],
                  child: _GearGridItem(
                    item: item,
                    isEquipped: isEquipped,
                    isHighlighted: isHighlighted,
                    onTap: () async {
                      // Equip visual state in grid (in-memory)
                      app.equipGear(item.id);
                      // Also persist to EquipmentService for Faith Power
                      try {
                        final eq = context.read<EquipmentProvider>();
                        SlotType mapSlot(GearSlot s) {
                          switch (s) {
                            case GearSlot.head:
                              return SlotType.head;
                            case GearSlot.chest:
                              return SlotType.chest;
                            case GearSlot.hand:
                              return SlotType.hand;
                            case GearSlot.artifact:
                            case GearSlot.charm:
                              final e = eq.equipped;
                              return (e[SlotType.relic1] == null || (e[SlotType.relic1]?.isEmpty ?? true))
                                  ? SlotType.relic1
                                  : SlotType.relic2;
                            case GearSlot.hands:
                            case GearSlot.legs:
                            case GearSlot.feet:
                              return SlotType.hand;
                          }
                        }
                        final slot = mapSlot(item.slot);
                        await eq.equip(slot, item.id);
                        await app.equipArtifactForSlot(slot, item.id);
                        if (context.mounted) {
                          RewardToast.showSuccess(
                            context,
                            title: 'Equipped!',
                            subtitle: '${item.name} equipped on your Soul Avatar.',
                          );
                        }
                      } catch (_) {}
                    },
                    onLongPress: () {
                      RewardToast.setBottomSheetOpen(true);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => GearItemDetailSheet(item: item),
                      ).whenComplete(() => RewardToast.setBottomSheetOpen(false));
                    },
                  ),
                );
              }

              return const _EmptyInventorySlot();
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyInventorySlot extends StatelessWidget {
  const _EmptyInventorySlot();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                width: 1.5,
                color: theme.colorScheme.onBackground.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              Icons.add,
              size: 20,
              color: theme.colorScheme.onBackground.withValues(alpha: 0.4),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Empty',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onBackground.withValues(alpha: 0.5),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _GearGridItem extends StatelessWidget {
  final GearItem item;
  final bool isEquipped;
  final bool isHighlighted;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _GearGridItem({
    required this.item,
    required this.isEquipped,
    required this.isHighlighted,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rarityColor = gearRarityColor(item.rarity, theme);

    final borderColor = isEquipped
        ? rarityColor
        : (isHighlighted ? GamerColors.accent : theme.colorScheme.outline.withValues(alpha: 0.4));
    final borderWidth = isEquipped ? 2.0 : (isHighlighted ? 2.0 : 1.0);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: borderWidth),
          color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: GamerColors.accent.withValues(alpha: 0.25),
                    blurRadius: 14,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Icon(
                    iconForVisualKey(item.visualKey),
                    size: 20,
                    color: rarityColor,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: rarityDotColor(item.rarity, theme),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// (No avatar helpers; kept list-only behaviors)
