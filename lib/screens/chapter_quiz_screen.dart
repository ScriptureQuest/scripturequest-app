import '../theme/scripture_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/models/chapter_quiz.dart';
import 'package:level_up_your_faith/services/chapter_quiz_service.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/providers/settings_provider.dart';
import 'package:level_up_your_faith/models/quiz_difficulty.dart';

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
        _answers = [];
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
        title: Text('Chapter Learning'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: QuestPalette.of(context).accent),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: QuestPalette.of(context).accent))
          : SafeArea(child: _buildBody(theme)),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_quiz == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book, color: QuestPalette.of(context).accent, size: 48),
              SizedBox(height: 12),
              Text('No reflection available for this chapter yet.', style: theme.textTheme.titleMedium),
              SizedBox(height: 6),
              Text('More are coming soon. Keep reading joyfully! ✨', style: theme.textTheme.bodyMedium),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: Text('Back'),
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
        padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _chapterTag(),
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: QuestPalette.of(context).darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: QuestPalette.of(context).accent.withValues(alpha: 0.25), width: 1),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(passed ? 'Well done.' : 'Keep going.', style: theme.textTheme.titleLarge),
                  SizedBox(height: 8),
                  Text('You answered ${result.correct} out of ${result.totalFactual} correctly.', style: theme.textTheme.bodyMedium),
                  SizedBox(height: 8),
                  Text(
                    'Factual answers are checked; private reflections are not graded. Return to Scripture to explore what you noticed.',
                    style: theme.textTheme.bodySmall?.copyWith(color: QuestPalette.of(context).textSecondary),
                  ),
                ],
              ),
            ),
            Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push(Uri(path: '/verses', queryParameters: {'ref': '${widget.bookId} ${widget.chapter}'}).toString()),
                    child: Text('Read the chapter'),
                  ),
                ),
                SizedBox(width: 8),
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
                    child: Text('Try again'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chapterTag(),
          TextButton(onPressed: () => context.push(Uri(path: '/verses', queryParameters: {'ref': '${widget.bookId} ${widget.chapter}'}).toString()), child: Text('Read the passage in context')),
          SizedBox(height: 12),
          _difficultySelector(theme),
          SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: _quiz!.questions.length,
              separatorBuilder: (_, __) => SizedBox(height: 12),
              itemBuilder: (context, index) => _buildQuestionCard(context, index),
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _onFinish,
              icon: Icon(Icons.check, color: QuestPalette.of(context).darkBackground),
              label: Text('Finish'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chapterTag() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: QuestPalette.of(context).accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: QuestPalette.of(context).accent.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        '${_quiz!.bookId.toUpperCase()} • CHAPTER ${_quiz!.chapter}',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: QuestPalette.of(context).accent,
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
        color: QuestPalette.of(context).darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QuestPalette.of(context).accent.withValues(alpha: 0.20), width: 1),
      ),
      padding: EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.help_outline, color: QuestPalette.of(context).accent),
              SizedBox(width: 8),
              Expanded(child: Text(q.prompt, style: theme.textTheme.titleMedium)),
            ],
          ),
          SizedBox(height: 10),
          ...List.generate(q.options.length, (optIdx) {
            final opt = q.options[optIdx];
            final selectedHere = selected == optIdx;
            Color borderColor = QuestPalette.of(context).accent.withValues(alpha: 0.20);
            if (attempted && isFactual && selectedHere) {
              borderColor = isCorrect ? QuestPalette.of(context).success.withValues(alpha: 0.6) : QuestPalette.of(context).textSecondary.withValues(alpha: 0.5);
            } else if (attempted && q.isReflective && selectedHere) {
              borderColor = QuestPalette.of(context).accent.withValues(alpha: 0.5);
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
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1),
                  color: selectedHere ? QuestPalette.of(context).accent.withValues(alpha: 0.08) : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Icon(
                      selectedHere ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: selectedHere ? QuestPalette.of(context).accent : QuestPalette.of(context).textSecondary,
                    ),
                    SizedBox(width: 10),
                    Expanded(child: Text(opt, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
            );
          }),
          SizedBox(height: 6),
          if (attempted && isFactual)
            Row(
              children: [
                Icon(isCorrect ? Icons.check_circle : Icons.info_outline,
                    color: isCorrect ? QuestPalette.of(context).success : QuestPalette.of(context).textSecondary, size: 18),
                SizedBox(width: 6),
                Text(
                  isCorrect
                      ? 'Nice — that’s right.'
                      : 'Good try. Let’s look at the passage again next time.',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isCorrect ? QuestPalette.of(context).success : QuestPalette.of(context).textSecondary,
                  ),
                ),
              ],
            ),
          if (attempted && q.isReflective)
            Row(
              children: [
                Icon(Icons.favorite, color: QuestPalette.of(context).accent, size: 18),
                SizedBox(width: 6),
                Text('Thanks for reflecting on this.', style: theme.textTheme.labelMedium),
              ],
            ),
        ],
      ),
    );
  }

  bool _saving = false;
  void _onFinish() async {
    if (_saving || _finished) return;
    setState(() => _saving = true);
    try {
      final provider = context.read<AppProvider>();
      final result = _computeResult();
      final passed = result.totalFactual == 0 || result.correct / result.totalFactual >= .6;
      final saved = await provider.completeConnectedQuiz(widget.bookId, widget.chapter, passed, result.correct, result.totalFactual, _selectedDifficulty.code);
      if (mounted) {
        setState(() => _finished = true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Quiz saved · ${saved.xp > 0 ? '+${saved.xp} XP' : 'Earlier reward kept'}${saved.changes.isEmpty ? '' : '\n${saved.changes.join('\n')}'}')));
      }
    } catch (_) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save this quiz. Please try again.')));
    } finally { if(mounted) setState(() => _saving = false); }
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
      final base = QuestPalette.of(context).accent;
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
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                color: selected ? QuestPalette.of(context).neonCyan : QuestPalette.of(context).textSecondary,
                size: 16,
              ),
              SizedBox(width: 8),
              Icon(icon, color: QuestPalette.of(context).accent, size: 16),
              SizedBox(width: 6),
              Text('${d.label} • ${count(d)}',
                  style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose your challenge:', style: theme.textTheme.labelLarge?.copyWith(color: QuestPalette.of(context).textSecondary)),
        SizedBox(height: 8),
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
  _QuizResult({required this.totalFactual, required this.correct});
}
