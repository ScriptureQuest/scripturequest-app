import 'package:flutter/material.dart';
import 'package:level_up_your_faith/models/gear_item.dart';
import 'package:level_up_your_faith/theme.dart';

/// Returns a symbolic Material icon for a given visualKey.
/// Falls back to a calm default if unmapped.
IconData iconForVisualKey(String? key) {
  final k = (key ?? '').trim().toLowerCase();
  switch (k) {
    case 'ark_covenant':
      return Icons.account_balance;
    case 'tablets_covenant':
      return Icons.chrome_reader_mode;
    case 'bronze_serpent':
      return Icons.emoji_nature;
    case 'menorah':
      return Icons.wb_incandescent;
    case 'empty_tomb_stone':
      return Icons.circle;
    case 'staff_moses':
    case 'staff_aaron':
      return Icons.hiking;
    case 'davids_harp':
      return Icons.music_note;
    case 'breastplate_priest':
      return Icons.shield;
    case 'shofar':
      return Icons.campaign;
    case 'keys_kingdom':
      return Icons.key;
    case 'pearl':
      return Icons.circle;
    case 'scroll_isaiah':
    case 'little_scroll':
      return Icons.auto_stories;
    case 'censer':
      return Icons.local_fire_department;
    case 'jar_cana':
      return Icons.wine_bar;
    case 'basket_loaves':
      return Icons.shopping_basket;
    case 'net':
      return Icons.sailing;
    case 'jar_manna':
      return Icons.bakery_dining;
    case 'mantle_prophet':
    case 'hood_sackcloth':
    case 'ephod_linen':
    case 'garments_pilgrim':
      return Icons.checkroom;
    case 'sandals_peace':
    case 'pilgrims_sandals':
      return Icons.directions_walk;
    case 'anchor':
      return Icons.anchor;
    case 'lantern_word':
      return Icons.emoji_objects;
    case 'bread_presence':
      return Icons.breakfast_dining;
    case 'sling':
      return Icons.sports_handball;
    case 'stones_five':
    case 'mustard_seed':
      return Icons.grain;
    case 'widows_mite':
      return Icons.monetization_on;
    case 'basin_towel':
      return Icons.dry_cleaning;
    case 'staff_shepherd':
      return Icons.elderly;
    case 'olive_branch':
      return Icons.eco;
    case 'plumb_line':
      return Icons.straighten;
    case 'tongs_altar':
      return Icons.build;
    case 'rainbow_token':
      return Icons.palette;
    case 'star_bethlehem':
      return Icons.star;
    case 'turban_priest':
      return Icons.workspace_premium;
    case 'flask_oil':
      return Icons.science;
    case 'alabaster_jar':
      return Icons.emoji_food_beverage;
    case 'urim_thummim':
      return Icons.auto_awesome;
    case 'jordan_stone':
      return Icons.landscape;
    default:
      return Icons.auto_awesome;
  }
}

/// Subtle rarity micro-indicator color mapping (dot color).
/// Very low-key; avoid loud saturation.
Color rarityDotColor(GearRarity rarity, ThemeData theme) {
  switch (rarity) {
    case GearRarity.common:
    case GearRarity.uncommon:
      return theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55);
    case GearRarity.rare:
    case GearRarity.epic:
      return GamerColors.neonPurple.withValues(alpha: 0.8);
    case GearRarity.legendary:
      return Colors.amberAccent.shade400.withValues(alpha: 0.9);
  }
}
