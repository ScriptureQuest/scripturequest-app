import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:level_up_your_faith/models/verse_bookmark.dart';
import 'package:level_up_your_faith/services/storage_service.dart';

class BookmarkService {
  final StorageService _storage;

  BookmarkService(this._storage);

  String _keyForUser(String userId) => 'bookmarks_$userId';

  Future<List<VerseBookmark>> getBookmarksForUser(String userId) async {
    if (userId.trim().isEmpty) return [];
    try {
      final key = _keyForUser(userId);
      final raw = _storage.getString(key);
      if (raw == null) return [];
      final List<dynamic> list = jsonDecode(raw);
      final out = <VerseBookmark>[];
      for (final item in list) {
        try {
          final bm = VerseBookmark.fromJson(item as Map<String, dynamic>);
          out.add(bm);
        } catch (e) {
          debugPrint('Skipping corrupted bookmark: $e');
        }
      }
      return out;
    } catch (e) {
      debugPrint('BookmarkService.getBookmarksForUser error: $e');
      return [];
    }
  }

  Future<void> saveBookmarksForUser(String userId, List<VerseBookmark> bookmarks) async {
    if (userId.trim().isEmpty) return;
    try {
      final key = _keyForUser(userId);
      final list = bookmarks.map((e) => e.toJson()).toList();
      await _storage.save(key, jsonEncode(list));
    } catch (e) {
      debugPrint('BookmarkService.saveBookmarksForUser error: $e');
    }
  }
}
