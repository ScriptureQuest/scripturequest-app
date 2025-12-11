import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/models/gear_item.dart';
import 'package:level_up_your_faith/providers/equipment_provider.dart';
import 'package:level_up_your_faith/services/equipment_service.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/widgets/reward_toast.dart';

class SelectArtifactModal extends StatelessWidget {
  final SlotType slot;
  const SelectArtifactModal({super.key, required this.slot});

  String _slotLabel(SlotType s) {
    switch (s) {
      case SlotType.head:
        return 'Head';
      case SlotType.chest:
        return 'Chest';
      case SlotType.hand:
        return 'Hand';
      case SlotType.relic1:
        return 'Relic 1';
      case SlotType.relic2:
        return 'Relic 2';
      case SlotType.aura:
        return 'Aura';
    }
  }

  IconData _slotIcon(SlotType s) {
    switch (s) {
      case SlotType.head:
        return Icons.emoji_people_outlined;
      case SlotType.chest:
        return Icons.checkroom_outlined;
      case SlotType.hand:
        return Icons.auto_awesome;
      case SlotType.relic1:
      case SlotType.relic2:
        return Icons.token_outlined;
      case SlotType.aura:
        return Icons.auto_awesome_mosaic;
    }
  }

  @override
  Widget build(BuildContext context) {
    final eq = context.watch<EquipmentProvider>();
    final items = eq.itemsForSlot(slot);
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.16), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(_slotIcon(slot), color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Select Artifact', style: Theme.of(context).textTheme.titleLarge),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _ArtifactTile(item: item, onEquip: () async {
                    // Persist through EquipmentProvider and AppProvider for immediate Faith Power
                    await eq.equip(slot, item.id);
                    try {
                      await context.read<AppProvider>().equipArtifactForSlot(slot, item.id);
                    } catch (_) {}
                    try {
                      RewardToast.showSuccess(
                        context,
                        title: 'Equipped!',
                        subtitle: '${item.name} equipped on your Soul Avatar.',
                      );
                    } catch (_) {}
                    if (context.mounted) Navigator.of(context).pop();
                  });
                },
              ),
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No artifacts available for ${_slotLabel(slot)} yet.', style: Theme.of(context).textTheme.bodyMedium),
              ),
          ],
        ),
      ),
    );
  }
}

class _ArtifactTile extends StatelessWidget {
  final GearItem item;
  final VoidCallback onEquip;
  const _ArtifactTile({required this.item, required this.onEquip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
        ),
        child: Icon(Icons.auto_awesome, color: gearRarityColor(item.rarity, theme)),
      ),
      title: Text(item.name),
      subtitle: Text(item.subtitle?.isNotEmpty == true ? item.subtitle! : item.description, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: ElevatedButton.icon(
        onPressed: onEquip,
        icon: Icon(Icons.check, color: theme.colorScheme.onPrimary),
        label: const Text('Equip'),
      ),
    );
  }
}
