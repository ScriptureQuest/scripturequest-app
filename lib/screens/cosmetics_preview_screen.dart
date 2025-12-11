import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/services/cosmetic_service.dart';
import 'package:level_up_your_faith/models/cosmetic_item.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/widgets/soul_avatar.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';

class CosmeticsPreviewScreen extends StatefulWidget {
  const CosmeticsPreviewScreen({super.key});

  @override
  State<CosmeticsPreviewScreen> createState() => _CosmeticsPreviewScreenState();
}

class _CosmeticsPreviewScreenState extends State<CosmeticsPreviewScreen> {
  @override
  void dispose() {
    // Reset ephemeral previews when leaving the screen
    context.read<CosmeticService>().resetPreview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cosmetics (Preview Only)'),
        centerTitle: true,
      ),
      body: Consumer2<CosmeticService, AppProvider>(
        builder: (context, cosmetics, app, _) {
          final items = cosmetics.getAllCosmetics();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              _AvatarPreviewPanel(
                glowId: cosmetics.previewGlowId,
                frameId: cosmetics.previewFrameId,
                level: app.currentLevel,
                faithPower: app.faithPower.toDouble(),
              ),
              const SizedBox(height: 16),
              ...items.map((c) => _CosmeticTile(item: c)).toList(),
            ],
          );
        },
      ),
    );
  }
}

class _AvatarPreviewPanel extends StatelessWidget {
  final String? glowId;
  final String? frameId;
  final int level;
  final double faithPower;

  const _AvatarPreviewPanel({
    required this.glowId,
    required this.frameId,
    required this.level,
    required this.faithPower,
  });

  @override
  Widget build(BuildContext context) {
    // Render a calm preview card with optional glow/frame accents.
    final hasFrame = (frameId ?? '').isNotEmpty;
    final hasGlow = (glowId ?? '').isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GamerColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GamerColors.accent.withValues(alpha: 0.18), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: GamerColors.accent),
              SizedBox(width: 8),
              Text('Avatar Preview'),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: hasFrame
                    ? Border.all(color: Colors.amber.withValues(alpha: 0.6), width: 2)
                    : Border.all(color: Colors.transparent, width: 0),
                boxShadow: hasGlow
                    ? [
                        BoxShadow(
                          color: Colors.lightBlueAccent.withValues(alpha: 0.35),
                          blurRadius: 28,
                          spreadRadius: 6,
                        ),
                      ]
                    : const [],
              ),
              child: SoulAvatarViewV2(
                level: level,
                faithPower: faithPower,
                size: SoulAvatarSize.large,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasGlow || hasFrame ? 'Previewing: ${[
                  if (hasGlow) 'Glow',
                  if (hasFrame) 'Frame',
                ].join(' + ')}' : 'No cosmetic preview active',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: GamerColors.textSecondary),
          )
        ],
      ),
    );
  }
}

class _CosmeticTile extends StatelessWidget {
  final CosmeticItem item;
  const _CosmeticTile({required this.item});

  Color _rarityColor(CosmeticRarity r) {
    switch (r) {
      case CosmeticRarity.common:
        return Colors.grey;
      case CosmeticRarity.rare:
        return Colors.lightBlueAccent;
      case CosmeticRarity.epic:
        return Colors.purpleAccent;
      case CosmeticRarity.legendary:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.read<CosmeticService>();
    final owned = item.owned;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GamerColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GamerColors.accent.withValues(alpha: 0.12), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            item.type == CosmeticType.theme
                ? Icons.palette
                : item.type == CosmeticType.avatar_glow
                    ? Icons.auto_awesome
                    : item.type == CosmeticType.frame
                        ? Icons.crop_square
                        : Icons.texture,
            color: _rarityColor(item.rarity),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _rarityColor(item.rarity).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        item.rarity.label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: _rarityColor(item.rarity)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: GamerColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Preview button (always enabled)
                    ElevatedButton.icon(
                      onPressed: () {
                        svc.previewCosmetic(item);
                      },
                      icon: const Icon(Icons.visibility, color: Colors.black),
                      label: const Text('Preview'),
                    ),
                    const SizedBox(width: 8),
                    // Apply (only if owned)
                    OutlinedButton.icon(
                      onPressed: owned ? () => svc.applyCosmetic(item) : null,
                      icon: const Icon(Icons.check_circle, color: Colors.white70),
                      label: Text(owned ? 'Apply' : 'Apply'),
                    ),
                    const Spacer(),
                    // Purchase disabled
                    TextButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.lock_clock, color: Colors.white54),
                      label: const Text('Coming Soon'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
