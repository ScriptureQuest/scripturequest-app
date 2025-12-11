import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:level_up_your_faith/services/bible_service.dart';

/// KJV-only Bible service backed by a local JSON asset.
///
/// NOTE: The file assets/bible/kjv.json should contain the FULL KJV text
/// in the structure described below. Right now it may contain only a sample.
/// Once replaced with the full dataset, the Bible tab will support every
/// book/chapter/verse offline.
///
/// Expected JSON shape (abbreviated):
/// {
///   "books": [
///     {
///       "name": "Genesis",
///       "abbr": "Gen",
///       "chapters": [
///         { "chapter": 1, "verses": [ {"verse": 1, "text": "..."}, ... ] },
///         { "chapter": 2, "verses": [ ... ] }
///       ]
///     },
///     ...
///   ]
/// }
class KJVBibleService {
  KJVBibleService();

  // Map: Canonical display book name -> chapter -> list of verse maps
  final Map<String, Map<int, List<Map<String, dynamic>>>> _bookChapterVerseMap = {};
  // Lookup: case-insensitive key -> canonical display book name
  final Map<String, String> _bookKeyToCanonical = {};
  bool _initialized = false;

  final BibleService _helper = BibleService.instance;

  String _norm(String s) => s.trim().toLowerCase();

  void _indexBookName(String key, String canonical) {
    if (key.trim().isEmpty) return;
    _bookKeyToCanonical[_norm(key)] = canonical;
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/bible/kjv.json');
      final dynamic data = jsonDecode(jsonStr);
      final books = (data['books'] as List<dynamic>?);
      if (books == null) {
        debugPrint('KJVBibleService init: no books array in JSON');
        _initialized = true; // Avoid repeated attempts
        return;
      }

      for (final dynamic b in books) {
        if (b is! Map) continue;
        final name = (b['name'] as String? ?? '').trim();
        if (name.isEmpty) continue;
        final abbr = (b['abbr'] as String? ?? '').trim();
        final chapters = (b['chapters'] as List<dynamic>? ?? const []);

        // Build chapter -> verses list
        final chapterMap = <int, List<Map<String, dynamic>>>{};
        for (final dynamic c in chapters) {
          if (c is! Map) continue;
          final chNum = c['chapter'] is int ? c['chapter'] as int : int.tryParse('${c['chapter']}') ?? 0;
          if (chNum <= 0) continue;
          final verses = (c['verses'] as List<dynamic>? ?? const [])
              .whereType<Map>()
              .map((v) => {
                    'verse': v['verse'] is int ? v['verse'] as int : int.tryParse('${v['verse']}') ?? 0,
                    'text': (v['text'] as String? ?? '').trim(),
                  })
              .where((m) => (m['verse'] as int) > 0 && (m['text'] as String).isNotEmpty)
              .toList(growable: false);
          chapterMap[chNum] = verses;
        }

        _bookChapterVerseMap[name] = chapterMap;

        // Index common keys to resolve user inputs
        _indexBookName(name, name);
        if (abbr.isNotEmpty) _indexBookName(abbr, name);
        // Index BibleService variants (display<->ref)
        _indexBookName(_helper.displayToRef(name), name); // e.g., Psalms -> Psalm
        _indexBookName(_helper.refToDisplay(name), name); // usually identity

        // A couple of common synonyms just in case
        if (_norm(name) == 'psalms') _indexBookName('psalm', name);
        if (_norm(name) == 'song of solomon') {
          _indexBookName('song of songs', name);
          _indexBookName('canticles', name);
        }
      }

      _initialized = true;
    } catch (e) {
      debugPrint('KJVBibleService init error: $e');
      _initialized = true; // prevent repeated attempts during session
    }
  }

  String? _resolveCanonical(String anyBook) {
    final key = _norm(anyBook);
    if (_bookKeyToCanonical.containsKey(key)) return _bookKeyToCanonical[key];
    // Last attempt: try converting via BibleService both directions
    final ref = _helper.displayToRef(anyBook);
    if (_bookKeyToCanonical.containsKey(_norm(ref))) return _bookKeyToCanonical[_norm(ref)];
    final disp = _helper.refToDisplay(anyBook);
    if (_bookKeyToCanonical.containsKey(_norm(disp))) return _bookKeyToCanonical[_norm(disp)];
    return null;
  }

  /// Build a human-readable chapter string like:
  /// 1 In the beginning ...\n2 And the earth ...\n...
  String _buildChapterString(List<Map<String, dynamic>> verses) {
    final buffer = StringBuffer();
    for (final v in verses) {
      final n = v['verse'] as int? ?? 0;
      final t = v['text'] as String? ?? '';
      if (n <= 0 || t.isEmpty) continue;
      buffer.writeln('$n $t');
    }
    return buffer.toString().trimRight();
  }

  /// Returns the full chapter text for the given display/ref book name and chapter.
  Future<String> getChapterText({
    required String book,
    required int chapter,
  }) async {
    await _ensureInitialized();
    try {
      final b = book.trim();
      if (b.isEmpty || chapter <= 0) {
        return 'KJV text for $book $chapter is not available. Please check the KJV data file.';
      }
      final canonical = _resolveCanonical(b);
      if (canonical == null) {
        return 'KJV text for $book $chapter is not available. Please check the KJV data file.';
      }
      final chMap = _bookChapterVerseMap[canonical];
      final verses = chMap?[chapter];
      if (verses == null || verses.isEmpty) {
        return 'KJV text for $canonical $chapter is not available. Please check the KJV data file.';
      }
      return _buildChapterString(verses);
    } catch (e) {
      debugPrint('KJVBibleService.getChapterText error: $e');
      return 'Error loading chapter.';
    }
  }

  /// Returns a passage based on a reference like "John 3:16" or "Psalm 23".
  Future<String> getPassage({
    required String reference,
  }) async {
    await _ensureInitialized();
    try {
      final ref = reference.trim();
      if (ref.isEmpty) {
        return 'KJV passage for $reference is not available. Please check the KJV data file.';
      }

      final parsed = _helper.parseReference(ref);
      final bookDisplay = (parsed['bookDisplay'] as String?) ?? '';
      final chapter = (parsed['chapter'] as int?) ?? 0;

      // If a specific verse is requested, prefer that verse. Otherwise, full chapter.
      final verseMatch = RegExp(r':\s*(\d+)').firstMatch(ref);
      if (verseMatch != null) {
        final verseNum = int.tryParse(verseMatch.group(1) ?? '0') ?? 0;
        if (verseNum > 0 && chapter > 0) {
          final canonical = _resolveCanonical(bookDisplay);
          if (canonical != null) {
            final verses = _bookChapterVerseMap[canonical]?[chapter];
            final v = verses?.firstWhere(
              (m) => (m['verse'] as int? ?? 0) == verseNum,
              orElse: () => const {'verse': 0, 'text': ''},
            );
            final text = (v?['text'] as String? ?? '').trim();
            if (text.isNotEmpty) {
              return '$bookDisplay $chapter:$verseNum\n$text';
            }
          }
        }
        return 'KJV passage for $reference is not available. Please check the KJV data file.';
      }

      // Chapter-only reference
      if (bookDisplay.isNotEmpty && chapter > 0) {
        return getChapterText(book: bookDisplay, chapter: chapter);
      }
      return 'KJV passage for $reference is not available. Please check the KJV data file.';
    } catch (e) {
      debugPrint('KJVBibleService.getPassage error: $e');
      return 'Error loading passage.';
    }
  }
}
