import 'package:flutter/foundation.dart';

class BookMastery {
  final String bookId; // Display book name, e.g., "Genesis"
  final int chaptersRead;
  final int totalChapters;
  final int timesCompleted;
  final int artifactsOwned;
  final int questsCompleted;
  // Tier keys: none, lamp, olive, dove, scroll, crown
  final String masteryTier;

  const BookMastery({
    required this.bookId,
    required this.chaptersRead,
    required this.totalChapters,
    required this.timesCompleted,
    required this.artifactsOwned,
    required this.questsCompleted,
    required this.masteryTier,
  });

  double get completionPercent {
    if (totalChapters <= 0) return 0;
    final pct = chaptersRead / totalChapters;
    if (pct.isNaN || pct.isInfinite) return 0;
    return pct.clamp(0, 1);
  }

  BookMastery copyWith({
    String? bookId,
    int? chaptersRead,
    int? totalChapters,
    int? timesCompleted,
    int? artifactsOwned,
    int? questsCompleted,
    String? masteryTier,
  }) {
    return BookMastery(
      bookId: bookId ?? this.bookId,
      chaptersRead: chaptersRead ?? this.chaptersRead,
      totalChapters: totalChapters ?? this.totalChapters,
      timesCompleted: timesCompleted ?? this.timesCompleted,
      artifactsOwned: artifactsOwned ?? this.artifactsOwned,
      questsCompleted: questsCompleted ?? this.questsCompleted,
      masteryTier: masteryTier ?? this.masteryTier,
    );
  }

  Map<String, dynamic> toJson() => {
        'bookId': bookId,
        'chaptersRead': chaptersRead,
        'totalChapters': totalChapters,
        'timesCompleted': timesCompleted,
        'artifactsOwned': artifactsOwned,
        'questsCompleted': questsCompleted,
        'masteryTier': masteryTier,
      };

  factory BookMastery.fromJson(Map<String, dynamic> json) {
    try {
      return BookMastery(
        bookId: (json['bookId'] ?? '').toString(),
        chaptersRead: json['chaptersRead'] is int
            ? json['chaptersRead'] as int
            : int.tryParse('${json['chaptersRead'] ?? 0}') ?? 0,
        totalChapters: json['totalChapters'] is int
            ? json['totalChapters'] as int
            : int.tryParse('${json['totalChapters'] ?? 0}') ?? 0,
        timesCompleted: json['timesCompleted'] is int
            ? json['timesCompleted'] as int
            : int.tryParse('${json['timesCompleted'] ?? 0}') ?? 0,
        artifactsOwned: json['artifactsOwned'] is int
            ? json['artifactsOwned'] as int
            : int.tryParse('${json['artifactsOwned'] ?? 0}') ?? 0,
        questsCompleted: json['questsCompleted'] is int
            ? json['questsCompleted'] as int
            : int.tryParse('${json['questsCompleted'] ?? 0}') ?? 0,
        masteryTier: (json['masteryTier'] ?? 'none').toString(),
      );
    } catch (e) {
      debugPrint('BookMastery.fromJson error: $e');
      return BookMastery(
        bookId: (json['bookId'] ?? '').toString(),
        chaptersRead: 0,
        totalChapters: 0,
        timesCompleted: 0,
        artifactsOwned: 0,
        questsCompleted: 0,
        masteryTier: 'none',
      );
    }
  }
}
