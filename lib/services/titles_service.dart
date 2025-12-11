import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:level_up_your_faith/services/storage_service.dart';

/// Minimal titles service: unlocks and lists user titles locally.
class TitlesService {
  final StorageService _storage;
  TitlesService(this._storage);

  String _key(String uid) => 'titles_$uid';
  String _equippedKey(String uid) => 'equipped_title_$uid';

  Future<List<String>> _load(String uid) async {
    try {
      final s = _storage.getString(_key(uid));
      if (s == null || s.trim().isEmpty) return <String>[];
      final raw = jsonDecode(s);
      return List<String>.from(raw ?? const []);
    } catch (e) {
      debugPrint('TitlesService._load error: $e');
      return <String>[];
    }
  }

  Future<void> _save(String uid, List<String> titles) async {
    try {
      await _storage.save(_key(uid), jsonEncode(titles));
    } catch (e) {
      debugPrint('TitlesService._save error: $e');
    }
  }

  Future<void> unlockTitle(String id, {String uid = 'local'}) async {
    final list = await _load(uid);
    if (!list.contains(id)) {
      list.add(id);
      await _save(uid, list);
    }
  }

  Future<List<String>> getTitles({String uid = 'local'}) async {
    return await _load(uid);
  }

  Future<void> setEquippedTitle(String id, {String uid = 'local'}) async {
    try {
      // make sure it's unlocked
      final list = await _load(uid);
      if (!list.contains(id)) {
        list.add(id);
        await _save(uid, list);
      }
      await _storage.save(_equippedKey(uid), id);
    } catch (e) {
      debugPrint('TitlesService.setEquippedTitle error: $e');
    }
  }

  Future<String?> getEquippedTitle({String uid = 'local'}) async {
    try {
      final s = _storage.getString(_equippedKey(uid));
      if (s == null || s.trim().isEmpty) return null;
      return s.trim();
    } catch (e) {
      debugPrint('TitlesService.getEquippedTitle error: $e');
      return null;
    }
  }
}
