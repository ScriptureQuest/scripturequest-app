import 'package:flutter/material.dart';

import 'package:level_up_your_faith/models/gear_item.dart';
import 'package:level_up_your_faith/models/spiritual_stats.dart';
// AppProvider and routing not needed in v1.0 lore-only sheet
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/widgets/artifact_visuals.dart';
import 'package:level_up_your_faith/data/gear_lore.dart';
import 'package:google_fonts/google_fonts.dart';

class ArtifactDetailSheet extends StatelessWidget {
  final GearItem item;
  final bool isOwned;
  final String? bookSource;
  final bool fromQuest;

  const ArtifactDetailSheet({super.key, required this.item, required this.isOwned, required this.bookSource, required this.fromQuest});

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    final parts = s.split('_');
    return parts.map((p) => p.isEmpty ? p : (p[0].toUpperCase() + p.substring(1).toLowerCase())).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rarityColor = gearRarityColor(item.rarity, theme);
    final hintText = bookSource != null
        ? 'Earn by finishing $bookSource'
        : (fromQuest ? 'Reward from specific quests' : 'Not yet obtained');

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
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
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.92, end: 1.0),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                    child: Stack(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: rarityColor, width: 2),
                            color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.6),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            isOwned ? iconForVisualKey(item.visualKey) : Icons.help_outline,
                            color: rarityColor,
                            size: 32,
                          ),
                        ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: rarityDotColor(item.rarity, theme),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOwned ? item.name : 'Unknown Artifact',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _chip(context, _titleCase(item.rarity.name), rarityColor.withValues(alpha: 0.12), rarityColor),
                            _chip(context, _titleCase(item.slot.name), theme.colorScheme.surfaceVariant, theme.colorScheme.outlineVariant),
                            if (bookSource != null) _chip(context, 'Book: $bookSource', theme.colorScheme.surfaceVariant, theme.colorScheme.outlineVariant),
                            if (fromQuest) _chip(context, 'Quest Drop', theme.colorScheme.surfaceVariant, theme.colorScheme.outlineVariant),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Lore blurb (serif-like styling)
              Builder(
                builder: (context) {
                  final lore = kGearLore[item.id] ?? 'A sacred artifact of unknown origin.';
                  return Text(
                    lore,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      height: 1.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              if (isOwned) ...[
                Text(
                  item.description,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.9)),
                ),
                if (!item.stats.isZero) ...[
                  const SizedBox(height: 14),
                  _StatsSection(stats: item.stats),
                ],
              ] else ...[
                Text(hintText, style: theme.textTheme.bodyMedium),
              ],

              const SizedBox(height: 18),
              // v1.0: Lore-only — Equip and Inventory access disabled
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.22), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_clock, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Equipping returns in a future update. For now, enjoy the lore.',
                        style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label, Color bg, Color border) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(label, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final SpiritualStats stats;
  const _StatsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (stats.isZero) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Spiritual Bonuses', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            if (stats.wisdom != 0) _pill(context, 'Wisdom', stats.wisdom),
            if (stats.discipline != 0) _pill(context, 'Discipline', stats.discipline),
            if (stats.compassion != 0) _pill(context, 'Compassion', stats.compassion),
            if (stats.witness != 0) _pill(context, 'Witness', stats.witness),
          ],
        ),
      ],
    );
  }

  Widget _pill(BuildContext context, String label, int value) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('+$value $label', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500)),
    );
  }
}
