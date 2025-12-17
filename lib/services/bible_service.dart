import 'package:flutter/foundation.dart';

/// Simple mock Bible service that returns passage text for a reference
/// and a given translation code. This can later be wired to a real API.
class BibleService {
  BibleService._internal();
  static final BibleService instance = BibleService._internal();
  // Canonical 66 books with chapter counts. Display names may differ from
  // reference names for a few cases (e.g., Psalms -> Psalm for refs).
  // Each entry: {'display': String, 'ref': String, 'chapters': int}
  static const List<Map<String, dynamic>> _books = [
    // Old Testament
    {'display': 'Genesis', 'ref': 'Genesis', 'chapters': 50},
    {'display': 'Exodus', 'ref': 'Exodus', 'chapters': 40},
    {'display': 'Leviticus', 'ref': 'Leviticus', 'chapters': 27},
    {'display': 'Numbers', 'ref': 'Numbers', 'chapters': 36},
    {'display': 'Deuteronomy', 'ref': 'Deuteronomy', 'chapters': 34},
    {'display': 'Joshua', 'ref': 'Joshua', 'chapters': 24},
    {'display': 'Judges', 'ref': 'Judges', 'chapters': 21},
    {'display': 'Ruth', 'ref': 'Ruth', 'chapters': 4},
    {'display': '1 Samuel', 'ref': '1 Samuel', 'chapters': 31},
    {'display': '2 Samuel', 'ref': '2 Samuel', 'chapters': 24},
    {'display': '1 Kings', 'ref': '1 Kings', 'chapters': 22},
    {'display': '2 Kings', 'ref': '2 Kings', 'chapters': 25},
    {'display': '1 Chronicles', 'ref': '1 Chronicles', 'chapters': 29},
    {'display': '2 Chronicles', 'ref': '2 Chronicles', 'chapters': 36},
    {'display': 'Ezra', 'ref': 'Ezra', 'chapters': 10},
    {'display': 'Nehemiah', 'ref': 'Nehemiah', 'chapters': 13},
    {'display': 'Esther', 'ref': 'Esther', 'chapters': 10},
    {'display': 'Job', 'ref': 'Job', 'chapters': 42},
    {'display': 'Psalms', 'ref': 'Psalm', 'chapters': 150},
    {'display': 'Proverbs', 'ref': 'Proverbs', 'chapters': 31},
    {'display': 'Ecclesiastes', 'ref': 'Ecclesiastes', 'chapters': 12},
    {'display': 'Song of Solomon', 'ref': 'Song of Solomon', 'chapters': 8},
    {'display': 'Isaiah', 'ref': 'Isaiah', 'chapters': 66},
    {'display': 'Jeremiah', 'ref': 'Jeremiah', 'chapters': 52},
    {'display': 'Lamentations', 'ref': 'Lamentations', 'chapters': 5},
    {'display': 'Ezekiel', 'ref': 'Ezekiel', 'chapters': 48},
    {'display': 'Daniel', 'ref': 'Daniel', 'chapters': 12},
    {'display': 'Hosea', 'ref': 'Hosea', 'chapters': 14},
    {'display': 'Joel', 'ref': 'Joel', 'chapters': 3},
    {'display': 'Amos', 'ref': 'Amos', 'chapters': 9},
    {'display': 'Obadiah', 'ref': 'Obadiah', 'chapters': 1},
    {'display': 'Jonah', 'ref': 'Jonah', 'chapters': 4},
    {'display': 'Micah', 'ref': 'Micah', 'chapters': 7},
    {'display': 'Nahum', 'ref': 'Nahum', 'chapters': 3},
    {'display': 'Habakkuk', 'ref': 'Habakkuk', 'chapters': 3},
    {'display': 'Zephaniah', 'ref': 'Zephaniah', 'chapters': 3},
    {'display': 'Haggai', 'ref': 'Haggai', 'chapters': 2},
    {'display': 'Zechariah', 'ref': 'Zechariah', 'chapters': 14},
    {'display': 'Malachi', 'ref': 'Malachi', 'chapters': 4},
    // New Testament
    {'display': 'Matthew', 'ref': 'Matthew', 'chapters': 28},
    {'display': 'Mark', 'ref': 'Mark', 'chapters': 16},
    {'display': 'Luke', 'ref': 'Luke', 'chapters': 24},
    {'display': 'John', 'ref': 'John', 'chapters': 21},
    {'display': 'Acts', 'ref': 'Acts', 'chapters': 28},
    {'display': 'Romans', 'ref': 'Romans', 'chapters': 16},
    {'display': '1 Corinthians', 'ref': '1 Corinthians', 'chapters': 16},
    {'display': '2 Corinthians', 'ref': '2 Corinthians', 'chapters': 13},
    {'display': 'Galatians', 'ref': 'Galatians', 'chapters': 6},
    {'display': 'Ephesians', 'ref': 'Ephesians', 'chapters': 6},
    {'display': 'Philippians', 'ref': 'Philippians', 'chapters': 4},
    {'display': 'Colossians', 'ref': 'Colossians', 'chapters': 4},
    {'display': '1 Thessalonians', 'ref': '1 Thessalonians', 'chapters': 5},
    {'display': '2 Thessalonians', 'ref': '2 Thessalonians', 'chapters': 3},
    {'display': '1 Timothy', 'ref': '1 Timothy', 'chapters': 6},
    {'display': '2 Timothy', 'ref': '2 Timothy', 'chapters': 4},
    {'display': 'Titus', 'ref': 'Titus', 'chapters': 3},
    {'display': 'Philemon', 'ref': 'Philemon', 'chapters': 1},
    {'display': 'Hebrews', 'ref': 'Hebrews', 'chapters': 13},
    {'display': 'James', 'ref': 'James', 'chapters': 5},
    {'display': '1 Peter', 'ref': '1 Peter', 'chapters': 5},
    {'display': '2 Peter', 'ref': '2 Peter', 'chapters': 3},
    {'display': '1 John', 'ref': '1 John', 'chapters': 5},
    {'display': '2 John', 'ref': '2 John', 'chapters': 1},
    {'display': '3 John', 'ref': '3 John', 'chapters': 1},
    {'display': 'Jude', 'ref': 'Jude', 'chapters': 1},
    {'display': 'Revelation', 'ref': 'Revelation', 'chapters': 22},
  ];

