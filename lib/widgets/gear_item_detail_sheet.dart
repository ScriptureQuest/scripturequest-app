import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gear_item.dart';
import '../models/spiritual_stats.dart';
import '../services/gear_inventory_service.dart';
import 'artifact_visuals.dart';
import 'package:level_up_your_faith/services/equipment_service.dart';
import 'package:level_up_your_faith/providers/equipment_provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/widgets/reward_toast.dart';

class GearItemDetailSheet extends StatelessWidget {
  final GearItem item;

  const GearItemDetailSheet({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gear = context.watch<GearInventoryService>();
    final isEquipped = gear.isEquipped(item);
    final rarityColor = gearRarityColor(item.rarity, theme);
    String _titleCase(String s) {
      if (s.isEmpty) return s;
      final parts = s.split('_');
      return parts
          .map((p) => p.isEmpty ? p : (p[0].toUpperCase() + p.substring(1).toLowerCase()))
          .join(' ');
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: rarityColor, width: 2),
                        color:
                            theme.colorScheme.surfaceVariant.withValues(alpha: 0.6),
                      ),
                      alignment: Alignment.center,
                      child: Icon(iconForVisualKey(item.visualKey), color: rarityColor),
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
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                      if (item.subtitle != null &&
                          item.subtitle!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            item.subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _Chip(
                            label: _titleCase(item.rarity.name),
                            color: rarityColor.withValues(alpha: 0.12),
                            borderColor: rarityColor,
                          ),
                          _Chip(
                            label: _titleCase(item.slot.name),
                            color: theme.colorScheme.surfaceVariant,
                            borderColor: theme.colorScheme.outlineVariant,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Text(
              item.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
              ),
            ),

            // Biblical Reference (optional)
            if (item.reference != null && item.reference!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Biblical Reference',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                item.reference!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            const SizedBox(height: 16),
            _StatsSection(stats: item.stats),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  // Update grid highlight (in-memory)
                  gear.toggleEquip(item);

                  // Map helper GearSlot -> Equipment SlotType (persistent Faith Power)
                  SlotType mapSlot(GearSlot s, EquipmentProvider eq) {
                    switch (s) {
                      case GearSlot.head:
                        return SlotType.head;
                      case GearSlot.chest:
                        return SlotType.chest;
                      case GearSlot.hand:
                        return SlotType.hand;
                      case GearSlot.artifact:
                      case GearSlot.charm:
                        // Choose first free relic slot, else relic2
                        final e = eq.equipped;
                        return (e[SlotType.relic1] == null || (e[SlotType.relic1]?.isEmpty ?? true))
                            ? SlotType.relic1
                            : SlotType.relic2;
                      case GearSlot.hands:
                      case GearSlot.legs:
                      case GearSlot.feet:
                        // Not distinctly supported in v1; map to hand for now
                        return SlotType.hand;
                    }
                  }

                  try {
                    final eq = context.read<EquipmentProvider>();
                    final app = context.read<AppProvider>();
                    if (isEquipped) {
                      // Find which slot holds this id
                      SlotType? found;
                      eq.equipped.forEach((s, id) {
                        if ((id ?? '').trim() == item.id) found = s;
                      });
                      if (found != null) {
                        await eq.unequip(found!);
                        await app.unequipArtifactSlot(found!);
                        if (context.mounted) {
                          RewardToast.showSuccess(
                            context,
                            title: 'Unequipped',
                            subtitle: '${item.name} has been unequipped.',
                            icon: Icons.check_circle_outline,
                          );
                        }
                      }
                    } else {
                      final slot = mapSlot(item.slot, eq);
                      await eq.equip(slot, item.id);
                      await app.equipArtifactForSlot(slot, item.id);
                      if (context.mounted) {
                        RewardToast.showSuccess(
                          context,
                          title: 'Equipped!',
                          subtitle: '${item.name} equipped on your Soul Avatar.',
                        );
                      }
                    }
                  } catch (_) {}

                  Navigator.of(context).maybePop();
                },
                child: Text(isEquipped ? 'Unequip' : 'Equip'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color borderColor;

  const _Chip({
    required this.label,
    required this.color,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final SpiritualStats stats;

  const _StatsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (stats.isZero) {
      return Text(
        'No specific stat bonuses.\nThis item is a symbolic encouragement.',
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Spiritual Bonuses',
            style:
                theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            if (stats.wisdom != 0) _StatPill(label: 'Wisdom', value: stats.wisdom),
            if (stats.discipline != 0)
              _StatPill(label: 'Discipline', value: stats.discipline),
            if (stats.compassion != 0)
              _StatPill(label: 'Compassion', value: stats.compassion),
            if (stats.witness != 0)
              _StatPill(label: 'Witness', value: stats.witness),
          ],
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int value;

  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '+$value $label',
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
