import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:level_up_your_faith/widgets/sacred/sacred_ui.dart';
import 'package:level_up_your_faith/widgets/reward_toast.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/services/bible_service.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/widgets/common/game_end_panel.dart';

class BookOrderGameScreen extends StatefulWidget {
  const BookOrderGameScreen({super.key});

  @override
  State<BookOrderGameScreen> createState() => _BookOrderGameScreenState();
}

class _BookOrderGameScreenState extends State<BookOrderGameScreen> {
  final _rng = Random();

  // Session state
  final List<_BookRound> _rounds = <_BookRound>[];
  int _currentIndex = 0;
  bool _sessionComplete = false;
  bool _xpGranted = false;
  int? _awardedXp; // for end-screen display only

  // UI feedback
  bool _showHint = false;

  // Canonical order map for quick comparisons
  late final Map<String, int> _canonicalIndex; // display name -> index

  @override
  void initState() {
    super.initState();
    _canonicalIndex = _buildCanonicalIndex();
    _startNewSession();
  }

  Map<String, int> _buildCanonicalIndex() {
    final books = BibleService.instance.getAllBooks();
    final map = <String, int>{};
    for (var i = 0; i < books.length; i++) {
      map[books[i]] = i;
    }
    return map;
  }

  void _startNewSession() {
    setState(() {
      _rounds
        ..clear()
        ..addAll(_pickRounds());
      _currentIndex = 0;
      _sessionComplete = false;
      _xpGranted = false;
      _awardedXp = null;
      _showHint = false;
    });
  }

  List<_BookRound> _pickRounds() {
    // Curated small sets (v1.0)
    final pool = <List<String>>[
      // OT samples
      ['Genesis', 'Exodus', 'Leviticus'],
      ['Psalms', 'Proverbs', 'Ecclesiastes'],
      ['Joshua', 'Judges', 'Ruth'],
      // NT samples
      ['Matthew', 'Mark', 'Luke'],
      ['Romans', '1 Corinthians', '2 Corinthians'],
      ['Galatians', 'Ephesians', 'Philippians', 'Colossians'],
    ];
    pool.shuffle(_rng);
    final take = 2; // 1–2 rounds; we opt for 2 for a short session
    return pool.take(take).map((correct) => _BookRound(correctBooks: correct, rng: _rng)).toList();
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (_sessionComplete) return;
    final r = _rounds[_currentIndex];
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = r.currentOrder.removeAt(oldIndex);
      r.currentOrder.insert(newIndex, item);
      _showHint = false;
    });
    // After each reorder, check correctness
    if (_isInCorrectOrder(r)) {
      setState(() {
        r.isCorrect = true;
      });
    } else {
      setState(() {
        r.isCorrect = false;
        _showHint = true;
      });
    }
  }

  bool _isInCorrectOrder(_BookRound r) {
    try {
      // Compare by canonical index positions
      int prev = -1;
      for (final b in r.currentOrder) {
        final idx = _canonicalIndex[b] ?? 9999;
        if (idx < prev) return false;
        prev = idx;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  void _goNext() {
    if (_currentIndex + 1 < _rounds.length) {
      setState(() {
        _currentIndex += 1;
        _showHint = false;
      });
    } else {
      _completeSession();
    }
  }

  Future<void> _completeSession() async {
    if (_sessionComplete) return;
    setState(() {
      _sessionComplete = true;
    });
    if (!_xpGranted && mounted) {
      _xpGranted = true;
      try {
        final app = context.read<AppProvider>();
        const base = 12; // between 10–20 XP
        final awarded = await app.awardMiniGameXp(base);
        _awardedXp = awarded;
        await app.incrementLearningGamesCompleted();
        // One-off achievement for Book Order
        await app.unlockAchievementPublic('book_order_once');
        if (mounted) {
          final subtitle = awarded > 0 ? '+$awarded XP' : null;
          RewardToast.showSuccess(context, title: 'Play & Learn completed!', subtitle: subtitle);
        }
      } catch (e) {
        debugPrint('book-order: award xp error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasRound = !_sessionComplete && _rounds.isNotEmpty && _currentIndex < _rounds.length;
    final r = hasRound ? _rounds[_currentIndex] : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Order Challenge'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader('Drag the books into the right order.', icon: Icons.extension),
              const SizedBox(height: 8),

              if (!_sessionComplete && r != null) ...[
                FadeSlideIn(
                  child: SacredCard(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: cs.primary.withValues(alpha: 0.4), width: 1),
                          ),
                          child: const Icon(Icons.menu_book, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Round ${_currentIndex + 1} of ${_rounds.length}', style: theme.textTheme.titleSmall),
                              const SizedBox(height: 2),
                              Text('Put these books in the correct order', style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Draggable list
                FadeSlideIn(
                  child: SacredCard(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: _DraggableBooks(
                      books: r.currentOrder,
                      onReorder: _onReorder,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_showHint && !(r.isCorrect))
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                      const SizedBox(width: 6),
                      Text('Try adjusting the order.', style: theme.textTheme.labelSmall?.copyWith(color: Colors.amber)),
                    ],
                  ),

                if (r.isCorrect) ...[
                  const SizedBox(height: 12),
                  SacredCard(
                    child: Row(
                      children: [
                        const Icon(Icons.celebration, color: GamerColors.success),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Great job! That order looks right.', style: theme.textTheme.bodyMedium)),
                        ElevatedButton.icon(
                          onPressed: _goNext,
                          icon: const Icon(Icons.arrow_forward, color: GamerColors.darkBackground),
                          label: Text(_currentIndex + 1 < _rounds.length ? 'Next' : 'Finish'),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                GameEndPanel(
                  header: 'Books in Order!',
                  summary: 'You completed the challenge.',
                  xp: _awardedXp,
                  onPlayAgain: _startNewSession,
                  onBackToHub: () => context.go('/community'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DraggableBooks extends StatelessWidget {
  final List<String> books;
  final void Function(int oldIndex, int newIndex) onReorder;
  const _DraggableBooks({required this.books, required this.onReorder});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Fixed height container so ReorderableListView can layout inside Column
    final height = (books.length * 64.0) + 8.0;
    return SizedBox(
      height: height,
      child: ReorderableListView.builder(
        itemCount: books.length,
        onReorder: onReorder,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 4),
        buildDefaultDragHandles: false,
        itemBuilder: (context, index) {
          final b = books[index];
          return Container(
            key: ValueKey('book_$b'),
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.onSurfaceVariant.withValues(alpha: 0.18), width: 1),
            ),
            child: ListTile(
              leading: ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_indicator, color: Colors.white70),
              ),
              title: Text(b, style: theme.textTheme.titleMedium),
              minTileHeight: 52,
            ),
          );
        },
      ),
    );
  }
}

class _BookRound {
  final List<String> correctBooks; // in canonical order
  final Random rng;

  late final List<String> currentOrder;
  bool isCorrect = false;

  _BookRound({required this.correctBooks, required this.rng}) {
    currentOrder = List<String>.from(correctBooks);
    currentOrder.shuffle(rng);
    // Ensure it's actually shuffled; if accidentally equal, reshuffle once
    if (_listsEqual(currentOrder, correctBooks) && currentOrder.length > 1) {
      currentOrder.shuffle(rng);
    }
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