  List<String> getAllBooks() => _books.map((e) => e['display'] as String).toList(growable: false);

  int getChapterCount(String displayBook) {
    final m = _books.firstWhere((e) => (e['display'] as String).toLowerCase() == displayBook.toLowerCase(), orElse: () => const {'display': '', 'ref': '', 'chapters': 0});
    return (m['chapters'] as int?) ?? 0;
  }

  String displayToRef(String displayBook) {
    final m = _books.firstWhere((e) => (e['display'] as String).toLowerCase() == displayBook.toLowerCase(), orElse: () => const {'display': '', 'ref': ''});
    final ref = (m['ref'] as String?) ?? displayBook;
    return ref;
  }

  String refToDisplay(String refBook) {
    final m = _books.firstWhere((e) => (e['ref'] as String).toLowerCase() == refBook.toLowerCase(), orElse: () => const {'display': ''});
    final disp = (m['display'] as String?) ?? refBook;
    return disp;
  }

  /// Parse a reference like "John 3:16", "Psalm 23", "1 Thessalonians 5:1-2".
  /// Returns a tuple-like map: { 'bookDisplay': String?, 'bookRef': String?, 'chapter': int?, 'verse': int?, 'verseEnd': int? }
  Map<String, dynamic> parseReference(String reference) {
    final raw = reference.trim();
    if (raw.isEmpty) return {'bookDisplay': null, 'bookRef': null, 'chapter': null, 'verse': null, 'verseEnd': null};

    final refUpper = raw.toUpperCase();
    // Sort ref names by length desc to avoid partial matches like 'John' before '1 John'
    final refNames = _books.map((e) => e['ref'] as String).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final refName in refNames) {
      final upper = refName.toUpperCase();
      if (refUpper.startsWith(upper)) {
        // Extract chapter and verse numbers after book name
        final remainder = raw.substring(refName.length).trim();
        // Match patterns like "3", "3:16", "3:16-18"
        final match = RegExp(r'^(\d+)(?::(\d+)(?:-(\d+))?)?').firstMatch(remainder);
        final chapter = match != null ? int.tryParse(match.group(1)!) : null;
        final verse = match != null && match.group(2) != null ? int.tryParse(match.group(2)!) : null;
        final verseEnd = match != null && match.group(3) != null ? int.tryParse(match.group(3)!) : null;
        final display = refToDisplay(refName);
        return {'bookDisplay': display, 'bookRef': refName, 'chapter': chapter, 'verse': verse, 'verseEnd': verseEnd};
      }
    }
    return {'bookDisplay': null, 'bookRef': null, 'chapter': null, 'verse': null, 'verseEnd': null};
  }

  /// Normalize a book name to handle common aliases
  String normalizeBookName(String book) {
    final lower = book.trim().toLowerCase();
    // Common aliases
    if (lower == 'psalms' || lower == 'psalm') return 'Psalm';
    if (lower == 'song of songs' || lower == 'song of solomon') return 'Song of Solomon';
    if (lower == 'revelations') return 'Revelation';
    // Try to find matching book
    for (final b in _books) {
      if ((b['display'] as String).toLowerCase() == lower ||
          (b['ref'] as String).toLowerCase() == lower) {
        return b['ref'] as String;
      }
    }
    return book;
  }

  /// Get verse text for a reference (for VOTD display)
  /// Returns the verse text or null if not found
  Future<String?> getVerseText(String reference, {String versionCode = 'KJV'}) async {
    // First, try direct normalized reference lookup (simplest case)
    final directKey = reference.trim().toUpperCase();
    if (_mockPassages.containsKey(directKey)) {
      final versions = _mockPassages[directKey]!;
      return versions[versionCode.toUpperCase()] ?? versions.values.first;
    }
    
    // Parse reference for more sophisticated matching
    final parsed = parseReference(reference);
    if (parsed['bookRef'] == null || parsed['chapter'] == null) return null;
    
    final bookRef = parsed['bookRef'] as String;
    final chapter = parsed['chapter'] as int;
    final verse = parsed['verse'] as int?;
    final verseEnd = parsed['verseEnd'] as int?;
    
    // Build the lookup key
    String lookupKey;
    if (verse != null && verseEnd != null) {
      lookupKey = '$bookRef $chapter:$verse-$verseEnd'.toUpperCase();
    } else if (verse != null) {
      lookupKey = '$bookRef $chapter:$verse'.toUpperCase();
    } else {
      lookupKey = '$bookRef $chapter'.toUpperCase();
    }
    
    // Try exact match
    final versions = _mockPassages[lookupKey];
    if (versions != null) {
      return versions[versionCode.toUpperCase()] ?? versions.values.first;
    }
    
    // Try normalized book name variations
    final normalizedBook = normalizeBookName(bookRef);
    if (normalizedBook != bookRef) {
      String altKey;
      if (verse != null && verseEnd != null) {
        altKey = '$normalizedBook $chapter:$verse-$verseEnd'.toUpperCase();
      } else if (verse != null) {
        altKey = '$normalizedBook $chapter:$verse'.toUpperCase();
      } else {
        altKey = '$normalizedBook $chapter'.toUpperCase();
      }
      final altVersions = _mockPassages[altKey];
      if (altVersions != null) {
        return altVersions[versionCode.toUpperCase()] ?? altVersions.values.first;
      }
    }
    
    return null;
  }
  // Map<referenceUppercase, Map<versionCode, text>>
  final Map<String, Map<String, String>> _mockPassages = {
    'JOHN 3:16': {
      'KJV': 'For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.',
      'NIV': 'For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.',
      'ESV': 'For God so loved the world, that he gave his only Son, that whoever believes in him should not perish but have eternal life.',
      'NLT': 'For this is how God loved the world: He gave his one and only Son, so that everyone who believes in him will not perish but have eternal life.',
      'CSB': 'For God loved the world in this way: He gave his one and only Son, so that everyone who believes in him will not perish but have eternal life.',
      'NKJV': 'For God so loved the world that He gave His only begotten Son, that whoever believes in Him should not perish but have everlasting life.',
    },
    '2 CORINTHIANS 12:9': {
      'KJV': 'And he said unto me, My grace is sufficient for thee: for my strength is made perfect in weakness. Most gladly therefore will I rather glory in my infirmities, that the power of Christ may rest upon me.',
      'NIV': 'But he said to me, "My grace is sufficient for you, for my power is made perfect in weakness." Therefore I will boast all the more gladly about my weaknesses, so that Christ\'s power may rest on me.',
      'ESV': 'But he said to me, "My grace is sufficient for you, for my power is made perfect in weakness." Therefore I will boast all the more gladly of my weaknesses, so that the power of Christ may rest upon me.',
      'NLT': 'Each time he said, "My grace is all you need. My power works best in weakness." So now I am glad to boast about my weaknesses, so that the power of Christ can work through me.',
      'CSB': 'But he said to me, "My grace is sufficient for you, for my power is perfected in weakness." Therefore, I will most gladly boast all the more about my weaknesses, so that Christ\'s power may reside in me.',
      'NKJV': 'And He said to me, "My grace is sufficient for you, for My strength is made perfect in weakness." Therefore most gladly I will rather boast in my infirmities, that the power of Christ may rest upon me.',
    },
    'PROVERBS 3:5-6': {
      'KJV': 'Trust in the LORD with all thine heart; and lean not unto thine own understanding. In all thy ways acknowledge him, and he shall direct thy paths.',
      'NIV': 'Trust in the LORD with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight.',
      'ESV': 'Trust in the LORD with all your heart, and do not lean on your own understanding. In all your ways acknowledge him, and he will make straight your paths.',
      'NLT': 'Trust in the LORD with all your heart; do not depend on your own understanding. Seek his will in all you do, and he will show you which path to take.',
      'CSB': 'Trust in the LORD with all your heart, and do not rely on your own understanding; in all your ways know him, and he will make your paths straight.',
      'NKJV': 'Trust in the LORD with all your heart, And lean not on your own understanding; In all your ways acknowledge Him, And He shall direct your paths.',
    },
    'JEREMIAH 29:11': {
      'KJV': 'For I know the thoughts that I think toward you, saith the LORD, thoughts of peace, and not of evil, to give you an expected end.',
      'NIV': '"For I know the plans I have for you," declares the LORD, "plans to prosper you and not to harm you, plans to give you hope and a future."',
      'ESV': 'For I know the plans I have for you, declares the LORD, plans for welfare and not for evil, to give you a future and a hope.',
      'NLT': 'For I know the plans I have for you," says the LORD. "They are plans for good and not for disaster, to give you a future and a hope.',
      'CSB': 'For I know the plans I have for you"—this is the LORD\'s declaration—"plans for your well-being, not for disaster, to give you a future and a hope.',
      'NKJV': 'For I know the thoughts that I think toward you, says the LORD, thoughts of peace and not of evil, to give you a future and a hope.',
    },
    'ISAIAH 41:10': {
      'KJV': 'Fear thou not; for I am with thee: be not dismayed; for I am thy God: I will strengthen thee; yea, I will help thee; yea, I will uphold thee with the right hand of my righteousness.',
      'NIV': 'So do not fear, for I am with you; do not be dismayed, for I am your God. I will strengthen you and help you; I will uphold you with my righteous right hand.',
      'ESV': 'Fear not, for I am with you; be not dismayed, for I am your God; I will strengthen you, I will help you, I will uphold you with my righteous right hand.',
      'NLT': 'Don\'t be afraid, for I am with you. Don\'t be discouraged, for I am your God. I will strengthen you and help you. I will hold you up with my victorious right hand.',
      'CSB': 'Do not fear, for I am with you; do not be afraid, for I am your God. I will strengthen you; I will help you; I will hold on to you with my righteous right hand.',
      'NKJV': 'Fear not, for I am with you; Be not dismayed, for I am your God. I will strengthen you, Yes, I will help you, I will uphold you with My righteous right hand.',
    },
    'ROMANS 8:28': {
      'KJV': 'And we know that all things work together for good to them that love God, to them who are the called according to his purpose.',
      'NIV': 'And we know that in all things God works for the good of those who love him, who have been called according to his purpose.',
      'ESV': 'And we know that for those who love God all things work together for good, for those who are called according to his purpose.',
      'NLT': 'And we know that God causes everything to work together for the good of those who love God and are called according to his purpose for them.',
      'CSB': 'We know that all things work together for the good of those who love God, who are called according to his purpose.',
      'NKJV': 'And we know that all things work together for good to those who love God, to those who are the called according to His purpose.',
    },
    'JOSHUA 1:9': {
      'KJV': 'Have not I commanded thee? Be strong and of a good courage; be not afraid, neither be thou dismayed: for the LORD thy God is with thee whithersoever thou goest.',
      'NIV': 'Have I not commanded you? Be strong and courageous. Do not be afraid; do not be discouraged, for the LORD your God will be with you wherever you go.',
      'ESV': 'Have I not commanded you? Be strong and courageous. Do not be frightened, and do not be dismayed, for the LORD your God is with you wherever you go.',
      'NLT': 'This is my command—be strong and courageous! Do not be afraid or discouraged. For the LORD your God is with you wherever you go.',
      'CSB': 'Haven\'t I commanded you: be strong and courageous? Do not be afraid or discouraged, for the LORD your God is with you wherever you go.',
      'NKJV': 'Have I not commanded you? Be strong and of good courage; do not be afraid, nor be dismayed, for the LORD your God is with you wherever you go.',
    },
    '1 JOHN 1:9': {
      'KJV': 'If we confess our sins, he is faithful and just to forgive us our sins, and to cleanse us from all unrighteousness.',
      'NIV': 'If we confess our sins, he is faithful and just and will forgive us our sins and purify us from all unrighteousness.',
      'ESV': 'If we confess our sins, he is faithful and just to forgive us our sins and to cleanse us from all unrighteousness.',
      'NLT': 'But if we confess our sins to him, he is faithful and just to forgive us our sins and to cleanse us from all wickedness.',
      'CSB': 'If we confess our sins, he is faithful and righteous to forgive us our sins and to cleanse us from all unrighteousness.',
      'NKJV': 'If we confess our sins, He is faithful and just to forgive us our sins and to cleanse us from all unrighteousness.',
    },
    'PSALM 23:1-4': {
      'KJV': 'The LORD is my shepherd; I shall not want. He maketh me to lie down in green pastures: he leadeth me beside the still waters. He restoreth my soul: he leadeth me in the paths of righteousness for his name\'s sake. Yea, though I walk through the valley of the shadow of death, I will fear no evil: for thou art with me; thy rod and thy staff they comfort me.',
      'NIV': 'The LORD is my shepherd, I lack nothing. He makes me lie down in green pastures, he leads me beside quiet waters, he refreshes my soul. He guides me along the right paths for his name’s sake. Even though I walk through the darkest valley, I will fear no evil, for you are with me; your rod and your staff, they comfort me.',
      'ESV': 'The LORD is my shepherd; I shall not want. He makes me lie down in green pastures. He leads me beside still waters. He restores my soul. He leads me in paths of righteousness for his name\'s sake. Even though I walk through the valley of the shadow of death, I will fear no evil, for you are with me; your rod and your staff, they comfort me.',
      'NLT': 'The LORD is my shepherd; I have all that I need. He lets me rest in green meadows; he leads me beside peaceful streams. He renews my strength. He guides me along right paths, bringing honor to his name. Even when I walk through the darkest valley, I will not be afraid, for you are close beside me. Your rod and your staff protect and comfort me.',
      'CSB': 'The LORD is my shepherd; I have what I need. He lets me lie down in green pastures; he leads me beside quiet waters. He renews my life; he leads me along the right paths for his name\'s sake. Even when I go through the darkest valley, I fear no danger, for you are with me; your rod and your staff—they comfort me.',
      'NKJV': 'The LORD is my shepherd; I shall not want. He makes me to lie down in green pastures; He leads me beside the still waters. He restores my soul; He leads me in the paths of righteousness For His name’s sake. Yea, though I walk through the valley of the shadow of death, I will fear no evil; For You are with me; Your rod and Your staff, they comfort me.',
    },
    'PHILIPPIANS 4:6-7': {
      'KJV': 'Be careful for nothing; but in every thing by prayer and supplication with thanksgiving let your requests be made known unto God. And the peace of God, which passeth all understanding, shall keep your hearts and minds through Christ Jesus.',
      'NIV': 'Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God. And the peace of God, which transcends all understanding, will guard your hearts and your minds in Christ Jesus.',
      'ESV': 'Do not be anxious about anything, but in everything by prayer and supplication with thanksgiving let your requests be made known to God. And the peace of God, which surpasses all understanding, will guard your hearts and your minds in Christ Jesus.',
      'NLT': 'Don’t worry about anything; instead, pray about everything. Tell God what you need, and thank him for all he has done. Then you will experience God’s peace, which exceeds anything we can understand. His peace will guard your hearts and minds as you live in Christ Jesus.',
      'CSB': 'Don’t worry about anything, but in everything, through prayer and petition with thanksgiving, present your requests to God. And the peace of God, which surpasses all understanding, will guard your hearts and minds in Christ Jesus.',
      'NKJV': 'Be anxious for nothing, but in everything by prayer and supplication, with thanksgiving, let your requests be made known to God; and the peace of God, which surpasses all understanding, will guard your hearts and minds through Christ Jesus.',
    },
  };

  String _normalizeRef(String reference) => reference.trim().toUpperCase();

  Future<String> getPassage(String reference, String versionCode) async {
    try {
      final key = _normalizeRef(reference);
      final versions = _mockPassages[key];
      if (versions == null) return 'Passage not available in mock yet. Try another reference.';
      final text = versions[versionCode.toUpperCase()];
      return text ?? 'Passage for $versionCode not available in mock yet.';
    } catch (e) {
      debugPrint('BibleService.getPassage error: $e');
      return 'Error loading passage.';
    }
  }

  /// Returns a mock chapter text for the given book (display or ref name) and chapter.
  ///
  /// - If we have known verse/range samples for the requested chapter, we stitch
  ///   a minimal chapter view using those samples and a clear mock notice.
  /// - Otherwise we return a helpful mock placeholder indicating where the full
  ///   chapter would appear once a real data source is connected.
  Future<String> getChapterText({
    required String book,
    required int chapter,
    required String versionCode,
  }) async {
    try {
      // Normalize to ref name (e.g., Psalms -> Psalm for references)
      final refBook = displayToRef(book);
      final upperRefBook = refBook.toUpperCase();
      final upperVersion = versionCode.toUpperCase();

      // Special cases where we have partial content to showcase a chapter view
      // 1) John 3 — we have John 3:16 across versions
      if (upperRefBook == 'JOHN' && chapter == 3) {
        final v16 = _mockPassages['JOHN 3:16']?[upperVersion] ??
            _mockPassages['JOHN 3:16']?.values.first;
        final snippet = v16 ?? '';
        return 'John 3 (Chapter View) — $upperVersion\n\n'
            '[1] (Mock) Verse text not included in demo.\n'
            '[2] (Mock) Verse text not included in demo.\n'
            '...\n'
            '[16] $snippet\n'
            '...\n\n'
            '(Mock) Additional verses omitted. Full chapter will appear when connected to a real Bible source.';
      }

      // 2) Psalm 23 — we have Psalm 23:1-4 across versions
      if ((upperRefBook == 'PSALM' || upperRefBook == 'PSALMS') && chapter == 23) {
        final sample = _mockPassages['PSALM 23:1-4']?[upperVersion] ??
            _mockPassages['PSALM 23:1-4']?.values.first ?? '';
        return 'Psalm 23 (Chapter View) — $upperVersion\n\n'
            '$sample\n\n'
            '(Mock) Remaining verses are omitted in this demo. Full chapter will appear with a real data source.';
      }

      // 3) Philippians 4 — we have 4:6-7 across versions
      if (upperRefBook == 'PHILIPPIANS' && chapter == 4) {
        final sample = _mockPassages['PHILIPPIANS 4:6-7']?[upperVersion] ??
            _mockPassages['PHILIPPIANS 4:6-7']?.values.first ?? '';
        return 'Philippians 4 (Chapter View) — $upperVersion\n\n'
            '$sample\n\n'
            '(Mock) Remaining verses are omitted in this demo. Full chapter will appear with a real data source.';
      }

      // General placeholder for all other books/chapters
      final displayBook = refToDisplay(refBook);
      return '(Mock) $displayBook $chapter — full chapter text in $upperVersion would be displayed here when connected to a real Bible source.';
    } catch (e) {
      debugPrint('BibleService.getChapterText error: $e');
      return 'Error loading chapter.';
    }
  }
}
