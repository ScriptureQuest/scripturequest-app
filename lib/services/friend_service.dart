import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:level_up_your_faith/models/friend_model.dart';
import 'package:level_up_your_faith/services/storage_service.dart';

class FriendService {
  final StorageService _storage;

  FriendService(this._storage);

  String _keyForUser(String userId) => 'friends_$userId';

  Future<List<FriendModel>> getFriendsForUser(String userId) async {
    if (userId.trim().isEmpty) return [];
    try {
      final key = _keyForUser(userId);
      final raw = _storage.getString(key);
      if (raw == null || raw.trim().isEmpty) return [];

      final List<dynamic> list = jsonDecode(raw);
      final out = <FriendModel>[];
      for (final item in list) {
        try {
          final fm = FriendModel.fromJson(item as Map<String, dynamic>);
          if (fm != null) out.add(fm);
        } catch (e) {
          debugPrint('FriendService: skipping corrupted friend entry: $e');
        }
      }
      // Sort by createdAt desc
      out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return out;
    } catch (e) {
      debugPrint('FriendService.getFriendsForUser error: $e');
      return [];
    }
  }

  Future<void> saveFriendsForUser(String userId, List<FriendModel> friends) async {
    if (userId.trim().isEmpty) return;
    try {
      final key = _keyForUser(userId);
      final list = friends.map((e) => e.toJson()).toList();
      await _storage.save(key, jsonEncode(list));
    } catch (e) {
      debugPrint('FriendService.saveFriendsForUser error: $e');
    }
  }
}
