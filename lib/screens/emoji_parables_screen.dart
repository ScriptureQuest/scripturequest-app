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

class EmojiParablesScreen extends StatefulWidget {
  const EmojiParablesScreen({super.key});

  @override
  State<EmojiParablesScreen> createState() => _EmojiParablesScreenState();
}

class _EmojiParablesScreenState extends State<EmojiParablesScreen> {
  final _rng = Random();
  bool _loading = true;
  bool _sessionComplete = false;
  bool _xpGranted = false;
  int? _awardedXp; // end-screen display only

  final List<_EmojiRound> _rounds = <_EmojiRound>[];
  int _currentIndex = 0;

  // UI feedback state
  String? _lastWrong; // last wrong title tapped
  Set<String> _disabledChoices = <String>{};

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
      _lastWrong = null;
      _disabledChoices.clear();
    });

    try {
      final pool = await _loadParablesPool();
      pool.shuffle(_rng);
      final count = pool.length >= 4 ? 4 : (pool.length >= 3 ? 3 : pool.length);
      final selected = pool.take(count).toList();
      setState(() {
        _rounds.addAll(selected);
        _loading = false;
      });
    } catch (e) {
      debugPrint('emoji-parables: load error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _rounds.addAll(_fallbackRounds());
      });
    }
  }

  Future<List<_EmojiRound>> _loadParablesPool() async {
    final jsonStr = await rootBundle.loadString('assets/games/emoji_parables.json');
    final List<dynamic> data = jsonDecode(jsonStr) as List<dynamic>;
    final out = <_EmojiRound>[];
    for (final e in data) {
      try {
        if (e is Map) {
          final emojis = (e['emojis'] ?? '').toString().trim();
          final correct = (e['correctTitle'] ?? '').toString().trim();
          final optionsRaw = e['options'];
          final options = <String>[];
          if (optionsRaw is List) {
            for (final o in optionsRaw) {
              final s = (o ?? '').toString().trim();
              if (s.isNotEmpty) options.add(s);
            }
          }
          if (emojis.isNotEmpty && correct.isNotEmpty && options.length == 3 && options.contains(correct)) {
            out.add(_EmojiRound(emojis: emojis, correctTitle: correct, options: options));
          }
        }
      } catch (err) {
        debugPrint('emoji-parables: skip malformed entry: $err');
      }
    }
    if (out.isEmpty) return _fallbackRounds();
    return out;
  }

  List<_EmojiRound> _fallbackRounds() {
    return [
      _EmojiRound(emojis: '🐑✨', correctTitle: 'The Lost Sheep', options: const ['The Lost Sheep', 'The Good Samaritan', 'The Mustard Seed']),
      _EmojiRound(emojis: '🪙🔦', correctTitle: 'The Lost Coin', options: const ['The Lost Coin', 'The Sower', 'The Prodigal Son']),
      _EmojiRound(emojis: '👦🏡🐖', correctTitle: 'The Prodigal Son', options: const ['The Prodigal Son', 'The Two Sons', 'The Good Shepherd']),
    ];
  }

  void _onChoiceTap(String title) {
    if (_sessionComplete || _loading) return;
    final r = _rounds[_currentIndex];
    if (title == r.correctTitle) {
      setState(() {
        _lastWrong = null;
        _disabledChoices.clear();
        r.answeredCorrectly = true;
      });
    } else {
      setState(() {
        _lastWrong = title;
        _disabledChoices.add(title);
      });
    }
  }

  void _goNext() {
    if (_currentIndex + 1 < _rounds.length) {
      setState(() {
        _currentIndex += 1;
        _lastWrong = null;
        _disabledChoices.clear();
      });
    } else {
      _completeSession();
    }
  }

  Future<void> _completeSession() async {
    if (_sessionComplete) return;
    setState(() => _sessionComplete = true);
    if (!_xpGranted && mounted) {
      _xpGranted = true;
      try {
        final app = context.read<AppProvider>();
        const base = 12; // consistent with other games (gentle)
        final awarded = await app.awardMiniGameXp(base);
        _awardedXp = awarded;
        await app.incrementLearningGamesCompleted();
        // One-off achievement for Emoji Parables
        await app.unlockAchievementPublic('emoji_parables_once');
        if (mounted) {
          final subtitle = awarded > 0 ? '+$awarded XP' : null;
          RewardToast.showSuccess(context, title: 'Play & Learn completed!', subtitle: subtitle);
        }
      } catch (e) {
        debugPrint('emoji-parables: award xp error: $e');
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
        title: const Text('Emoji Parables'),
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
                    const SectionHeader('Guess the story by emojis.', icon: Icons.extension),
                    const SizedBox(height: 8),
                    if (!_sessionComplete && r != null) ...[
                      FadeSlideIn(
                        child: SacredCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                r.emojis,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.displaySmall?.copyWith(fontSize: 40, height: 1.2),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Which story is this?',
                                style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AnswerButtons(
                        options: r.options,
                        disabled: _disabledChoices,
                        onTap: _onChoiceTap,
                        correct: r.answeredCorrectly ? r.correctTitle : null,
                      ),
                      if (_lastWrong != null && !r.answeredCorrectly) ...[
                        const SizedBox(height: 12),
                        SacredCard(
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.amber),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text('Not quite. Try another one.', style: theme.textTheme.labelMedium?.copyWith(color: Colors.amber)),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (r.answeredCorrectly) ...[
                        const SizedBox(height: 12),
                        SacredCard(
                          child: Row(
                            children: [
                              const Icon(Icons.celebration, color: GamerColors.success),
                              const SizedBox(width: 10),
                              Expanded(child: Text("That's right!", style: theme.textTheme.bodyMedium)),
                              ElevatedButton.icon(
                                onPressed: _goNext,
                                icon: const Icon(Icons.arrow_forward, color: GamerColors.darkBackground),
                                label: Text(_currentIndex + 1 < _rounds.length ? 'Next' : 'Finish'),
                              )
                            ],
                          ),
                        ),
                      ],
                    ] else ...[
                      GameEndPanel(
                        header: 'Puzzle Completed!',
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

class _EmojiRound {
  final String emojis;
  final String correctTitle;
  final List<String> options;
  bool answeredCorrectly;

  _EmojiRound({required this.emojis, required this.correctTitle, required this.options, this.answeredCorrectly = false});
}

class _AnswerButtons extends StatelessWidget {
  final List<String> options;
  final Set<String> disabled;
  final void Function(String title) onTap;
  final String? correct;
  const _AnswerButtons({required this.options, required this.disabled, required this.onTap, this.correct});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      children: [
        for (final title in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: (disabled.contains(title) || correct != null) ? null : () => onTap(title),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _backgroundFor(title, cs, correct, disabled.contains(title)),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cs.onSurfaceVariant.withValues(alpha: 0.18), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      _iconFor(title, correct, disabled.contains(title)),
                      size: 20,
                      color: _iconColorFor(title, cs, correct, disabled.contains(title)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: _textColorFor(title, theme, cs, correct, disabled.contains(title)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _backgroundFor(String title, ColorScheme cs, String? correct, bool isDisabled) {
    if (correct == title) return cs.surfaceContainerHigh;
    if (isDisabled) return cs.surfaceContainerHighest;
    return cs.surfaceContainerHigh;
  }

  Color _textColorFor(String title, ThemeData theme, ColorScheme cs, String? correct, bool isDisabled) {
    if (correct == title) return theme.colorScheme.onSurface;
    if (isDisabled) return cs.onSurfaceVariant;
    return theme.colorScheme.onSurface;
  }

  IconData _iconFor(String title, String? correct, bool isDisabled) {
    if (correct == title) return Icons.check_circle;
    if (isDisabled) return Icons.cancel_outlined;
    return Icons.touch_app_rounded;
  }

  Color _iconColorFor(String title, ColorScheme cs, String? correct, bool isDisabled) {
    if (correct == title) return Colors.greenAccent;
    if (isDisabled) return Colors.amber;
    return GamerColors.textSecondary;
  }
}
