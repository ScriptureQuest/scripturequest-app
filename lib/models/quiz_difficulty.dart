enum QuizDifficulty { quick, standard, deep }

extension QuizDifficultyHelpers on QuizDifficulty {
  String get label {
    switch (this) {
      case QuizDifficulty.quick:
        return 'Quick';
      case QuizDifficulty.standard:
        return 'Standard';
      case QuizDifficulty.deep:
        return 'Deep';
    }
  }

  /// Desired total questions for the difficulty.
  /// The quiz may provide fewer; callers should clamp with available length.
  int get desiredQuestionCount {
    switch (this) {
      case QuizDifficulty.quick:
        return 3;
      case QuizDifficulty.standard:
        return 5;
      case QuizDifficulty.deep:
        return 7;
    }
  }

  /// String identifier for analytics/progress events
  String get code {
    switch (this) {
      case QuizDifficulty.quick:
        return 'quick';
      case QuizDifficulty.standard:
        return 'standard';
      case QuizDifficulty.deep:
        return 'deep';
    }
  }

  static QuizDifficulty fromCode(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'quick':
        return QuizDifficulty.quick;
      case 'deep':
        return QuizDifficulty.deep;
      case 'standard':
      default:
        return QuizDifficulty.standard;
    }
  }
}
