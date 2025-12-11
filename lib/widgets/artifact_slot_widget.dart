import 'package:flutter/material.dart';
import 'package:level_up_your_faith/theme.dart';

class ArtifactSlotWidget extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? equippedName;
  final String? equippedIconAsset;
  final VoidCallback onTap;
  final bool selected;

  const ArtifactSlotWidget({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.equippedName,
    this.equippedIconAsset,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasItem = (equippedName != null && equippedName!.trim().isNotEmpty);
    final border = selected ? theme.colorScheme.primary : theme.colorScheme.outline;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border.withValues(alpha: selected ? 0.9 : 0.35), width: selected ? 2 : 1),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
              ),
              child: Icon(icon, color: hasItem ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.labelSmall),
                  const SizedBox(height: 2),
                  Text(
                    hasItem ? equippedName! : '+ Equip',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: hasItem ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
