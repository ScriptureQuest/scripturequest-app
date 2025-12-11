import 'package:flutter/foundation.dart';
/// Range model for verse spans (inclusive).
class _VerseRange {
  final int start;
  final int end;
  const _VerseRange(this.start, this.end);

  bool contains(int verse) => verse >= start && verse <= end;
}

class BibleRedLetterHelper {
  /// Range-based red-letter coverage for key Jesus passages.
  ///
  /// Structure: book -> chapter -> list of inclusive verse ranges.
  /// Keep this local, fast, and lightweight (no I/O; O(small) lookup).
  static final Map<String, Map<int, List<_VerseRange>>> _jesusRanges = {
    // Matthew — comprehensive red-letter ranges (KJV style)
    'Matthew': {
      // Early sayings and replies
      3: const [ _VerseRange(15, 15) ],
      4: const [ _VerseRange(4, 4), _VerseRange(7, 7), _VerseRange(10, 10), _VerseRange(17, 17) ],
      // Sermon on the Mount
      5: const [ _VerseRange(3, 48) ],
      6: const [ _VerseRange(1, 34) ],
      7: const [ _VerseRange(1, 29) ],
      // Miracles and teachings
      8: const [
        _VerseRange(3, 4), _VerseRange(7, 7), _VerseRange(10, 13), _VerseRange(20, 22),
        _VerseRange(26, 26), _VerseRange(32, 32),
      ],
      9: const [
        _VerseRange(2, 7), _VerseRange(9, 13), _VerseRange(15, 17), _VerseRange(22, 22), _VerseRange(24, 26),
        _VerseRange(28, 30), _VerseRange(37, 38),
      ],
      // Mission discourse
      10: const [ _VerseRange(5, 42) ],
      11: const [ _VerseRange(4, 30) ],
      12: const [
        _VerseRange(3, 8), _VerseRange(11, 13), _VerseRange(25, 37), _VerseRange(39, 45), _VerseRange(48, 50),
      ],
      // Parables discourse
      13: const [ _VerseRange(3, 52) ],
      14: const [ _VerseRange(16, 18), _VerseRange(27, 31) ],
      15: const [ _VerseRange(3, 9), _VerseRange(13, 20), _VerseRange(24, 28), _VerseRange(32, 32) ],
      16: const [ _VerseRange(2, 3), _VerseRange(6, 11), _VerseRange(13, 20), _VerseRange(23, 28) ],
      17: const [ _VerseRange(7, 7), _VerseRange(9, 12), _VerseRange(17, 21), _VerseRange(22, 23), _VerseRange(25, 26) ],
      18: const [ _VerseRange(3, 35) ],
      19: const [ _VerseRange(4, 6), _VerseRange(8, 12), _VerseRange(14, 14), _VerseRange(17, 30) ],
      20: const [ _VerseRange(13, 15), _VerseRange(18, 19), _VerseRange(21, 23), _VerseRange(25, 28), _VerseRange(32, 34) ],
      21: const [
        _VerseRange(2, 3), _VerseRange(13, 13), _VerseRange(16, 16), _VerseRange(19, 22), _VerseRange(24, 25),
        _VerseRange(27, 27), _VerseRange(31, 32), _VerseRange(34, 44),
      ],
      22: const [ _VerseRange(2, 14), _VerseRange(18, 21), _VerseRange(29, 32), _VerseRange(37, 40), _VerseRange(42, 46) ],
      23: const [ _VerseRange(2, 39) ],
      // Olivet discourse
      24: const [ _VerseRange(2, 51) ],
      25: const [ _VerseRange(1, 46) ],
      26: const [
        _VerseRange(10, 13), _VerseRange(18, 18), _VerseRange(21, 25), _VerseRange(26, 29), _VerseRange(31, 32),
        _VerseRange(34, 34), _VerseRange(36, 46), _VerseRange(50, 50), _VerseRange(52, 54), _VerseRange(55, 55), _VerseRange(64, 64),
      ],
      27: const [ _VerseRange(11, 11), _VerseRange(46, 46) ],
      28: const [ _VerseRange(9, 10), _VerseRange(18, 20) ],
    },

    // Mark — comprehensive ranges
    'Mark': {
      1: const [ _VerseRange(15, 17), _VerseRange(38, 38), _VerseRange(41, 44) ],
      2: const [ _VerseRange(5, 12), _VerseRange(14, 14), _VerseRange(17, 17), _VerseRange(19, 22), _VerseRange(25, 28) ],
      3: const [ _VerseRange(3, 5), _VerseRange(23, 30), _VerseRange(33, 35) ],
      4: const [ _VerseRange(3, 32), _VerseRange(35, 35), _VerseRange(39, 40) ],
      5: const [ _VerseRange(8, 9), _VerseRange(19, 19), _VerseRange(30, 30), _VerseRange(34, 36), _VerseRange(39, 41) ],
      6: const [ _VerseRange(4, 4), _VerseRange(10, 11), _VerseRange(31, 31), _VerseRange(37, 38), _VerseRange(50, 52) ],
      7: const [ _VerseRange(6, 13), _VerseRange(18, 23), _VerseRange(27, 29), _VerseRange(34, 34) ],
      8: const [ _VerseRange(2, 3), _VerseRange(5, 5), _VerseRange(12, 12), _VerseRange(15, 15), _VerseRange(17, 21), _VerseRange(27, 38) ],
      9: const [ _VerseRange(1, 1), _VerseRange(12, 13), _VerseRange(19, 19), _VerseRange(21, 25), _VerseRange(29, 31), _VerseRange(33, 50) ],
      10: const [
        _VerseRange(3, 9), _VerseRange(11, 11), _VerseRange(14, 15), _VerseRange(18, 21), _VerseRange(23, 25), _VerseRange(27, 27),
        _VerseRange(29, 31), _VerseRange(33, 34), _VerseRange(36, 40), _VerseRange(42, 45), _VerseRange(49, 49), _VerseRange(52, 52),
      ],
      11: const [ _VerseRange(2, 3), _VerseRange(14, 14), _VerseRange(17, 17), _VerseRange(22, 26), _VerseRange(29, 33) ],
      12: const [ _VerseRange(1, 44) ],
      13: const [ _VerseRange(2, 37) ],
      14: const [ _VerseRange(6, 9), _VerseRange(13, 15), _VerseRange(18, 21), _VerseRange(22, 25), _VerseRange(27, 30), _VerseRange(32, 42), _VerseRange(48, 49), _VerseRange(62, 62) ],
      15: const [ _VerseRange(2, 2), _VerseRange(34, 34) ],
      16: const [ _VerseRange(15, 18) ],
    },

    // Luke — comprehensive ranges
    'Luke': {
      2: const [ _VerseRange(49, 49) ],
      4: const [ _VerseRange(4, 4), _VerseRange(8, 8), _VerseRange(12, 12), _VerseRange(21, 27), _VerseRange(35, 35), _VerseRange(43, 43) ],
      5: const [ _VerseRange(4, 4), _VerseRange(10, 10), _VerseRange(13, 14), _VerseRange(20, 24), _VerseRange(27, 32), _VerseRange(34, 35) ],
      6: const [ _VerseRange(3, 5), _VerseRange(9, 9), _VerseRange(20, 49) ],
      7: const [ _VerseRange(9, 9), _VerseRange(13, 15), _VerseRange(22, 23), _VerseRange(25, 28), _VerseRange(31, 35), _VerseRange(40, 50) ],
      8: const [ _VerseRange(5, 18), _VerseRange(21, 21), _VerseRange(25, 25), _VerseRange(30, 30), _VerseRange(39, 39), _VerseRange(45, 48), _VerseRange(50, 50), _VerseRange(52, 55) ],
      9: const [ _VerseRange(3, 5), _VerseRange(13, 14), _VerseRange(18, 27), _VerseRange(41, 41), _VerseRange(44, 44), _VerseRange(48, 50), _VerseRange(55, 62) ],
      10: const [ _VerseRange(2, 24), _VerseRange(26, 37), _VerseRange(41, 42) ],
      11: const [ _VerseRange(2, 13), _VerseRange(17, 26), _VerseRange(29, 32), _VerseRange(34, 52) ],
      12: const [ _VerseRange(1, 59) ],
      13: const [ _VerseRange(2, 9), _VerseRange(12, 12), _VerseRange(15, 21), _VerseRange(24, 30), _VerseRange(32, 35) ],
      14: const [ _VerseRange(3, 6), _VerseRange(8, 14), _VerseRange(16, 35) ],
      15: const [ _VerseRange(4, 32) ],
      16: const [ _VerseRange(10, 31) ],
      17: const [ _VerseRange(6, 10), _VerseRange(14, 14), _VerseRange(17, 19), _VerseRange(20, 37) ],
      18: const [ _VerseRange(2, 8), _VerseRange(16, 17), _VerseRange(19, 22), _VerseRange(24, 27), _VerseRange(29, 30), _VerseRange(41, 42) ],
      19: const [ _VerseRange(5, 10), _VerseRange(12, 27), _VerseRange(30, 31), _VerseRange(40, 46) ],
      20: const [ _VerseRange(3, 8), _VerseRange(9, 40), _VerseRange(41, 44), _VerseRange(46, 47) ],
      21: const [ _VerseRange(3, 3), _VerseRange(8, 36) ],
      22: const [
        _VerseRange(8, 8), _VerseRange(10, 13), _VerseRange(15, 22), _VerseRange(31, 34), _VerseRange(35, 38), _VerseRange(40, 40),
        _VerseRange(42, 42), _VerseRange(46, 46), _VerseRange(48, 48), _VerseRange(51, 53), _VerseRange(67, 69),
      ],
      23: const [ _VerseRange(28, 31), _VerseRange(34, 34), _VerseRange(43, 43), _VerseRange(46, 46) ],
      24: const [ _VerseRange(17, 19), _VerseRange(25, 27), _VerseRange(36, 39), _VerseRange(41, 49) ],
    },

    // John — comprehensive ranges
    'John': {
      1: const [ _VerseRange(38, 39), _VerseRange(42, 43), _VerseRange(47, 51) ],
      2: const [ _VerseRange(4, 4), _VerseRange(7, 8), _VerseRange(16, 19) ],
      3: const [ _VerseRange(3, 21) ],
      4: const [ _VerseRange(7, 26), _VerseRange(32, 32), _VerseRange(34, 38), _VerseRange(48, 54) ],
      5: const [ _VerseRange(6, 9), _VerseRange(11, 12), _VerseRange(14, 14), _VerseRange(17, 47) ],
      6: const [ _VerseRange(5, 6), _VerseRange(10, 10), _VerseRange(20, 20), _VerseRange(26, 40), _VerseRange(43, 58), _VerseRange(61, 65), _VerseRange(67, 71) ],
      7: const [ _VerseRange(6, 8), _VerseRange(16, 24), _VerseRange(28, 29), _VerseRange(33, 34), _VerseRange(37, 38) ],
      8: const [ _VerseRange(7, 7), _VerseRange(10, 14), _VerseRange(16, 19), _VerseRange(23, 26), _VerseRange(28, 29), _VerseRange(31, 59) ],
      9: const [ _VerseRange(3, 5), _VerseRange(7, 7), _VerseRange(35, 41) ],
      10: const [ _VerseRange(1, 18), _VerseRange(25, 30), _VerseRange(32, 32), _VerseRange(34, 38) ],
      11: const [ _VerseRange(4, 4), _VerseRange(7, 7), _VerseRange(9, 11), _VerseRange(14, 15), _VerseRange(23, 26), _VerseRange(34, 44) ],
      12: const [ _VerseRange(7, 8), _VerseRange(23, 28), _VerseRange(32, 32), _VerseRange(35, 36), _VerseRange(44, 50) ],
      13: const [ _VerseRange(7, 38) ],
      14: const [ _VerseRange(1, 31) ],
      15: const [ _VerseRange(1, 27) ],
      16: const [ _VerseRange(5, 33) ],
      17: const [ _VerseRange(1, 26) ],
      18: const [ _VerseRange(4, 8), _VerseRange(11, 11), _VerseRange(20, 23), _VerseRange(34, 37) ],
      19: const [ _VerseRange(11, 11), _VerseRange(26, 27), _VerseRange(28, 28), _VerseRange(30, 30) ],
      20: const [ _VerseRange(15, 18), _VerseRange(19, 23), _VerseRange(26, 29) ],
      21: const [ _VerseRange(5, 7), _VerseRange(10, 10), _VerseRange(12, 12), _VerseRange(15, 23) ],
    },

    // Acts — Jesus' post-resurrection words (red-letter in many KJV editions)
    'Acts': {
      1: const [ _VerseRange(4, 8) ],
    },
  };

  /// Determines if the given verse is within a Jesus-speaking range.
  /// Book name should match the display name from BibleService (e.g., "Matthew").
  static bool isJesusSpeaking({
    required String bookName,
    required int chapter,
    required int verseNumber,
  }) {
    // Fast lookup with graceful fallbacks.
    bool isSpeaking = false;
    final mapByBook = _jesusRanges[bookName];
    if (mapByBook != null) {
      final ranges = mapByBook[chapter];
      if (ranges != null && ranges.isNotEmpty) {
        for (final r in ranges) {
          if (r.contains(verseNumber)) {
            isSpeaking = true;
            break;
          }
        }
      }
    }
    // Temporary diagnostics for Build 3.5 verification
    debugPrint('RedLetterCheck → $bookName $chapter:$verseNumber → $isSpeaking');
    return isSpeaking;
  }
}
