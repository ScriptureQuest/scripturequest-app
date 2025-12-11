import 'package:flutter/foundation.dart';

/// Types of progress events emitted by the app.
enum ProgressEventType {
  chapterCompleted,
  chapterQuizStarted,
  chapterQuizCompleted,
  dailyTaskCompleted,
  nightlyTaskCompleted,
  reflectionTaskCompleted,
  questStepCompleted,
  readingPlanDayCompleted,
  streakDayKept,
  streakBroken,
}

/// Generic progress event with a small flexible payload.
@immutable
class ProgressEvent {
  final ProgressEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> payload;

  ProgressEvent({
    required this.type,
    required this.payload,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // --------- Static constructors for common events ---------

  // Chapter completed
  static ProgressEvent chapterCompleted(
    String bookId,
    String bookName,
    int chapter,
  ) {
    return ProgressEvent(
      type: ProgressEventType.chapterCompleted,
      payload: {
        'bookId': bookId,
        'bookName': bookName,
        'chapter': chapter,
      },
    );
  }

  // Chapter quiz started (no XP by itself; mainly for analytics/stats)
  static ProgressEvent chapterQuizStarted(
    String bookId,
    int chapter,
    String difficulty,
  ) {
    return ProgressEvent(
      type: ProgressEventType.chapterQuizStarted,
      payload: {
        'bookId': bookId,
        'chapter': chapter,
        'difficulty': difficulty,
      },
    );
  }

  // Chapter quiz completed
  static ProgressEvent chapterQuizCompleted(
    String bookId,
    int chapter,
    bool passed,
    int numCorrect,
    int numQuestions,
    String difficulty,
  ) {
    return ProgressEvent(
      type: ProgressEventType.chapterQuizCompleted,
      payload: {
        'bookId': bookId,
        'chapter': chapter,
        'passed': passed,
        'numCorrect': numCorrect,
        'numQuestions': numQuestions,
        'difficulty': difficulty,
      },
    );
  }

  // Generic task completed (Daily, Nightly, Reflection)
  static ProgressEvent taskCompleted(
    String taskId,
    String taskType, // 'daily' | 'nightly' | 'reflection'
  ) {
    return ProgressEvent(
      type: _taskTypeToEvent(taskType),
      payload: {
        'taskId': taskId,
        'taskType': taskType,
      },
    );
  }

  // Questline step completed
  static ProgressEvent questStepCompleted(
    String questlineId,
    int stepIndex,
  ) {
    return ProgressEvent(
      type: ProgressEventType.questStepCompleted,
      payload: {
        'questlineId': questlineId,
        'stepIndex': stepIndex,
      },
    );
  }

  // Reading plan day completed
  static ProgressEvent readingPlanDayCompleted(
    String planId,
    int dayIndex,
  ) {
    return ProgressEvent(
      type: ProgressEventType.readingPlanDayCompleted,
      payload: {
        'planId': planId,
        'dayIndex': dayIndex,
      },
    );
  }

  // Streak events
  static ProgressEvent streakDayKept(int currentStreak) {
    return ProgressEvent(
      type: ProgressEventType.streakDayKept,
      payload: {
        'currentStreak': currentStreak,
      },
    );
  }

  static ProgressEvent streakBroken({int? previousStreak}) {
    return ProgressEvent(
      type: ProgressEventType.streakBroken,
      payload: {
        if (previousStreak != null) 'previousStreak': previousStreak,
      },
    );
  }

  // Helper: map task type to specific event type for convenience constructor
  static ProgressEventType _taskTypeToEvent(String taskType) {
    switch (taskType.toLowerCase()) {
      case 'daily':
        return ProgressEventType.dailyTaskCompleted;
      case 'nightly':
        return ProgressEventType.nightlyTaskCompleted;
      case 'reflection':
        return ProgressEventType.reflectionTaskCompleted;
      default:
        return ProgressEventType.dailyTaskCompleted;
    }
  }
}
