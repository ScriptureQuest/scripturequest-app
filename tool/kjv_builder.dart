// Dart script to merge 66 KJV JSON files + Books.json into one consolidated
// assets/bible/kjv.json in the expected Dreamflow structure.
//
// Usage examples:
//   dart run tool/kjv_builder.dart \
//     --src /path/to/Bible-kjv \
//     --out assets/bible/kjv.json
//
// Expected input structure (from https://github.com/aruljohn/Bible-kjv):
// - Books.json
// - Genesis.json, Exodus.json, ..., Revelation.json
// Each book JSON file is an array of objects: {"chapter": n, "verse": n, "text": "..."}
// Books.json provides official order and abbreviations.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  final parsed = _ArgParser(args);
  final srcDir = parsed.get('--src') ?? parsed.get('-s') ?? './kjv_source';
  final outFilePath = parsed.get('--out') ?? parsed.get('-o') ?? 'assets/bible/kjv.json';

  final src = Directory(srcDir);
  if (!src.existsSync()) {
    stderr.writeln('Source directory not found: $srcDir');
    exit(2);
  }

  final booksIndexFile = File(_join(srcDir, 'Books.json'));
  if (!booksIndexFile.existsSync()) {
    stderr.writeln('Books.json not found in: $srcDir');
    exit(2);
  }

  // Load and normalize Books index
  final booksIndexContent = await booksIndexFile.readAsString();
  final dynamic indexJson = jsonDecode(booksIndexContent);
  final List<_BookMeta> orderedBooks = _parseBooksIndex(indexJson);
  if (orderedBooks.isEmpty) {
    stderr.writeln('Books index parsed but no books found.');
    exit(2);
  }

  stdout.writeln('Found ${orderedBooks.length} books in Books.json');

  final List<Map<String, dynamic>> booksOut = [];

  for (final meta in orderedBooks) {
    // Identify the corresponding file for this book.
    final File? bookFile = _findBookFile(srcDir, meta.name);
    if (bookFile == null || !bookFile.existsSync()) {
      stderr.writeln('WARNING: Could not find JSON file for book: ${meta.name}. Skipping.');
      continue;
    }

    final raw = await bookFile.readAsString();
    final dynamic versesJson = jsonDecode(raw);
    if (versesJson is! List) {
      stderr.writeln('Invalid book JSON (expected a List) for ${meta.name}. Skipping.');
      continue;
    }

    // Group by chapter
    final Map<int, List<Map<String, dynamic>>> byChapter = {};
    for (final item in versesJson) {
      if (item is! Map) continue;
      final ch = _asInt(item['chapter']);
      final vs = _asInt(item['verse']);
      final tx = item['text'];
      if (ch == null || vs == null || tx is! String) {
        // Skip malformed rows but do not stop the whole process.
        stderr.writeln('Skipping malformed entry in ${meta.name}: $item');
        continue;
      }
      byChapter.putIfAbsent(ch, () => []);
      byChapter[ch]!.add({
        'verse': vs,
        'text': tx,
      });
    }

    // Build sorted chapters
    final List<int> chapterNumbers = byChapter.keys.toList()..sort();
    final List<Map<String, dynamic>> chaptersOut = [];
    for (final ch in chapterNumbers) {
      final verses = byChapter[ch]!..sort((a, b) => (a['verse'] as int).compareTo(b['verse'] as int));
      chaptersOut.add({
        'chapter': ch,
        'verses': verses,
      });
    }

    booksOut.add({
      'name': meta.name, // Use name from Books.json to match official KJV naming
      'abbr': meta.abbr ?? _defaultAbbr(meta.name),
      'chapters': chaptersOut,
    });
    stdout.writeln('Processed ${meta.name}: ${chaptersOut.length} chapters');
  }

  // Create final structure
  final Map<String, dynamic> finalJson = {
    'books': booksOut,
  };

  // Ensure output directory exists
  final outFile = File(outFilePath);
  outFile.parent.createSync(recursive: true);
  final encoded = const JsonEncoder.withIndent('  ').convert(finalJson);
  await outFile.writeAsString(encoded);

  stdout.writeln('Wrote ${booksOut.length} books to $outFilePath');

  // Print start and end sections for verification
  const previewLen = 1000; // characters
  final start = encoded.substring(0, encoded.length < previewLen ? encoded.length : previewLen);
  final end = encoded.substring(encoded.length < previewLen ? 0 : encoded.length - previewLen);

  stdout.writeln('----- kjv.json START -----');
  stdout.writeln(start);
  stdout.writeln('----- kjv.json END (last ${end.length} chars) -----');
  stdout.writeln(end);
}

