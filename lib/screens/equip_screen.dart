import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/widgets/home_action_button.dart';
import 'package:level_up_your_faith/widgets/reward_toast.dart';

class EquipScreen extends StatelessWidget {
  const EquipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, p, _) {
      final gs = p.equippedGearSlots;
      final cs = p.equippedCosmetics;
      final titleId = p.equippedTitleId;

      return Scaffold(
        appBar: AppBar(
          title: Text('Equip & Avatar', style: Theme.of(context).textTheme.headlineSmall),
          centerTitle: true,
          actions: const [HomeActionButton()],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Silhouette Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: GamerColors.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GamerColors.accent.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.person_outline, size: 120, color: GamerColors.textSecondary.withValues(alpha: 0.7)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _slotChip(context, 'Head', 'gear', 'head', gs['head']),
                        _slotChip(context, 'Chest', 'gear', 'chest', gs['chest']),
                        _slotChip(context, 'Hands', 'gear', 'hands', gs['hands']),
                        _slotChip(context, 'Feet', 'gear', 'feet', gs['feet']),
                        _slotChip(context, 'Aura', 'cosmetic', 'aura', cs['aura']),
                        _slotChip(context, 'Frame', 'cosmetic', 'frame', cs['frame']),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Title footer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: GamerColors.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GamerColors.accent.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: GamerColors.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Equipped Title', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 4),
                          Text(titleId ?? 'None', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _chooseTitle(context),
                      icon: const Icon(Icons.swap_horiz, color: GamerColors.accent),
                      label: const Text('Change'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _slotChip(BuildContext context, String label, String slotType, String slotKey, String? itemId) {
    return InkWell(
      onTap: () => _chooseForSlot(context, slotType, slotKey),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: GamerColors.darkSurface,
          border: Border.all(color: GamerColors.accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(slotType == 'gear' ? Icons.security : Icons.auto_awesome, color: GamerColors.accent, size: 18),
            const SizedBox(width: 8),
            Text('$label: ', style: Theme.of(context).textTheme.labelMedium),
            Text(itemId ?? 'Empty', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: GamerColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  void _chooseForSlot(BuildContext context, String slotType, String slotKey) {
    final p = context.read<AppProvider>();
    final items = p.playerInventory.items.values
        .where((i) => i.type == (slotType == 'gear' ? 'gear' : 'cosmetic') && (i.meta['slot']?.toString() ?? '') == slotKey)
        .toList();
    RewardToast.setBottomSheetOpen(true);
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: GamerColors.darkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Choose $slotKey', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...items.map((i) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Icon(slotType == 'gear' ? Icons.security : Icons.auto_awesome, color: GamerColors.accent),
                title: Text(i.name),
                subtitle: Text(i.description.isNotEmpty ? i.description : i.rarity.toUpperCase()),
                trailing: ElevatedButton(
                  onPressed: () async {
                    await p.equipItem(slotType: slotType, slotKey: slotKey, itemId: i.id);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Equip'),
                ),
              )),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('You have no items for this slot yet.', style: Theme.of(context).textTheme.bodyMedium),
              ),
            )
        ],
      ),
    ).whenComplete(() => RewardToast.setBottomSheetOpen(false));
  }

  void _chooseTitle(BuildContext context) {
    final p = context.read<AppProvider>();
    final items = p.playerInventory.items.values.where((i) => i.type == 'title').toList();
    RewardToast.setBottomSheetOpen(true);
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: GamerColors.darkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Choose Title', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...items.map((i) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: const Icon(Icons.stars, color: GamerColors.accent),
                title: Text(i.name),
                subtitle: Text(i.description.isNotEmpty ? i.description : 'Title'),
                trailing: ElevatedButton(
                  onPressed: () async {
                    await p.equipItem(slotType: 'title', slotKey: 'title', itemId: i.id);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Equip'),
                ),
              )),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('You have no titles yet.', style: Theme.of(context).textTheme.bodyMedium),
              ),
            )
        ],
      ),
    ).whenComplete(() => RewardToast.setBottomSheetOpen(false));
  }
}
