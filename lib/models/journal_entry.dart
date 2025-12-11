import 'package:flutter/foundation.dart';

class JournalEntry {
  final String id;
  final String userId;
  final String? questId;
  final String? questTitle;
  final String? scriptureReference;
  final String reflectionText; // Acts as body
  final String? title; // v2.0 optional title
  final List<String> tags; // v2.0 optional tags
  final bool isPinned; // v2.0 Phase 2: pinned entries
  final String? spiritualFocus; // e.g., Faith, Hope, Encouragement
  final String? questType; // scripture_reading, prayer, reflection, service, community
  // v1.0 Verse link metadata (optional)
  final String? linkedRef; // e.g., "John 3:16" or "Psalm 23"
  final String? linkedRefRoute; // e.g., "/verses?ref=John%203%3A16"
  final DateTime createdAt;
  final DateTime? updatedAt;

  const JournalEntry({
    required this.id,
    required this.userId,
    this.questId,
    this.questTitle,
    this.scriptureReference,
    required this.reflectionText,
    this.title,
    this.tags = const <String>[],
    this.isPinned = false,
    this.spiritualFocus,
    this.questType,
    this.linkedRef,
    this.linkedRefRoute,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'questId': questId,
        'questTitle': questTitle,
        'scriptureReference': scriptureReference,
        'reflectionText': reflectionText,
        'title': title,
        'tags': tags,
        'isPinned': isPinned,
        'spiritualFocus': spiritualFocus,
        'questType': questType,
        'linkedRef': linkedRef,
        'linkedRefRoute': linkedRefRoute,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    try {
      // Defensive parse for tags
      List<String> _parseTags(dynamic raw) {
        try {
          if (raw == null) return const <String>[];
          if (raw is List) {
            return raw.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
          }
          // Support comma-separated legacy strings if ever present
          final s = raw.toString();
          if (s.trim().isEmpty) return const <String>[];
          return s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        } catch (_) {
          return const <String>[];
        }
      }
      bool _parsePinned(dynamic raw) {
        try {
          if (raw == null) return false;
          if (raw is bool) return raw;
          final s = raw.toString().trim().toLowerCase();
          if (s == 'true' || s == '1' || s == 'yes') return true;
          return false;
        } catch (_) {
          return false;
        }
      }
      return JournalEntry(
        id: (json['id'] ?? '').toString(),
        userId: (json['userId'] ?? '').toString(),
        questId: (json['questId'])?.toString(),
        questTitle: (json['questTitle'])?.toString(),
        scriptureReference: (json['scriptureReference'])?.toString(),
        reflectionText: (json['reflectionText'] ?? '').toString(),
        title: (json['title'])?.toString().trim().isEmpty == true ? null : json['title']?.toString(),
        tags: _parseTags(json['tags']),
        isPinned: _parsePinned(json['isPinned']),
        spiritualFocus: (json['spiritualFocus'])?.toString(),
        questType: (json['questType'])?.toString(),
        linkedRef: (json['linkedRef'])?.toString(),
        linkedRefRoute: (json['linkedRefRoute'])?.toString(),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'].toString())
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'].toString())
            : null,
      );
    } catch (e) {
      debugPrint('Error parsing JournalEntry: $e');
      // Safe fallback to avoid crashes
      return JournalEntry(
        id: (json['id'] ?? '').toString(),
        userId: (json['userId'] ?? '').toString(),
        questId: (json['questId'])?.toString(),
        questTitle: (json['questTitle'])?.toString(),
        scriptureReference: (json['scriptureReference'])?.toString(),
        reflectionText: (json['reflectionText'] ?? '').toString(),
        title: (json['title'])?.toString(),
        tags: const <String>[],
        isPinned: false,
        spiritualFocus: (json['spiritualFocus'])?.toString(),
        questType: (json['questType'])?.toString(),
        linkedRef: (json['linkedRef'])?.toString(),
        linkedRefRoute: (json['linkedRefRoute'])?.toString(),
        createdAt: DateTime.now(),
        updatedAt: null,
      );
    }
  }

  JournalEntry copyWith({
    String? id,
    String? userId,
    String? questId,
    String? questTitle,
    String? scriptureReference,
    String? reflectionText,
    String? title,
    List<String>? tags,
    bool? isPinned,
    String? spiritualFocus,
    String? questType,
    String? linkedRef,
    String? linkedRefRoute,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      questId: questId ?? this.questId,
      questTitle: questTitle ?? this.questTitle,
      scriptureReference: scriptureReference ?? this.scriptureReference,
      reflectionText: reflectionText ?? this.reflectionText,
      title: title ?? this.title,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      spiritualFocus: spiritualFocus ?? this.spiritualFocus,
      questType: questType ?? this.questType,
      linkedRef: linkedRef ?? this.linkedRef,
      linkedRefRoute: linkedRefRoute ?? this.linkedRefRoute,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
