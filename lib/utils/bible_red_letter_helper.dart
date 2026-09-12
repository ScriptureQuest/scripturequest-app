import 'package:flutter/painting.dart';
import '../data/red_letter_spans.dart';

/// Edition-backed speech boundaries, verified against exact bundled verse text.
/// Unknown/different text is never guessed. See the importer and review report.
class BibleRedLetterHelper {
  static int fingerprint(String text) {
    var hash = 0;
    for (final unit in text.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }

  static List<(int, int)> ranges(
      {required String bookName,
      required int chapter,
      required int verseNumber,
      required String text}) {
    final entry = redLetterSpans['$bookName:$chapter:$verseNumber'];
    if (entry == null || entry.first != fingerprint(text)) return const [];
    return [for (var i = 1; i < entry.length; i += 2) (entry[i], entry[i + 1])];
  }

  static TextSpan render(
      {required String bookName,
      required int chapter,
      required int verseNumber,
      required String text,
      required bool enabled,
      required TextStyle bodyStyle,
      required TextStyle speechStyle}) {
    final spans = enabled
        ? ranges(
            bookName: bookName,
            chapter: chapter,
            verseNumber: verseNumber,
            text: text)
        : const <(int, int)>[];
    final children = <TextSpan>[];
    var cursor = 0;
    for (final (start, end) in spans) {
      if (start > cursor)
        children.add(TextSpan(text: text.substring(cursor, start)));
      children
          .add(TextSpan(text: text.substring(start, end), style: speechStyle));
      cursor = end;
    }
    if (cursor < text.length)
      children.add(TextSpan(text: text.substring(cursor)));
    return TextSpan(style: bodyStyle, children: children);
  }
}
