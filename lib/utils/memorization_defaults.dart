import 'package:flutter/foundation.dart';

/// Small curated fallback set for Memorization Practice when the user
/// has no favorited verses yet. Keep this tiny and offline-only.
class MemorizationDefaults {
  /// Verse keys use the app's display format: "Book:Chapter:Verse"
  static const List<String> curatedKeys = <String>[
    'John:3:16',
    'Psalms:23:1',
    'Philippians:4:13',
  ];

  static bool isCuratedKey(String key) {
    try {
      final k = key.trim();
      return curatedKeys.contains(k);
    } catch (e) {
      debugPrint('isCuratedKey error: $e');
      return false;
    }
  }

  // Gentle hint text shown only when using curated defaults in Practice.
  static const String hintTitle = "You're practicing some favorite verses from Scripture.";
  static const String hintBody = 'Favorite any verse in the Bible Reader to practice it here.';
}
