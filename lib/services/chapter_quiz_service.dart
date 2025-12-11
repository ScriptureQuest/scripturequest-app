import 'package:level_up_your_faith/models/chapter_quiz.dart';

/// Static seed quizzes v1.0 for a few high-impact chapters.
class ChapterQuizService {
  static final List<ChapterQuiz> _quizzes = <ChapterQuiz>[
    // John 3
    ChapterQuiz(
      id: 'john_3',
      bookId: 'John',
      chapter: 3,
      questions: const [
        ChapterQuizQuestion(
          id: 'j3_q1',
          prompt: 'Who came to Jesus by night in John 3?',
          options: ['Nicodemus', 'Peter', 'John', 'A Pharisee (unnamed)'],
          correctOptionIndex: 0,
        ),
        ChapterQuizQuestion(
          id: 'j3_q2',
          prompt: 'What central theme is emphasized in John 3?',
          options: ['Being born again', 'Fasting and prayer', 'Temple worship', 'Sabbath rules'],
          correctOptionIndex: 0,
        ),
        ChapterQuizQuestion(
          id: 'j3_q3',
          prompt: 'Which truth from John 3 most encouraged you today?',
          options: [
            'God so loved the world',
            'The Spirit gives new birth',
            'Jesus brings light to darkness',
            'Believing brings life',
          ],
          correctOptionIndex: null,
          isReflective: true,
        ),
      ],
    ),

    // Romans 8
    ChapterQuiz(
      id: 'romans_8',
      bookId: 'Romans',
      chapter: 8,
      questions: const [
        ChapterQuizQuestion(
          id: 'r8_q1',
          prompt: 'Finish the phrase: There is therefore now no _____.',
          options: ['condemnation', 'fear', 'law', 'accusation'],
          correctOptionIndex: 0,
        ),
        ChapterQuizQuestion(
          id: 'r8_q2',
          prompt: 'What is a key message of Romans 8?',
          options: [
            'Life in the Spirit and assurance in God’s love',
            'Importance of circumcision',
            'Food laws and holy days',
            'Jerusalem temple rituals',
          ],
          correctOptionIndex: 0,
        ),
        ChapterQuizQuestion(
          id: 'r8_q3',
          prompt: 'Which assurance in Romans 8 comforted you most?',
          options: [
            'Nothing separates us from God’s love',
            'The Spirit helps in our weakness',
            'We are more than conquerors',
            'All things work together for good',
          ],
          correctOptionIndex: null,
          isReflective: true,
        ),
      ],
    ),

    // Psalm 23
    ChapterQuiz(
      id: 'psalm_23',
      bookId: 'Psalms',
      chapter: 23,
      questions: const [
        ChapterQuizQuestion(
          id: 'p23_q1',
          prompt: 'The LORD is my _____; I shall not want.',
          options: ['shepherd', 'shield', 'fortress', 'rock'],
          correctOptionIndex: 0,
        ),
        ChapterQuizQuestion(
          id: 'p23_q2',
          prompt: 'What is the main theme of Psalm 23?',
          options: ['God’s shepherding care', 'Judgment on enemies', 'Creation’s wonder', 'The law’s perfection'],
          correctOptionIndex: 0,
        ),
        ChapterQuizQuestion(
          id: 'p23_q3',
          prompt: 'Which line rests your soul today?',
          options: [
            'He restoreth my soul',
            'Thou art with me',
            'Goodness and mercy shall follow me',
            'I shall dwell in the house of the LORD',
          ],
          correctOptionIndex: null,
          isReflective: true,
        ),
      ],
    ),

    // Proverbs 3
    ChapterQuiz(
      id: 'proverbs_3',
      bookId: 'Proverbs',
      chapter: 3,
      questions: const [
        ChapterQuizQuestion(
          id: 'pr3_q1',
          prompt: 'Trust in the LORD with all thine _____.',
          options: ['heart', 'mind', 'strength', 'soul'],
          correctOptionIndex: 0,
        ),
        ChapterQuizQuestion(
          id: 'pr3_q2',
          prompt: 'What theme guides Proverbs 3?',
          options: [
            'Wisdom, trust, and God-directed paths',
            'Kings and kingdoms',
            'Priestly sacrifices',
            'Prophetic visions',
          ],
          correctOptionIndex: 0,
        ),
        ChapterQuizQuestion(
          id: 'pr3_q3',
          prompt: 'Which counsel do you want to lean into?',
          options: [
            'Acknowledge Him in all thy ways',
            'Despise not the chastening of the LORD',
            'Keep mercy and truth',
            'Honor the LORD with thy substance',
          ],
          correctOptionIndex: null,
          isReflective: true,
        ),
      ],
    ),

    // Luke 2
    ChapterQuiz(
      id: 'luke_2',
      bookId: 'Luke',
      chapter: 2,
      questions: const [
        ChapterQuizQuestion(
          id: 'lk2_q1',
          prompt: 'Where was Jesus born according to Luke 2?',
          options: ['Bethlehem', 'Nazareth', 'Jerusalem', 'Capernaum'],
          correctOptionIndex: 0,
        ),
        ChapterQuizQuestion(
          id: 'lk2_q2',
          prompt: 'Which theme stands out in Luke 2?',
          options: [
            'God’s humble entrance and faithful promises',
            'The Exodus narrative',
            'Temple sacrifices and incense',
            'Exile and return',
          ],
          correctOptionIndex: 0,
        ),
        ChapterQuizQuestion(
          id: 'lk2_q3',
          prompt: 'Which moment touched your heart most?',
          options: [
            'Angels’ song of peace',
            'Mary’s pondering',
            'Simeon’s blessing',
            'The shepherds’ witness',
          ],
          correctOptionIndex: null,
          isReflective: true,
        ),
      ],
    ),
  ];

  static ChapterQuiz? getQuizForChapter(String bookId, int chapter) {
    final key = bookId.trim().toLowerCase();
    try {
      return _quizzes.firstWhere(
        (q) => q.bookId.toLowerCase() == key && q.chapter == chapter,
        orElse: () => const ChapterQuiz(id: '', bookId: '', chapter: 0, questions: <ChapterQuizQuestion>[]),
      ).id.isEmpty
          ? null
          : _quizzes.firstWhere((q) => q.bookId.toLowerCase() == key && q.chapter == chapter);
    } catch (_) {
      return null;
    }
  }

  static List<ChapterQuiz> getAllQuizzes() => List<ChapterQuiz>.from(_quizzes);
}
