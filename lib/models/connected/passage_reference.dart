import '../../services/bible_service.dart';
import 'destination.dart';

/// Canonical relationship key, not a new Bible text/parser implementation.
class PassageReference {
  final String book;
  final int chapter;
  final int? verse, endVerse;
  const PassageReference(this.book, this.chapter, [this.verse, this.endVerse]);
  static PassageReference? tryParse(String? text) {
    if (text == null ||
        !RegExp(r'^.+ \d+(?::\d+(?:-\d+)?)?$').hasMatch(text.trim()))
      return null;
    final p = BibleService.instance.parseReference(text.trim());
    final b = p['bookDisplay'] as String?;
    final ch = p['chapter'] as int?;
    final v = p['verse'] as int?, end = p['verseEnd'] as int?;
    if (b == null ||
        ch == null ||
        ch < 1 ||
        ch > BibleService.instance.getChapterCount(b) ||
        (v != null && v < 1) ||
        (end != null && end < (v ?? 1))) return null;
    return PassageReference(b, ch, v, end);
  }

  String get chapterKey => '$book:$chapter';
  String get label =>
      '$book $chapter${verse == null ? '' : ':$verse${endVerse == null ? '' : '-$endVerse'}'}';
  ConnectedDestination get destination => ConnectedDestination(
      Uri(path: '/verses', queryParameters: {'ref': label}).toString());
  bool sameChapter(PassageReference other) => chapterKey == other.chapterKey;
}
