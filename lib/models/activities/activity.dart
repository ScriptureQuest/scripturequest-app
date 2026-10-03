import '../connected/passage_reference.dart';

enum ActivityKind { wordSearch, crossword, legacy }

class PassageWord {
  final String answer, clue;
  final int verse;
  const PassageWord(this.answer, this.clue, this.verse);
}

/// Stable IDs identify rewards; difficulty and randomized layouts never do.
class ScriptureActivity {
  final String id, title, description;
  final ActivityKind kind;
  final PassageReference? passage;
  final List<PassageWord> words;
  final String? legacyRoute;
  final int xp;
  const ScriptureActivity(
      {required this.id,
      required this.title,
      required this.description,
      required this.kind,
      this.passage,
      this.words = const [],
      this.legacyRoute,
      this.xp = 10});
  String get route => legacyRoute ?? '/play-learn/activity/$id';
  String get family => switch (kind) {
        ActivityKind.wordSearch => 'Word Search',
        ActivityKind.crossword => 'Crossword',
        ActivityKind.legacy => 'Classic',
      };
}
