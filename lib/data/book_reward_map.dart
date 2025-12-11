// Scripture Quest — Book to Reward Mapping
//
// Maps display book names (as used by AppProvider._normalizeDisplayBook)
// to a list of canonical Gear item ids from kGearSeedList that fit the book’s
// narrative, characters, or themes. The BookRewardService will filter out
// any ids not present in the current seed list and skip already owned items.

const Map<String, List<String>> kBookRewardMap = {
  // Torah / Pentateuch
  'Genesis': <String>[
    // Covenant and new beginnings
    'charm_rainbow_token', // Genesis 9 – covenant bow in the cloud
    'charm_olive_branch', // Genesis 8 – peace after the flood
  ],
  'Exodus': <String>[
    'hand_staff_of_moses',
    'hand_manna_jar',
    'artifact_tablets_of_the_covenant',
    'artifact_menorah_lampstand',
    // Bronze serpent is Numbers but acceptable in Exodus theme
    'artifact_bronze_serpent',
    'hand_bread_of_presence_plate',
  ],
  'Leviticus': <String>[
    'chest_priestly_breastplate',
    'hand_shofar_of_jubilee',
    'hand_censer_of_incense',
  ],
  'Numbers': <String>[
    'hand_aarons_budding_staff',
    'artifact_bronze_serpent',
    'charm_jordan_river_stone',
  ],
  'Deuteronomy': <String>[
    'artifact_tablets_of_the_covenant',
    'charm_anchor_of_hope',
  ],

  // Historical books
  'Joshua': <String>[
    'charm_jordan_river_stone',
    'feet_sandals_of_peace',
  ],
  'Judges': <String>[
    'hand_shepherds_sling',
    'head_sackcloth_hood',
  ],
  '1 Samuel': <String>[
    'charm_five_smooth_stones',
    'hand_shepherds_sling',
    'davids_harp',
  ],
  '2 Samuel': <String>[
    'chest_linen_ephod',
    'hand_shepherds_staff',
    'davids_harp',
  ],

  // Wisdom / Poetry
  'Psalms': <String>[
    'davids_harp',
    'hand_lantern_of_the_word', // Psalm 119:105
    'hand_shepherds_staff',     // Psalm 23
    'charm_five_smooth_stones', // Davidic theme
  ],

  // Major Prophets
  'Isaiah': <String>[
    'hand_scroll_of_isaiah',
    'hand_tongs_from_the_altar',
    'feet_sandals_of_peace',
  ],
  'Jeremiah': <String>[
    'hand_censer_of_incense',
    'feet_sandals_of_peace',
  ],
  'Ezekiel': <String>[
    'charm_little_scroll',
    'hand_censer_of_incense',
  ],
  'Daniel': <String>[
    'charm_anchor_of_hope',
    'head_priestly_turban',
  ],

  // Minor Prophets (representative)
  'Hosea': <String>['hand_plumb_line', 'feet_sandals_of_peace'],
  'Joel': <String>['hand_censer_of_incense'],
  'Amos': <String>['hand_plumb_line'],
  'Obadiah': <String>['head_sackcloth_hood'],
  'Jonah': <String>['head_sackcloth_hood', 'charm_small_flask_of_oil'],
  'Micah': <String>['feet_sandals_of_peace'],
  'Nahum': <String>['hand_plumb_line'],
  'Habakkuk': <String>['charm_anchor_of_hope'],
  'Zephaniah': <String>['head_sackcloth_hood'],
  'Haggai': <String>['hand_plumb_line'],
  'Zechariah': <String>['hand_plumb_line'],
  'Malachi': <String>['hand_censer_of_incense'],

  // Gospels
  'Matthew': <String>[
    'charm_bethlehem_star',
    'charm_mustard_seed_pendant',
    'feet_sandals_of_peace',
  ],
  'Mark': <String>[
    'charm_widows_mite',
    'hands_basin_and_towel',
    'feet_sandals_of_peace',
  ],
  'Luke': <String>[
    'hand_water_jars_of_cana',
    'hand_alabaster_jar',
    'feet_sandals_of_peace',
  ],
  'John': <String>[
    'hand_water_jars_of_cana',
    'hand_loaves_basket',
    'hand_fishers_net',
  ],

  // Acts
  'Acts': <String>[
    'hand_fishers_net',
    'feet_sandals_of_peace',
    'pilgrims_sandals',
  ],

  // Epistles (representative)
  'Romans': <String>['charm_anchor_of_hope'],
  '1 Corinthians': <String>['hands_basin_and_towel'],
  '2 Corinthians': <String>['hands_basin_and_towel'],
  'Galatians': <String>['charm_anchor_of_hope'],
  'Ephesians': <String>['feet_sandals_of_peace'],
  'Philippians': <String>['charm_anchor_of_hope'],
  'Colossians': <String>['hands_basin_and_towel'],
  '1 Thessalonians': <String>['pilgrims_sandals'],
  '2 Thessalonians': <String>['pilgrims_sandals'],
  '1 Timothy': <String>['hands_basin_and_towel'],
  '2 Timothy': <String>['hands_basin_and_towel'],
  'Titus': <String>['hands_basin_and_towel'],
  'Philemon': <String>['charm_small_flask_of_oil'],
  'Hebrews': <String>['charm_anchor_of_hope', 'pilgrims_sandals'],
  'James': <String>['hands_basin_and_towel'],
  '1 Peter': <String>['pilgrims_sandals'],
  '2 Peter': <String>['hand_fishers_net'],
  '1 John': <String>['hand_loaves_basket'],
  '2 John': <String>['hand_loaves_basket'],
  '3 John': <String>['hand_loaves_basket'],
  'Jude': <String>['hand_censer_of_incense'],

  // Revelation
  'Revelation': <String>[
    'charm_little_scroll', // Rev 10
    'artifact_ark_of_the_covenant',
    'hand_censer_of_incense', // Rev 8
  ],
};