class _BookMeta {
  final String name; // Official book name (e.g., Genesis, Psalms)
  final String? abbr; // Abbreviation (e.g., Gen, Ps)
  const _BookMeta(this.name, this.abbr);
}

List<_BookMeta> _parseBooksIndex(dynamic indexJson) {
  // The structure of Books.json can vary.
  // We try to be resilient and support:
  // 1) List of objects: [{"name":"Genesis","abbr":"Gen"}, ...]
  // 2) {"books": [ ...same as above... ]}
  // 3) Keys might be named differently: book/title, abbr/abbrev/short
  List list; 
  if (indexJson is List) {
    list = indexJson;
  } else if (indexJson is Map && indexJson['books'] is List) {
    list = indexJson['books'];
  } else {
    return [];
  }
  return list
      .whereType<Map>()
      .map((m) {
        final name = _pickString(m, ['name', 'book', 'title', 'Book', 'Name']);
        final abbr = _pickString(m, ['abbr', 'abbrev', 'short', 'abbrv', 'Abbr']);
        if (name == null) return null;
        return _BookMeta(name, abbr);
      })
      .whereType<_BookMeta>()
      .toList();
}

String? _pickString(Map m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  return null;
}

int? _asInt(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v.trim());
  return null;
}

File? _findBookFile(String dir, String bookName) {
  // Try a few filename patterns to be robust against spaces/underscores/etc.
  final candidates = <String>{
    '$bookName.json',
    '${bookName.replaceAll(' ', '')}.json',
    '${bookName.replaceAll(' ', '_')}.json',
  };
  // Psalm/Psalms fallback
  if (bookName == 'Psalm') {
    candidates.add('Psalms.json');
  } else if (bookName == 'Psalms') {
    candidates.add('Psalm.json');
  }

  for (final name in candidates) {
    final f = File(_join(dir, name));
    if (f.existsSync()) return f;
  }

  // As a last resort, scan files to find a case-insensitive match ignoring spaces/underscores.
  final normalizedTarget = _normalize(bookName);
  final files = Directory(dir)
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.json'))
      .toList();
  for (final f in files) {
    final base = f.uri.pathSegments.last;
    if (base.toLowerCase() == 'books.json') continue;
    final name = base.substring(0, base.length - 5); // remove .json
    if (_normalize(name) == normalizedTarget) return f;
  }
  return null;
}

String _normalize(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

String _join(String a, String b) => a.endsWith(Platform.pathSeparator) ? a + b : a + Platform.pathSeparator + b;

String _defaultAbbr(String name) {
  // Simple heuristic fallback abbreviation: take first 3 letters without spaces/punctuation.
  final s = name.replaceAll(RegExp(r'[^A-Za-z]'), '');
  return s.length <= 3 ? s : s.substring(0, 3);
}

class _ArgParser {
  final Map<String, String> _map = {};
  _ArgParser(List<String> args) {
    for (var i = 0; i < args.length; i++) {
      final a = args[i];
      if (a.startsWith('--')) {
        if (i + 1 < args.length && !args[i + 1].startsWith('-')) {
          _map[a] = args[++i];
        } else {
          _map[a] = 'true';
        }
      } else if (a.startsWith('-')) {
        if (i + 1 < args.length && !args[i + 1].startsWith('-')) {
          _map[a] = args[++i];
        } else {
          _map[a] = 'true';
        }
      }
    }
  }
  String? get(String key) => _map[key];
}
