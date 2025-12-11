import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/models/chapter_quiz.dart';
import 'package:level_up_your_faith/services/chapter_quiz_service.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/providers/settings_provider.dart';
import 'package:level_up_your_faith/models/quiz_difficulty.dart';
import 'package:level_up_your_faith/services/progress/progress_engine.dart';
import 'package:level_up_your_faith/services/progress/progress_event.dart';

class ChapterQuizScreen extends StatefulWidget {
  final String bookId; // display name
  final int chapter;
  const ChapterQuizScreen({super.key, required this.bookId, required this.chapter});

  @override
  State<ChapterQuizScreen> createState() => _ChapterQuizScreenState();
}

class _ChapterQuizScreenState extends State<ChapterQuizScreen> {
  ChapterQuiz? _quiz;
  bool _loading = true;
  bool _finished = false;
  late List<int?> _answers; // per question, selected index
  QuizDifficulty _selectedDifficulty = QuizDifficulty.standard;
  bool _difficultyLocked = false; // lock after first answer

  @override
  void initState() {
    super.initState();
    // Initialize difficulty from settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pref = context.read<SettingsProvider>().preferredQuizDifficulty;
      setState(() => _selectedDifficulty = pref);
      _load();
    });
  }

  void _load() {
    try {
      final q = ChapterQuizService.getQuizForChapter(widget.bookId, widget.chapter);
      final trimmed = _trimToDifficulty(q);
      setState(() {
        _quiz = trimmed;
        _answers = List<int?>.filled(trimmed?.questions.length ?? 0, null);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _quiz = null;
        _answers = const [];
        _loading = false;
      });
    }
  }

  ChapterQuiz? _trimToDifficulty(ChapterQuiz? q) {
    if (q == null) return null;
    final desired = _selectedDifficulty.desiredQuestionCount;
    final take = q.questions.length < desired ? q.questions.length : desired;
    return q.copyWith(questions: q.questions.take(take).toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chapter Reflection'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GamerColors.accent),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: GamerColors.accent))
          : SafeArea(child: _buildBody(theme)),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_quiz == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.menu_book, color: GamerColors.accent, size: 48),
              const SizedBox(height: 12),
              Text('No reflection available for this chapter yet.', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text('More are coming soon. Keep reading joyfully! ✨', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (_finished) {
      final result = _computeResult();
      final passed = result.totalFactual == 0 ? true : (result.correct / result.totalFactual) >= 0.6;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _chapterTag(),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: GamerColors.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: GamerColors.accent.withValues(alpha: 0.25), width: 1),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(passed ? 'Well done.' : 'Keep going.', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('You answered ${result.correct} out of ${result.totalFactual} correctly.', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(
                    passed
                        ? 'You’re hiding this chapter in your heart.'
                        : 'Every time you try, you remember a little more.',
                    style: theme.textTheme.bodySmall?.copyWith(color: GamerColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Back to chapter'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _finished = false;
                        _difficultyLocked = false;
                        // Reload the quiz with the same difficulty
                        _load();
                      });
                    },
                    child: const Text('Try again'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chapterTag(),
          const SizedBox(height: 12),
          _difficultySelector(theme),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: _quiz!.questions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildQuestionCard(context, index),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _onFinish,
              icon: const Icon(Icons.check, color: GamerColors.darkBackground),
              label: const Text('Finish'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chapterTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: GamerColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GamerColors.accent.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        '${_quiz!.bookId.toUpperCase()} • CHAPTER ${_quiz!.chapter}',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: GamerColors.accent,
              letterSpacing: 1.2,
            ),
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, int index) {
    final theme = Theme.of(context);
    final q = _quiz!.questions[index];
    final selected = _answers[index];
    final isFactual = !q.isReflective && q.correctOptionIndex != null;
    final isCorrect = isFactual && selected != null && selected == q.correctOptionIndex;
    final attempted = selected != null;
    return Container(
      decoration: BoxDecoration(
        color: GamerColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GamerColors.accent.withValues(alpha: 0.20), width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.help_outline, color: GamerColors.accent),
              const SizedBox(width: 8),
              Expanded(child: Text(q.prompt, style: theme.textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(q.options.length, (optIdx) {
            final opt = q.options[optIdx];
            final selectedHere = selected == optIdx;
            Color borderColor = GamerColors.accent.withValues(alpha: 0.20);
            if (attempted && isFactual && selectedHere) {
              borderColor = isCorrect ? GamerColors.success.withValues(alpha: 0.6) : GamerColors.textSecondary.withValues(alpha: 0.5);
            } else if (attempted && q.isReflective && selectedHere) {
              borderColor = GamerColors.accent.withValues(alpha: 0.5);
            }
            return InkWell(
              onTap: () {
                setState(() {
                  _answers[index] = optIdx;
                  if (!_difficultyLocked) {
                    _difficultyLocked = true;
                  }
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1),
                  color: selectedHere ? GamerColors.accent.withValues(alpha: 0.08) : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Icon(
                      selectedHere ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: selectedHere ? GamerColors.accent : GamerColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(opt, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
          if (attempted && isFactual)
            Row(
              children: [
                Icon(isCorrect ? Icons.check_circle : Icons.info_outline,
                    color: isCorrect ? GamerColors.success : GamerColors.textSecondary, size: 18),
                const SizedBox(width: 6),
                Text(
                  isCorrect
                      ? 'Nice — that’s right.'
                      : 'Good try. Let’s look at the passage again next time.',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isCorrect ? GamerColors.success : GamerColors.textSecondary,
                  ),
                ),
              ],
            ),
          if (attempted && q.isReflective)
            Row(
              children: [
                const Icon(Icons.favorite, color: GamerColors.accent, size: 18),
                const SizedBox(width: 6),
                Text('Thanks for reflecting on this.', style: theme.textTheme.labelMedium),
              ],
            ),
        ],
      ),
    );
  }

  void _onFinish() async {
    try {
      // Award only on first completion
      final provider = context.read<AppProvider>();
      final result = _computeResult();
      final total = result.totalFactual;
      final correct = result.correct;
      final passed = total == 0 ? true : (correct / total) >= 0.6;
      if (!provider.hasCompletedQuiz(widget.bookId, widget.chapter)) {
        // Defer XP to ProgressEngine
        await provider.markQuizCompleted(widget.bookId, widget.chapter, awardXp: false);
      }
      // Notify quest system (daily tasks etc.) that a quiz was completed
      try {
        await provider.checkActiveQuests(event: 'onQuizCompleted', payload: {
          'book': widget.bookId,
          'chapter': widget.chapter,
          'passed': passed,
        });
      } catch (_) {}
      // Emit unified progress event (XP, stats, achievements)
      try {
        final bookRef = provider.bibleService.displayToRef(widget.bookId);
        await ProgressEngine.instance.emit(
          ProgressEvent.chapterQuizCompleted(
            bookRef,
            widget.chapter,
            passed,
            correct,
            total,
            _selectedDifficulty.code,
          ),
        );
      } catch (_) {}
      setState(() => _finished = true);
    } catch (e) {
      // Gracefully continue
    }
  }

  _QuizResult _computeResult() {
    int factual = 0;
    int correct = 0;
    for (var i = 0; i < _quiz!.questions.length; i++) {
      final q = _quiz!.questions[i];
      if (!q.isReflective && q.correctOptionIndex != null) {
        factual++;
        if (_answers[i] != null && _answers[i] == q.correctOptionIndex) correct++;
      }
    }
    return _QuizResult(totalFactual: factual, correct: correct);
  }

  Widget _difficultySelector(ThemeData theme) {
    final locked = _difficultyLocked;
    String count(QuizDifficulty d) => '${d.desiredQuestionCount} questions';
    Widget chip(QuizDifficulty d, {required IconData icon}) {
      final selected = _selectedDifficulty == d;
      final base = GamerColors.accent;
      final bg = selected ? base.withValues(alpha: 0.20) : base.withValues(alpha: 0.10);
      final border = selected ? base.withValues(alpha: 0.65) : base.withValues(alpha: 0.35);
      return InkWell(
        onTap: locked
            ? null
            : () async {
                if (_selectedDifficulty == d) return;
                setState(() {
                  _selectedDifficulty = d;
                  // Regenerate questions only if user hasn't answered yet
                  _quiz = _trimToDifficulty(ChapterQuizService.getQuizForChapter(widget.bookId, widget.chapter));
                  _answers = List<int?>.filled(_quiz?.questions.length ?? 0, null);
                });
                // Persist preference immediately
                await context.read<SettingsProvider>().setPreferredQuizDifficulty(d);
              },
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected ? GamerColors.neonCyan : GamerColors.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Icon(icon, color: GamerColors.accent, size: 16),
              const SizedBox(width: 6),
              Text('${d.label} • ${count(d)}',
                  style: theme.textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose your challenge:', style: theme.textTheme.labelLarge?.copyWith(color: GamerColors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            chip(QuizDifficulty.quick, icon: Icons.bolt),
            chip(QuizDifficulty.standard, icon: Icons.terrain),
            chip(QuizDifficulty.deep, icon: Icons.local_florist),
          ],
        ),
      ],
    );
  }

}

class _QuizResult {
  final int totalFactual;
  final int correct;
  const _QuizResult({required this.totalFactual, required this.correct});
}
