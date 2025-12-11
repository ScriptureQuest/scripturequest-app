import 'package:flutter/foundation.dart';

/// Optional lore blurbs for artifacts in the Codex.
/// Keys are GearItem.id. If an id is not present, UI will show a default line.
const Map<String, String> kGearLore = <String, String>{
  // Legendary
  'artifact_ark_of_the_covenant':
      'Carried before the people, the Ark bore witness to covenant mercy.',
  'artifact_tablets_of_the_covenant':
      'Words etched in stone, yet written deepest upon the heart.',
  'artifact_bronze_serpent':
      'A sign lifted up in the wilderness—look and live.',
  'artifact_menorah_lampstand':
      'Sevenfold light, a gentle reminder to walk in His ways.',
  'artifact_empty_tomb_stone':
      'The stone that once sealed sorrow now heralds everlasting joy.',

  // Epic
  'hand_staff_of_moses': 'Simple wood in a sovereign hand parted the sea.',
  'davids_harp': 'Strings that steadied a troubled king and stirred praise.',
  'chest_priestly_breastplate':
      'Twelve stones resting near the heart—names the Lord remembers.',
  'hand_aarons_budding_staff':
      'Where life seemed withered, blossoms declared His choice.',
  'hand_shofar_of_jubilee': 'A trumpet of release announcing homecoming and rest.',

  // Rare
  'hand_scroll_of_isaiah': 'Scroll of consolation and promise, fulfilled in Christ.',
  'hand_censer_of_incense': 'Prayers rising, fragrant before the throne.',
  'hand_water_jars_of_cana': 'Ordinary vessels, extraordinary grace.',
  'hand_loaves_basket': 'In His hands, little becomes abundance.',
  'hand_fishers_net': 'Cast again at His word and behold the catch.',
  'hand_manna_jar': 'Morning mercies gathered fresh, enough for today.',
  'chest_prophets_mantle': 'A garment of calling—truth with humility and love.',
  'feet_sandals_of_peace': 'Steps readied with peace for every road ahead.',
  'pilgrims_sandals': 'Travel light; the city to come draws near.',
  'charm_anchor_of_hope': 'A steadfast hope, sure in storm and calm alike.',
  'hand_lantern_of_the_word': 'Light for each step, a lamp to the path.',
  'hand_bread_of_presence_plate': 'Table fellowship—God dwells with His people.',

  // Uncommon
  'hand_shepherds_sling': 'Small faith against large fears; victory is the Lord’s.',
  'charm_five_smooth_stones': 'Quiet preparation for appointed moments.',
  'charm_mustard_seed_pendant': 'A seed sown becomes shelter in His care.',
  'charm_widows_mite': 'A small coin, a great gift—wholehearted devotion.',
  'hands_basin_and_towel': 'Greatness kneed to serve; love stooped low.',
  'hand_shepherds_staff': 'Rod and staff—comfort for the weary soul.',
  'head_sackcloth_hood': 'A sign of sorrow that opens into renewal.',
  'chest_linen_ephod': 'Simple garments for a heart undivided.',
  'legs_pilgrims_garments': 'Sojourners clothed for a long obedience.',
  'charm_olive_branch': 'Peace extended like a green shoot after flood.',
  'hand_plumb_line': 'A standard set among a people He loves.',
  'hand_tongs_from_the_altar': 'Cleansed lips, a ready “Here am I, send me.”',

  // Common
  'charm_rainbow_token': 'A bow set in clouds to remember mercy.',
  'charm_bethlehem_star': 'A light for seekers on the road to joy.',
  'head_priestly_turban': '“Holy to the Lord” set upon the brow.',
  'charm_small_flask_of_oil': 'Little becomes plenty when entrusted to Him.',
  'hand_alabaster_jar': 'Poured-out love remembered wherever the gospel goes.',
  'hand_urim_thummim': 'Discernment sought in the presence of God.',
  'charm_jordan_river_stone': 'A memorial of crossings led by the Lord.',
  'charm_little_scroll': 'Taste the word; speak what you have received.',
};
