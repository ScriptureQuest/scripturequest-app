import 'package:level_up_your_faith/models/cosmetic_item.dart';

/// Local cosmetic examples (monetization disabled). All owned=false.
class CosmeticSeedsV1 {
  static List<CosmeticItem> list() {
    return const [
      CosmeticItem(
        id: 'theme_dawn',
        name: 'Dawn Theme',
        description: 'A calm olive dawn palette inspired by parchment and morning light.',
        type: CosmeticType.theme,
        rarity: CosmeticRarity.rare,
        priceUSD: 2.99,
        owned: false,
      ),
      CosmeticItem(
        id: 'glow_starlight',
        name: 'Starlight Avatar Glow',
        description: 'A soft celestial aura that shimmers around your Soul Avatar.',
        type: CosmeticType.avatar_glow,
        rarity: CosmeticRarity.epic,
        priceUSD: 3.99,
        owned: false,
      ),
      CosmeticItem(
        id: 'frame_golden',
        name: 'Golden Frame',
        description: 'A refined golden frame around your profile identity.',
        type: CosmeticType.frame,
        rarity: CosmeticRarity.epic,
        priceUSD: 4.99,
        owned: false,
      ),
      CosmeticItem(
        id: 'theme_bedtime',
        name: 'Bedtime Calm',
        description: 'Warm plum surfaces and indigo accents for night reading.',
        type: CosmeticType.theme,
        rarity: CosmeticRarity.common,
        priceUSD: 1.99,
        owned: false,
      ),
      CosmeticItem(
        id: 'theme_ocean',
        name: 'Ocean Deep',
        description: 'Cool modern blues inspired by deep seas.',
        type: CosmeticType.theme,
        rarity: CosmeticRarity.rare,
        priceUSD: 2.99,
        owned: false,
      ),
    ];
  }
}
