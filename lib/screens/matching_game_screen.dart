import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/widgets/sacred/sacred_ui.dart';
import 'package:level_up_your_faith/widgets/reward_toast.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/widgets/common/game_end_panel.dart';

class MatchingGameScreen extends StatefulWidget {
  const MatchingGameScreen({super.key});

  @override
  State<MatchingGameScreen> createState() => _MatchingGameScreenState();
}

class _MatchingGameScreenState extends State<MatchingGameScreen> {
  final _rng = Random();
  bool _loading = true;
  bool _completed = false;
  bool _xpGranted = false;
  int? _awardedXp; // for end-screen display only
  int _totalPairs = 0;
  int _matchedPairs = 0;
  List<_CardData> _cards = <_CardData>[];
  int? _firstRevealed; // index
  int? _secondRevealed; // index
  Timer? _flipBackTimer;

  @override
  void initState() {
    super.initState();
    _setupBoard();
  }

  @override
  void dispose() {
    _flipBackTimer?.cancel();
    super.dispose();
  }

  Future<void> _setupBoard() async {
    setState(() {
      _loading = true;
      _completed = false;
      _xpGranted = false;
      _awardedXp = null;
      _totalPairs = 0;
      _matchedPairs = 0;
      _cards = <_CardData>[];
      _firstRevealed = null;
      _secondRevealed = null;
    });

    try {
      final app = context.read<AppProvider>();

      // 1) Build pool from favorites (and effectively memorization list, which reuses favorites)
      final favKeys = app.favoriteVerseKeys; // 'Book:Ch:V'
      final favPairs = <(String ref, String snippet)>[];
      for (final key in favKeys) {
        if (favPairs.length >= 4) break; // cap from favorites
        final ref = _displayRefFromKey(key);
        if (ref.isEmpty) {
          debugPrint('matching-game: empty ref from key: $key');
          continue;
        }
        try {
          debugPrint('matching-game: loading passage for ref: $ref (from key: $key)');
          final text = await app.loadKjvPassage(ref);
          if (text == 'Verse unavailable' || text.contains('error') || text.contains('Error')) {
            debugPrint('matching-game: passage unavailable for $ref - skipping');
            continue;
          }
          final snippet = _toSnippet(text);
          if (snippet.isNotEmpty) {
            favPairs.add((ref, snippet));
            debugPrint('matching-game: successfully added pair for $ref');
          } else {
            debugPrint('matching-game: empty snippet for $ref - skipping');
          }
        } catch (e) {
          debugPrint('matching-game: load passage for $ref failed: $e');
        }
      }

      // 2) If fewer than 3 pairs, fill from local asset list
      List<(String ref, String snippet)> pool = [...favPairs];
      if (pool.length < 3) {
        try {
          final jsonStr = await rootBundle.loadString('assets/verses/core_verses.json');
          final List<dynamic> data = jsonDecode(jsonStr) as List<dynamic>;
          final extras = <(String, String)>[];
          for (final e in data) {
            if (e is Map) {
              final ref = (e['reference'] ?? '').toString().trim();
              final snip = (e['snippet'] ?? '').toString().trim();
              if (ref.isNotEmpty && snip.isNotEmpty) extras.add((ref, snip));
            }
          }
          // Shuffle extras and append until we reach 3–4 total pairs
          extras.shuffle(_rng);
          for (final it in extras) {
            if (pool.any((p) => p.$1 == it.$1)) continue; // avoid duplicate ref
            pool.add(it);
            if (pool.length >= 4) break; // cap at 4 pairs total
          }
        } catch (e) {
          debugPrint('matching-game: load core_verses.json failed: $e');
        }
      }

      // Ensure at least 3 pairs (if even assets fail, fallback to a small built-in list)
      if (pool.length < 3) {
        debugPrint('matching-game: insufficient pairs (${pool.length}), using fallback verses');
        final fallback = <(String, String)>[
          ('John 3:16', 'For God so loved the world, that he gave his only begotten Son...'),
          ('Psalm 23:1', 'The Lord is my shepherd; I shall not want.'),
          ('Philippians 4:6', 'Be careful for nothing; but in every thing by prayer...'),
          ('Proverbs 3:5', 'Trust in the Lord with all thine heart...'),
        ];
        fallback.shuffle(_rng);
        for (final p in fallback) {
          if (pool.any((e) => e.$1 == p.$1)) continue;
          pool.add(p);
          if (pool.length >= 3) break;
        }
      }

      // Cap to 4 pairs; if more, randomly sample 3–4
      if (pool.length > 4) {
        pool.shuffle(_rng);
        pool = pool.take(4).toList();
      }

      // Create cards (one ref + one snippet per pair)
      final cards = <_CardData>[];
      for (final p in pool) {
        final id = p.$1; // use reference as pair id
        cards.add(_CardData(pairId: id, kind: _CardKind.reference, text: p.$1));
        cards.add(_CardData(pairId: id, kind: _CardKind.snippet, text: p.$2));
      }
      cards.shuffle(_rng);

      debugPrint('matching-game: board setup complete - ${pool.length} pairs, ${cards.length} cards');
      
      if (!mounted) return;
      setState(() {
        _cards = cards;
        _totalPairs = pool.length;
        _loading = false;
        _completed = false;
        _matchedPairs = 0;
        _firstRevealed = null;
        _secondRevealed = null;
      });
    } catch (e) {
      debugPrint('matching-game: setup error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  String _displayRefFromKey(String key) {
    try {
      final parts = key.split(':');
      if (parts.length == 3) {
        return '${parts[0]} ${parts[1]}:${parts[2]}';
      }
      if (parts.length == 2) {
        return '${parts[0]} ${parts[1]}';
      }
      return key;
    } catch (_) {
      return key;
    }
  }

  String _toSnippet(String passage) {
    try {
      // The KJV helper returns lines like "John 3:16\nFor God so loved..."
      final lines = passage.split('\n');
      String body = '';
      if (lines.length > 1) {
        body = lines.sublist(1).join(' ').trim();
      } else {
        body = passage.trim();
      }
      if (body.length > 90) return body.substring(0, 90).trim() + '…';
      return body;
    } catch (_) {
      return passage.trim();
    }
  }

  void _onCardTap(int index) {
    if (_loading || _completed) return;
    if (index < 0 || index >= _cards.length) return;
    final c = _cards[index];
    if (c.matched) return;
    if (_firstRevealed != null && _secondRevealed != null) return; // waiting for flip-back

    setState(() {
      if (_firstRevealed == null) {
        _firstRevealed = index;
      } else if (_secondRevealed == null && index != _firstRevealed) {
        _secondRevealed = index;
        _checkMatch();
      }
    });
  }

  void _checkMatch() {
    final aIdx = _firstRevealed;
    final bIdx = _secondRevealed;
    if (aIdx == null || bIdx == null) return;
    final a = _cards[aIdx];
    final b = _cards[bIdx];
    final isMatch = (a.pairId == b.pairId) && (a.kind != b.kind);

    if (isMatch) {
      setState(() {
        _cards[aIdx] = a.copyWith(matched: true);
        _cards[bIdx] = b.copyWith(matched: true);
        _firstRevealed = null;
        _secondRevealed = null;
        _matchedPairs += 1;
      });
      if (_matchedPairs + 0 >= _totalPairs) {
        _onComplete();
      }
    } else {
      _flipBackTimer?.cancel();
      _flipBackTimer = Timer(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() {
          _firstRevealed = null;
          _secondRevealed = null;
        });
      });
    }
  }

