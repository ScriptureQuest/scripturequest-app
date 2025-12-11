import 'package:flutter/foundation.dart';

/// Lightweight archive entry for a completed in-memory Quest Board quest.
/// We intentionally keep only minimal metadata to avoid bloating storage.
class CompletedBoardQuestEntry {
  final String id;
  final String title;
  final String type; // daily | weekly | reflection | special
  final int xpReward;
  final DateTime completedAt;

  const CompletedBoardQuestEntry({
    required this.id,
    required this.title,
    required this.type,
    required this.xpReward,
    required this.completedAt,
  });

  CompletedBoardQuestEntry copyWith({
    String? id,
    String? title,
    String? type,
    int? xpReward,
    DateTime? completedAt,
  }) {
    return CompletedBoardQuestEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      xpReward: xpReward ?? this.xpReward,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'xpReward': xpReward,
        'completedAt': completedAt.toIso8601String(),
      };

  static CompletedBoardQuestEntry fromJson(Map<String, dynamic> json) {
    try {
      return CompletedBoardQuestEntry(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        type: (json['type'] ?? '').toString(),
        xpReward: int.tryParse('${json['xpReward'] ?? 0}') ?? 0,
        completedAt: DateTime.tryParse((json['completedAt'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
    } catch (e) {
      debugPrint('CompletedBoardQuestEntry.fromJson error: $e');
      return CompletedBoardQuestEntry(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        type: (json['type'] ?? '').toString(),
        xpReward: int.tryParse('${json['xpReward'] ?? 0}') ?? 0,
        completedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
    }
  }
}
