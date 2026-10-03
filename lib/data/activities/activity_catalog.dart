import '../../models/activities/activity.dart';
import '../../models/connected/passage_reference.dart';
import '../connected/connected_catalog.dart';

/// Authored clues refer to exact words in bundled KJV verses, not trivia claims.
class ActivityCatalog {
  // Existing parable titles; references are navigation context, not new quiz claims.
  static const parableReferences = {
    'The Lost Sheep': 'Luke 15:3-7',
    'The Lost Coin': 'Luke 15:8-10',
    'The Prodigal Son': 'Luke 15:11-32',
    'The Mustard Seed': 'Matthew 13:31-32',
    'Wise and Foolish Builders': 'Matthew 7:24-27',
    'The Good Samaritan': 'Luke 10:25-37',
    'The Talents': 'Matthew 25:14-30',
    'The Hidden Treasure': 'Matthew 13:44',
  };
  static const shepherd = [
    PassageWord('SHEPHERD', 'The LORD is my ___ (verse 1).', 1),
    PassageWord('GREEN', 'The colour of the pastures (verse 2).', 2),
    PassageWord('WATERS', 'He leadeth me beside the still ___ (verse 2).', 2),
    PassageWord('SOUL', 'He restoreth my ___ (verse 3).', 3),
    PassageWord('TABLE', 'Thou preparest a ___ before me (verse 5).', 5),
  ];
  static const word = [
    PassageWord('WORD', 'In the beginning was the ___ (verse 1).', 1),
    PassageWord('LIGHT', 'The life was the ___ of men (verse 4).', 4),
    PassageWord('DARKNESS', 'The light shineth in ___ (verse 5).', 5),
    PassageWord('WITNESS', 'John came for a ___ (verse 7).', 7),
    PassageWord('FLESH', 'The Word was made ___ (verse 14).', 14),
  ];
  static const night = [
    PassageWord('NIGHT', 'When Nicodemus came to Jesus (verse 2).', 2),
    PassageWord('KINGDOM', 'The ___ of God (verse 3).', 3),
    PassageWord('WIND', 'The ___ bloweth where it listeth (verse 8).', 8),
    PassageWord('WORLD', 'For God so loved the ___ (verse 16).', 16),
    PassageWord('LIFE', 'Everlasting ___ (verse 16).', 16),
  ];
  static final puzzles = <ScriptureActivity>[
    for (final kind in [ActivityKind.wordSearch, ActivityKind.crossword])
      for (final set in [
        (
          'shepherd',
          'The Shepherd’s Care',
          PassageReference('Psalms', 23),
          shepherd
        ),
        ('word', 'The Word and the Light', PassageReference('John', 1), word),
        (
          'night',
          'A Conversation at Night',
          PassageReference('John', 3),
          night
        ),
      ])
        ScriptureActivity(
            id: '${kind.name}_${set.$1}_v1',
            title: set.$2,
            description: kind == ActivityKind.wordSearch
                ? 'Find five passage words, then see each in its verse.'
                : 'Solve five crossing clues with Scripture close at hand.',
            kind: kind,
            passage: set.$3,
            words: set.$4),
  ];
  static const classics = <ScriptureActivity>[
    ScriptureActivity(
        id: 'matching_v1',
        title: 'Matching Game',
        description: 'Pair Scripture with its reference.',
        kind: ActivityKind.legacy,
        legacyRoute: '/matching-game',
        xp: 15),
    ScriptureActivity(
        id: 'scramble_v1',
        title: 'Verse Scramble',
        description: 'Restore the order of familiar passages.',
        kind: ActivityKind.legacy,
        legacyRoute: '/verse-scramble',
        xp: 14),
    ScriptureActivity(
        id: 'book_order_v1',
        title: 'Book Order',
        description: 'Learn your way around the Bible’s books.',
        kind: ActivityKind.legacy,
        legacyRoute: '/book-order-game',
        xp: 12),
    ScriptureActivity(
        id: 'parables_v1',
        title: 'Emoji Parables',
        description: 'Recognize a story and return to its context.',
        kind: ActivityKind.legacy,
        legacyRoute: '/emoji-parables',
        xp: 12),
  ];
  static List<ScriptureActivity> get all => [...puzzles, ...classics];
  static ScriptureActivity byId(String id) => all.firstWhere((a) => a.id == id);
  static Iterable<ScriptureActivity> forPassage(PassageReference p) =>
      puzzles.where((a) => a.passage!.sameChapter(p));
  static List<String> validate() {
    final errors = <String>[];
    if (all.map((a) => a.id).toSet().length != all.length)
      errors.add('Duplicate activity ID');
    for (final a in puzzles) {
      if (ConnectedCatalog.current.forPassage(a.passage!).isEmpty)
        errors.add('Unlinked passage ${a.id}');
      if (a.words.length < 3 ||
          a.words.map((w) => w.answer).toSet().length != a.words.length)
        errors.add('Invalid words ${a.id}');
      for (final w in a.words) {
        if (!RegExp(r'^[A-Z]{3,10}$').hasMatch(w.answer) || w.verse < 1)
          errors.add('Invalid word ${a.id}');
      }
    }
    return errors;
  }
}
