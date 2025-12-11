import 'package:flutter/foundation.dart';

class FriendModel {
  final String id; // player id (same as LeaderboardPlayer.id)
  final String displayName; // snapshot of their name when added
  final String? tagline; // optional
  final DateTime createdAt;

  const FriendModel({
    required this.id,
    required this.displayName,
    this.tagline,
    required this.createdAt,
  });

  FriendModel copyWith({
    String? id,
    String? displayName,
    String? tagline,
    DateTime? createdAt,
  }) {
    return FriendModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      tagline: tagline ?? this.tagline,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'tagline': tagline,
        'createdAt': createdAt.toIso8601String(),
      };

  static FriendModel? fromJson(Map<String, dynamic>? json) {
    try {
      if (json == null) return null;
      final rawId = json['id'];
      final rawName = json['displayName'];
      if (rawId == null || rawName == null) return null;
      final id = rawId.toString().trim();
      final name = rawName.toString().trim();
      if (id.isEmpty || name.isEmpty) return null;

      // createdAt parsing with fallback to now()
      DateTime created;
      final rawCreated = json['createdAt'];
      if (rawCreated is String && rawCreated.trim().isNotEmpty) {
        created = DateTime.tryParse(rawCreated.trim()) ?? DateTime.now();
      } else {
        created = DateTime.now();
      }

      final tagline = (json['tagline'] == null)
          ? null
          : json['tagline'].toString();

      return FriendModel(
        id: id,
        displayName: name,
        tagline: (tagline != null && tagline.trim().isNotEmpty) ? tagline : null,
        createdAt: created,
      );
    } catch (e) {
      debugPrint('FriendModel.fromJson skipped corrupted entry: $e');
      return null;
    }
  }
}
