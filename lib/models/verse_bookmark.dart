import 'package:flutter/foundation.dart';

class VerseBookmark {
  final String id;
  final String reference; // e.g., "John 3:16" or "John 3"
  final String book; // Display book name, e.g., "John"
  final int chapter;
  final int? verse; // null = whole chapter bookmark
  final String translationCode; // e.g., "KJV"
  final String? note;
  final DateTime createdAt;

  const VerseBookmark({
    required this.id,
    required this.reference,
    required this.book,
    required this.chapter,
    required this.translationCode,
    required this.createdAt,
    this.verse,
    this.note,
  });

  VerseBookmark copyWith({
    String? id,
    String? reference,
    String? book,
    int? chapter,
    int? verse,
    String? translationCode,
    String? note,
    DateTime? createdAt,
  }) {
    return VerseBookmark(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      book: book ?? this.book,
      chapter: chapter ?? this.chapter,
      verse: verse ?? this.verse,
      translationCode: translationCode ?? this.translationCode,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'book': book,
      'chapter': chapter,
      'verse': verse,
      'translationCode': translationCode,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static VerseBookmark fromJson(Map<String, dynamic> json) {
    try {
      return VerseBookmark(
        id: (json['id'] ?? '') as String,
        reference: (json['reference'] ?? '') as String,
        book: (json['book'] ?? '') as String,
        chapter: (json['chapter'] is int)
            ? json['chapter'] as int
            : int.tryParse('${json['chapter']}') ?? 1,
        verse: json['verse'] == null
            ? null
            : (json['verse'] is int
                ? json['verse'] as int
                : int.tryParse('${json['verse']}')),
        translationCode: (json['translationCode'] ?? 'KJV') as String,
        note: json['note'] == null ? null : (json['note'] as String),
        createdAt: DateTime.tryParse((json['createdAt'] ?? '') as String) ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
    } catch (e) {
      debugPrint('VerseBookmark.fromJson error: $e');
      return VerseBookmark(
        id: '',
        reference: (json['reference'] ?? '') as String,
        book: (json['book'] ?? '') as String,
        chapter: (json['chapter'] is int)
            ? json['chapter'] as int
            : int.tryParse('${json['chapter']}') ?? 1,
        verse: json['verse'] == null
            ? null
            : (json['verse'] is int
                ? json['verse'] as int
                : int.tryParse('${json['verse']}')),
        translationCode: (json['translationCode'] ?? 'KJV') as String,
        note: json['note'] == null ? null : (json['note'] as String),
        createdAt: DateTime.tryParse((json['createdAt'] ?? '') as String) ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
    }
  }
}
