import 'package:flutter/foundation.dart';

class ChapterQuiz {
  final String id;
  final String bookId; // Display book name (e.g., 'John')
  final int chapter;
  final List<ChapterQuizQuestion> questions;

  const ChapterQuiz({
    required this.id,
    required this.bookId,
    required this.chapter,
    required this.questions,
  });

  ChapterQuiz copyWith({
    String? id,
    String? bookId,
    int? chapter,
    List<ChapterQuizQuestion>? questions,
  }) {
    return ChapterQuiz(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapter: chapter ?? this.chapter,
      questions: questions ?? this.questions,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'chapter': chapter,
        'questions': questions.map((q) => q.toJson()).toList(),
      };

  factory ChapterQuiz.fromJson(Map<String, dynamic> json) {
    try {
      final questionsRaw = json['questions'];
      final List<ChapterQuizQuestion> qs;
      if (questionsRaw is List) {
        qs = questionsRaw.map((e) {
          if (e is Map<String, dynamic>) return ChapterQuizQuestion.fromJson(e);
          if (e is Map) return ChapterQuizQuestion.fromJson(e.cast<String, dynamic>());
          return null;
        }).whereType<ChapterQuizQuestion>().toList();
      } else {
        qs = const <ChapterQuizQuestion>[];
      }
      return ChapterQuiz(
        id: (json['id'] ?? '').toString(),
        bookId: (json['bookId'] ?? '').toString(),
        chapter: int.tryParse('${json['chapter']}') ?? 1,
        questions: qs,
      );
    } catch (e) {
      debugPrint('ChapterQuiz.fromJson error: $e');
      return ChapterQuiz(id: '', bookId: '', chapter: 1, questions: const []);
    }
  }
}

class ChapterQuizQuestion {
  final String id;
  final String prompt;
  final List<String> options;
  final int? correctOptionIndex; // null for reflective
  final bool isReflective;

  const ChapterQuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    this.correctOptionIndex,
    this.isReflective = false,
  });

  ChapterQuizQuestion copyWith({
    String? id,
    String? prompt,
    List<String>? options,
    int? correctOptionIndex,
    bool? isReflective,
  }) {
    return ChapterQuizQuestion(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      options: options ?? this.options,
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
      isReflective: isReflective ?? this.isReflective,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'prompt': prompt,
        'options': options,
        'correctOptionIndex': correctOptionIndex,
        'isReflective': isReflective,
      };

  factory ChapterQuizQuestion.fromJson(Map<String, dynamic> json) {
    try {
      final optsRaw = json['options'];
      final List<String> opts = optsRaw is List
          ? optsRaw.map((e) => e.toString()).toList()
          : const <String>[];
      final hasReflective = json.containsKey('isReflective');
      final isReflective = hasReflective
          ? (json['isReflective'] == true)
          : (json['correctOptionIndex'] == null);
      return ChapterQuizQuestion(
        id: (json['id'] ?? '').toString(),
        prompt: (json['prompt'] ?? '').toString(),
        options: opts,
        correctOptionIndex: json['correctOptionIndex'] == null
            ? null
            : int.tryParse('${json['correctOptionIndex']}'),
        isReflective: isReflective,
      );
    } catch (e) {
      debugPrint('ChapterQuizQuestion.fromJson error: $e');
      return const ChapterQuizQuestion(id: '', prompt: '', options: <String>[]);
    }
  }
}