  Future<void> _onComplete() async {
    if (_completed) return;
    setState(() {
      _completed = true;
    });
    // Award a small XP (streak-aware) once
    if (!_xpGranted && mounted) {
      _xpGranted = true;
      try {
        final app = context.read<AppProvider>();
        const base = 15; // gentle XP between 10–20
        final awarded = await app.awardMiniGameXp(base);
        _awardedXp = awarded;
        if (mounted) {
          final subtitle = awarded > 0 ? '+$awarded XP' : null;
          RewardToast.showSuccess(context, title: 'Play & Learn completed!', subtitle: subtitle);
        }
      } catch (e) {
        debugPrint('matching-game: award xp error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matching Game'),
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
                    const SectionHeader('Match the Bible verse with its snippet.', icon: Icons.extension),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.psychology_alt_outlined, color: cs.primary),
                        const SizedBox(width: 8),
                        Text('Matches: $_matchedPairs / $_totalPairs', style: theme.textTheme.labelMedium),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _setupBoard,
                          icon: const Icon(Icons.refresh, color: GamerColors.accent),
                          label: const Text('New Game'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final w = c.maxWidth;
                          final cols = w >= 680 ? 3 : 2;
                          return GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: _cards.length,
                            itemBuilder: (context, i) {
                              final card = _cards[i];
                              final isRevealed = (i == _firstRevealed) || (i == _secondRevealed) || card.matched;
                              return _MemoryCard(
                                revealed: isRevealed,
                                matched: card.matched,
                                label: card.kind == _CardKind.reference ? card.text : card.text,
                                hintType: card.kind,
                                onTap: () => _onCardTap(i),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    if (_completed) ...[
                      const SizedBox(height: 8),
                      GameEndPanel(
                        header: 'Great job!',
                        summary: "All pairs found!",
                        xp: _awardedXp,
                        onPlayAgain: _setupBoard,
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

enum _CardKind { reference, snippet }

class _CardData {
  final String pairId;
  final _CardKind kind;
  final String text;
  final bool matched;
  const _CardData({
    required this.pairId,
    required this.kind,
    required this.text,
    this.matched = false,
  });

  _CardData copyWith({bool? matched}) => _CardData(pairId: pairId, kind: kind, text: text, matched: matched ?? this.matched);
}

class _MemoryCard extends StatelessWidget {
  final bool revealed;
  final bool matched;
  final String label;
  final _CardKind hintType; // to show a small icon on revealed side
  final VoidCallback onTap;
  const _MemoryCard({
    required this.revealed,
    required this.matched,
    required this.label,
    required this.hintType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bg = revealed
        ? cs.surfaceContainerHigh
        : cs.surfaceContainerHighest;

    return AnimatedOpacity(
      opacity: matched ? 0.85 : 1,
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        onTap: revealed ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: matched ? GamerColors.success.withValues(alpha: 0.6) : cs.onSurfaceVariant.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: revealed
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hintType == _CardKind.reference ? Icons.menu_book_rounded : Icons.format_quote_rounded,
                          size: 18,
                          color: hintType == _CardKind.reference ? cs.primary : cs.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          hintType == _CardKind.reference ? 'Reference' : 'Snippet',
                          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          label,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.visibility, color: GamerColors.textSecondary),
                      const SizedBox(height: 8),
                      Text('Tap to reveal', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
