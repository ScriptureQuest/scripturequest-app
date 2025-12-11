class BibleVersion {
  final String code; // e.g., KJV, NIV
  final String name; // e.g., King James Version
  final String abbr; // e.g., KJV

  const BibleVersion({
    required this.code,
    required this.name,
    required this.abbr,
  });
}

class BibleVersions {
  // Restrict to KJV only (public domain) for now
  static const List<BibleVersion> all = [
    BibleVersion(code: 'KJV', name: 'King James Version', abbr: 'KJV'),
  ];

  static BibleVersion byCode(String code) {
    return all.firstWhere(
      (v) => v.code.toUpperCase() == code.toUpperCase(),
      orElse: () => all.first,
    );
  }
}
