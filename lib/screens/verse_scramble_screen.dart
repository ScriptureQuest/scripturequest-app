import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/widgets/reward_toast.dart';
import 'package:level_up_your_faith/widgets/sacred/sacred_ui.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/widgets/common/game_end_panel.dart';

class VerseScrambleScreen extends StatefulWidget {
  const VerseScrambleScreen({super.key});

  @override
  State<VerseScrambleScreen> createState() => _VerseScrambleScreenState();
}

class _VerseScrambleScreenState extends State<VerseScrambleScreen> {
  final _rng = Random();
  bool _loading = true;
  bool _sessionComplete = false;
  bool _xpGranted = false;
  int? _awardedXp; // display in end screen only

  // Rounds
  final List<_Round> _rounds = <_Round>[];
  int _currentIndex = 0;

  // UI feedback
  bool _wrongChoice = false;

  @override
  void initState() {
    super.initState();
    _startNewSession();
  }

  Future<void> _startNewSession() async {
    setState(() {
      _loading = true;
      _sessionComplete = false;
      _xpGranted = false;
      _awardedXp = null;
      _currentIndex = 0;
      _rounds.clear();
      _wrongChoice = false;
    });

    try {
      final pool = await _loadVersePool();
      pool.shuffle(_rng);
      // Pick 2–3 rounds, gentle
      final count = pool.length >= 3 ? 3 : (pool.length >= 2 ? 2 : 1);
      final selected = pool.take(count).toList();
      setState(() {
        _rounds.addAll(selected);
        _loading = false;
      });
    } catch (e) {
      debugPrint('verse-scramble: load error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _rounds.add(
          _Round(
            reference: 'John 3:16',
            text: 'For God so loved the world that he gave his one and only Son.',
            missing: ['loved', 'world', 'Son'],
            distractors: const ['king', 'earth', 'walked'],
          ),
        );
      });
    }
  }

  Future<List<_Round>> _loadVersePool() async {
    final jsonStr = await rootBundle.loadString('assets/verses/scramble_verses.json');
    final List<dynamic> data = jsonDecode(jsonStr) as List<dynamic>;
    final out = <_Round>[];
    for (final e in data) {
      try {
        if (e is Map) {
          final ref = (e['reference'] ?? '').toString().trim();
          final text = (e['text'] ?? '').toString().trim();
          final missingRaw = e['missing'];
          final distractRaw = e['distractors'];
          final missing = <String>[];
          final distractors = <String>[];
          if (missingRaw is List) {
            for (final m in missingRaw) {
              final s = (m ?? '').toString().trim();
              if (s.isNotEmpty) missing.add(s);
            }
          }
          if (distractRaw is List) {
            for (final d in distractRaw) {
              final s = (d ?? '').toString().trim();
              if (s.isNotEmpty) distractors.add(s);
            }
          }
          if (ref.isNotEmpty && text.isNotEmpty && missing.isNotEmpty) {
            out.add(_Round(reference: ref, text: text, missing: missing, distractors: distractors));
          }
        }
      } catch (err) {
        debugPrint('verse-scramble: skip malformed entry: $err');
      }
    }
    if (out.isEmpty) {
      return [
        _Round(
          reference: 'Psalm 23:1',
          text: 'The Lord is my shepherd; I shall not want.',
          missing: ['shepherd', 'want'],
          distractors: const ['desire', 'teacher', 'kingdom'],
        ),
      ];
    }
    return out;
  }

  void _onChoiceTap(String choice) {
    if (_sessionComplete || _loading) return;
    final r = _rounds[_currentIndex];
    final nextBlankIndex = r.firstUnfilledIndex;
    if (nextBlankIndex == null) return; // already complete

    final expected = r.missing[nextBlankIndex];
    if (_equalsWord(choice, expected)) {
      setState(() {
        _wrongChoice = false;
        r.fill(nextBlankIndex, choice);
      });
      if (r.isComplete) {
        // Small delay to let UI show filled state
        Future.delayed(const Duration(milliseconds: 250), () {
          if (!mounted) return;
          setState(() {});
        });
      }
    } else {
      setState(() {
        _wrongChoice = true;
      });
    }
  }

  bool _equalsWord(String a, String b) {
    return a.trim().toLowerCase() == b.trim().toLowerCase();
  }

  void _goNext() {
    if (_currentIndex + 1 < _rounds.length) {
      setState(() {
        _currentIndex += 1;
        _wrongChoice = false;
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
        const base = 14; // between 10–20, gentle
        final awarded = await app.awardMiniGameXp(base);
        _awardedXp = awarded;
        await app.incrementLearningGamesCompleted();
        if (mounted) {
          final subtitle = awarded > 0 ? '+$awarded XP' : null;
          RewardToast.showSuccess(context, title: 'Play & Learn completed!', subtitle: subtitle);
        }
      } catch (e) {
        debugPrint('verse-scramble: award xp error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final r = (!_loading && _rounds.isNotEmpty) ? _rounds[_currentIndex] : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verse Scramble'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader('Tap the right words to fix the verse.', icon: Icons.extension),
                    const SizedBox(height: 8),
                    if (!_sessionComplete && r != null) ...[
                      _RoundCard(round: r, wrongChoice: _wrongChoice),
                      const SizedBox(height: 12),
                      _ChoicesGrid(
                        options: r.choices,
                        onTap: _onChoiceTap,
                      ),
                      if (r.isComplete) ...[
                        const SizedBox(height: 12),
                        SacredCard(
                          child: Row(
                            children: [
                              const Icon(Icons.celebration, color: GamerColors.success),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text('Great job! This verse looks right.', style: theme.textTheme.bodyMedium),
                              ),
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
                        header: 'Scramble Solved!',
                        summary: "You completed the challenge.",
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

class _RoundCard extends StatelessWidget {
  final _Round round;
  final bool wrongChoice;
  const _RoundCard({required this.round, required this.wrongChoice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final parts = round.renderParts();
    return FadeSlideIn(
      child: SacredCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(round.reference, style: theme.textTheme.titleMedium?.copyWith(color: cs.primary)),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.start,
              runSpacing: 8,
              children: [
                for (final p in parts)
                  p.isBlank
                      ? _BlankChip(label: round.isComplete ? p.answer ?? '____' : '____')
                      : Text(p.text!, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.45)),
              ],
            ),
            const SizedBox(height: 8),
            if (wrongChoice)
              Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                  const SizedBox(width: 6),
                  Text('Try again', style: theme.textTheme.labelSmall?.copyWith(color: Colors.amber)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _BlankChip extends StatelessWidget {
  final String label;
  const _BlankChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.onSurfaceVariant.withValues(alpha: 0.15), width: 1),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _ChoicesGrid extends StatelessWidget {
  final List<String> options;
  final void Function(String choice) onTap;
  const _ChoicesGrid({required this.options, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          InkWell(
            onTap: () => onTap(o),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: cs.onSurfaceVariant.withValues(alpha: 0.2), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.touch_app_rounded, size: 16, color: GamerColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(o, style: theme.textTheme.labelLarge),
                ],
              ),
            ),
          )
      ],
    );
  }
}

class _Round {
  final String reference;
  final String text;
  final List<String> missing;
  final List<String> distractors;

  // runtime state
  final List<String?> _filled; // same length as missing; null until filled
  late final List<String> choices;

  _Round({
    required this.reference,
    required this.text,
    required this.missing,
    required this.distractors,
  }) : _filled = List<String?>.filled(missing.length, null) {
    choices = <String>{...missing, ...distractors}.toList();
    choices.shuffle(Random());
  }

  bool get isComplete => _filled.every((e) => (e ?? '').isNotEmpty);

  int? get firstUnfilledIndex {
    for (var i = 0; i < _filled.length; i++) {
      if ((_filled[i] ?? '').isEmpty) return i;
    }
    return null;
  }

  void fill(int index, String word) {
    if (index < 0 || index >= _filled.length) return;
    _filled[index] = word;
  }

  List<_VersePart> renderParts() {
    // Replace the first occurrence of each missing word (in order) with blanks or filled answer
    String remaining = text;
    final parts = <_VersePart>[];
    for (var i = 0; i < missing.length; i++) {
      final target = missing[i];
      final pos = _findWordPosition(remaining, target);
      if (pos == null) {
        // If we can't find it, just continue
        continue;
      }
      if (pos.start > 0) {
        parts.add(_VersePart.text(remaining.substring(0, pos.start)));
      }
      final answer = _filled[i];
      parts.add(_VersePart.blank(answer: answer));
      remaining = remaining.substring(pos.end);
    }
    if (remaining.isNotEmpty) {
      parts.add(_VersePart.text(remaining));
    }
    return parts;
  }

  _WordPos? _findWordPosition(String input, String word) {
    try {
      final pattern = RegExp('\\b' + RegExp.escape(word) + '\\b', caseSensitive: false);
      final m = pattern.firstMatch(input);
      if (m == null) return null;
      return _WordPos(m.start, m.end);
    } catch (_) {
      return null;
    }
  }
}

class _WordPos {
  final int start;
  final int end;
  _WordPos(this.start, this.end);
}

class _VersePart {
  final String? text;
  final bool isBlank;
  final String? answer;

  _VersePart._(this.text, this.isBlank, this.answer);
  factory _VersePart.text(String t) => _VersePart._(t, false, null);
  factory _VersePart.blank({String? answer}) => _VersePart._(null, true, answer);
}
