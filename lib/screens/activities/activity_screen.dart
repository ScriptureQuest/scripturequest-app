import '../../widgets/sessions/done_for_now.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/activities/activity_catalog.dart';
import '../../data/connected/connected_catalog.dart';
import '../../models/activities/activity.dart';
import '../../models/connected/passage_reference.dart';
import '../../providers/app_provider.dart';
import '../../services/activities/puzzle_engine.dart';
import '../../widgets/product/product_ui.dart';
import '../../widgets/connected/next_action_panel.dart';

class ActivityFollowUp extends StatelessWidget {
  final PassageReference passage;
  const ActivityFollowUp({super.key, required this.passage});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        NextActionPanel(
            reference: passage.label, learning: true, secondaryJourney: true),
        TextButton.icon(
            onPressed: () => context.push(
                Uri(path: '/learn', queryParameters: {'ref': passage.label})
                    .toString()),
            icon: const Icon(Icons.auto_stories_outlined),
            label: const Text('All learning for this passage')),
        for (final d in ConnectedCatalog.current.forPassage(passage))
          TextButton(
              onPressed: () => context.push(
                  '/memorization-practice?key=${Uri.encodeComponent(d.memoryKey)}'),
              child: const Text('Choose a verse to remember')),
        DoneForNow(passage: passage),
      ]);
}

class ScriptureActivityScreen extends StatefulWidget {
  final String id;
  const ScriptureActivityScreen({super.key, required this.id});
  @override
  State<ScriptureActivityScreen> createState() =>
      _ScriptureActivityScreenState();
}

class _ScriptureActivityScreenState extends State<ScriptureActivityScreen> {
  ScriptureActivity? activity;
  WordSearchPuzzle? search;
  CrosswordPuzzle? crossword;
  final found = <String>{};
  final letters = <GridCell, String>{};
  final hinted = <String>{};
  final input = TextEditingController();
  final answerFocus = FocusNode();
  final gridScroll = ScrollController();
  Map? pendingDelivery;
  int? deliveredHints;
  final scroll = ScrollController();
  GridCell? anchor;
  int selected = 0, seed = 0;
  bool challenge = false, busy = false, saved = false;
  String? message, loadError;
  Map<int, String> verses = {};
  bool loaded = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      activity = ActivityCatalog.byId(widget.id);
      if (activity!.kind == ActivityKind.legacy)
        throw StateError('Not a puzzle');
      _reset();
      final app = context.read<AppProvider>();
      final record = app.activityRecords[widget.id] as Map?;
      pendingDelivery = record?['pending'] == true ? record : null;
      final result = <int, String>{};
      for (final w in activity!.words) {
        final text = await app
            .loadMemoryVerse('${activity!.passage!.chapterKey}:${w.verse}');
        if (!RegExp('\\b${w.answer}\\b', caseSensitive: false).hasMatch(text))
          throw StateError('Source word unavailable');
        result[w.verse] = text;
      }
      if (mounted)
        setState(() {
          verses = result;
          loaded = true;
        });
    } catch (_) {
      if (mounted)
        setState(() => loadError =
            'This activity could not load its Scripture source. Return to Play & Learn and try again.');
    }
  }

  void _reset() {
    if (scroll.hasClients) scroll.jumpTo(0);
    deliveredHints = null;
    found.clear();
    letters.clear();
    hinted.clear();
    anchor = null;
    saved = false;
    message = null;
    selected = 0;
    input.clear();
    if (activity!.kind == ActivityKind.wordSearch)
      search =
          WordSearchPuzzle(activity!.words, seed: seed, challenge: challenge);
    else
      crossword = CrosswordPuzzle(activity!.words);
  }

  bool get complete => activity!.kind == ActivityKind.wordSearch
      ? found.length == activity!.words.length
      : crossword!.letters.entries.every((e) => letters[e.key] == e.value);
  Future<void> save() async {
    if (busy || saved || !complete) return;
    setState(() => busy = true);
    try {
      final r = await context.read<AppProvider>().completeActivity(activity!.id,
          answers: {for (final w in activity!.words) w.answer: w.answer},
          hints: hinted.length);
      if (mounted)
        setState(() {
          saved = true;
          message =
              '${r.xp > 0 ? '+${r.xp} XP saved' : 'Practice saved · earlier reward kept'}.\n${r.changes.join('\n')}';
        });
      if (mounted && scroll.hasClients) scroll.jumpTo(0);
    } catch (_) {
      if (mounted)
        setState(() => message =
            'Could not save your result. Your progress is still here; retry saving.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> retryDelivery() async {
    if (busy || pendingDelivery == null) return;
    setState(() => busy = true);
    try {
      final app = context.read<AppProvider>();
      final accepted = app.activityRecords[widget.id] as Map?;
      if (accepted == null || accepted['pending'] != true)
        throw StateError('No pending completion');
      // This reconstructs the already accepted submission, never an unfinished board.
      final hints = accepted['bestHints'] as int;
      final result = await app.completeActivity(widget.id,
          answers: {for (final w in activity!.words) w.answer: w.answer},
          hints: hints);
      if (mounted)
        setState(() {
          saved = true;
          pendingDelivery = null;
          deliveredHints = hints;
          message =
              '${result.xp > 0 ? '+${result.xp} XP saved' : 'Earlier reward kept'}.\n${result.changes.join('\n')}';
        });
    } catch (_) {
      if (mounted)
        setState(() => message =
            'Delivery could not finish. Your pending record is kept. Retry when ready.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void tapSearch(GridCell cell) {
    if (saved || busy) return;
    setState(() {
      if (anchor == null) {
        anchor = cell;
        return;
      }
      final match = search!.match(anchor!, cell);
      anchor = null;
      if (match == null) {
        message = 'Choose the first and last letter of a straight word.';
      } else {
        found.add(match);
        message = 'Found $match · see its Scripture below.';
      }
    });
  }

  void chooseEntry(int index) {
    if (scroll.hasClients) scroll.jumpTo(0);
    setState(() {
      selected = index;
      input.text =
          crossword!.entries[index].cells.map((c) => letters[c] ?? '').join();
      message = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      answerFocus.requestFocus();
      final fieldContext = answerFocus.context;
      if (fieldContext != null) Scrollable.ensureVisible(fieldContext);
    });
  }

  @override
  void dispose() {
    input.dispose();
    answerFocus.dispose();
    gridScroll.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = activity;
    return Scaffold(
        appBar: AppBar(title: Text(a?.family ?? 'Play & Learn')),
        body: ProductWidth(
            child: loadError != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(loadError!),
                      TextButton(
                          onPressed: () {
                            setState(() {
                              loadError = null;
                              loaded = false;
                            });
                            _load();
                          },
                          child: const Text('Retry'))
                    ]))
                : !loaded
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        controller: scroll,
                        padding: const EdgeInsets.all(20),
                        children: [
                            Text(a!.title,
                                style:
                                    Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(height: 8),
                            Text(
                                '${a.passage!.label} · KJV · ${a.words.length} words'),
                            const SizedBox(height: 8),
                            const Text(
                                'Passage words from KJV. Replays keep earlier rewards. Looking at Scripture is encouraged.'),
                            TextButton(
                                onPressed: () =>
                                    context.push(a.passage!.destination.route),
                                child: const Text('Open Scripture')),
                            if (saved) ...[
                              const Icon(Icons.check_circle_outline, size: 48),
                              Text('Activity completed',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall),
                              Semantics(
                                  liveRegion: true, child: Text(message ?? '')),
                              const Text(
                                  'This records activity completion, not reading or independent recall.'),
                              Text(
                                  '${deliveredHints ?? hinted.length} answer hints used · personal best tracks fewer hints, not speed.'),
                              const SizedBox(height: 16),
                              ActivityFollowUp(passage: a.passage!),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                  onPressed: () => setState(() {
                                        seed++;
                                        _reset();
                                      }),
                                  icon: const Icon(Icons.replay),
                                  label:
                                      const Text('Play again · no repeat XP')),
                              TextButton(
                                  onPressed: () => context.canPop()
                                      ? context.pop()
                                      : context.go('/play-learn'),
                                  child: const Text('Back to activities')),
                            ] else ...[
                              if (pendingDelivery != null) ...[
                                const Text(
                                    'Your earlier activity completion still needs delivery. No replay is required.'),
                                FilledButton(
                                    onPressed: busy ? null : retryDelivery,
                                    child:
                                        const Text('Retry saved completion')),
                              ],
                              if (a.kind == ActivityKind.wordSearch) ...[
                                Wrap(spacing: 8, children: [
                                  ChoiceChip(
                                      label: const Text('Gentle'),
                                      selected: !challenge,
                                      onSelected: (_) => setState(() {
                                            challenge = false;
                                            _reset();
                                          })),
                                  ChoiceChip(
                                      label: const Text('Challenge'),
                                      selected: challenge,
                                      onSelected: (_) => setState(() {
                                            challenge = true;
                                            _reset();
                                          })),
                                ]),
                                Text(challenge
                                    ? 'Horizontal, vertical and diagonal; both directions.'
                                    : 'Horizontal and vertical; forward only.'),
                                const Text(
                                    'Tap the first and last letter. Tap the start again to cancel. Scroll sideways when needed.'),
                                const SizedBox(height: 12),
                                Text(anchor == null
                                    ? '${found.length} / ${a.words.length} words found'
                                    : 'Start selected: row ${anchor!.row + 1}, column ${anchor!.col + 1}. Choose the last letter.'),
                                _searchGrid(),
                                const SizedBox(height: 12),
                                LinearProgressIndicator(
                                    value: found.length / a.words.length),
                                Text(
                                    '${found.length} / ${a.words.length} found'),
                              ] else ...[
                                const Text(
                                    'Choose a clue or square, then enter the whole answer. Crossing letters are shared.'),
                                const SizedBox(height: 12),
                                _entryInput(),
                                const SizedBox(height: 16),
                                _crosswordGrid(),
                                ..._clues(),
                              ],
                              if (message != null)
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: Text(message!,
                                        semanticsLabel: message)),
                              if (complete)
                                FilledButton(
                                    onPressed: busy ? null : save,
                                    child: Text(busy
                                        ? 'Saving…'
                                        : 'Save completed activity')),
                              const SizedBox(height: 20),
                              Text('Words in their passage',
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              for (final w in a.words) _wordContext(w),
                            ]
                          ])));
  }

  Widget _searchGrid() {
    final marked = found.expand((w) => search!.paths[w]!).toSet();
    return _grid(
        search!.grid.length,
        search!.grid.length,
        (cell) => Semantics(
            label:
                'Row ${cell.row + 1}, column ${cell.col + 1}, ${search!.grid[cell.row][cell.col]}',
            button: true,
            child: InkWell(
                key: Key('search-${cell.row}-${cell.col}'),
                onTap: () => tapSearch(cell),
                child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: anchor == cell
                            ? Theme.of(context).colorScheme.primaryContainer
                            : marked.contains(cell)
                                ? Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer
                                : null,
                        border: Border.all(
                            color:
                                Theme.of(context).colorScheme.outlineVariant)),
                    child: Text(search!.grid[cell.row][cell.col],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18))))));
  }

  Widget _crosswordGrid() {
    final puzzle = crossword!, active = puzzle.entries[selected].cells;
    return _grid(puzzle.rows, puzzle.cols, (cell) {
      if (!puzzle.letters.containsKey(cell)) return const SizedBox();
      final number = puzzle.entries.indexWhere((e) => e.cells.first == cell);
      return Semantics(
          label:
              'Crossword row ${cell.row + 1}, column ${cell.col + 1}, ${letters[cell] ?? 'empty'}',
          button: true,
          child: InkWell(
              onTap: () {
                final candidates =
                    List.generate(puzzle.entries.length, (i) => i)
                        .where((i) => puzzle.entries[i].cells.contains(cell))
                        .toList();
                chooseEntry(candidates.firstWhere((i) => i != selected,
                    orElse: () => candidates.first));
              },
              child: Container(
                  decoration: BoxDecoration(
                      color: active.contains(cell)
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surface,
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outline)),
                  child: Stack(children: [
                    if (number >= 0)
                      Positioned(
                          left: 2,
                          top: 1,
                          child: Text('${number + 1}',
                              style: const TextStyle(fontSize: 10))),
                    Center(
                        child: Text(letters[cell] ?? '',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold))),
                  ]))));
    });
  }

  Widget _grid(int rows, int cols, Widget Function(GridCell) cell) => Scrollbar(
      controller: gridScroll,
      thumbVisibility: true,
      child: SingleChildScrollView(
          controller: gridScroll,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
              width: cols * 44.0,
              height: rows * 44.0,
              child: Column(children: [
                for (var r = 0; r < rows; r++)
                  Row(children: [
                    for (var c = 0; c < cols; c++)
                      SizedBox(
                          width: 44, height: 44, child: cell(GridCell(r, c)))
                  ])
              ]))));
  Widget _entryInput() {
    final e = crossword!.entries[selected];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(
          '${selected + 1} ${e.across ? 'Across' : 'Down'} · ${e.word.clue} (${e.word.answer.length})',
          style: Theme.of(context).textTheme.titleMedium),
      TextField(
          key: const Key('crossword-answer'),
          focusNode: answerFocus,
          controller: input,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
            LengthLimitingTextInputFormatter(e.word.answer.length)
          ],
          decoration: const InputDecoration(
              labelText: 'Answer', border: OutlineInputBorder()),
          onSubmitted: (_) => _enter()),
      Wrap(spacing: 8, children: [
        FilledButton(onPressed: _enter, child: const Text('Enter answer')),
        TextButton(
            onPressed: () => setState(() {
                  hinted.add(e.word.answer);
                  input.text = e.word.answer;
                  message = 'Answer revealed. Enter it to place the letters.';
                }),
            child: const Text('Reveal answer'))
      ]),
    ]);
  }

  List<Widget> _clues() => [
        for (var i = 0; i < crossword!.entries.length; i++)
          ListTile(
              selected: selected == i,
              onTap: () => chooseEntry(i),
              title: Text(
                  '${i + 1} ${crossword!.entries[i].across ? 'Across' : 'Down'}'),
              subtitle: Text(crossword!.entries[i].word.clue),
              trailing: crossword!.entries[i].cells
                      .every((c) => letters[c] == crossword!.letters[c])
                  ? const Icon(Icons.check)
                  : null),
      ];

  void _enter() {
    final e = crossword!.entries[selected], value = input.text.toUpperCase();
    setState(() {
      if (value.length != e.word.answer.length) {
        message = 'This answer needs ${e.word.answer.length} letters.';
        return;
      }
      if (value != e.word.answer) {
        message = 'Look again at verse ${e.word.verse}. No penalty for trying.';
        return;
      }
      for (var i = 0; i < e.cells.length; i++) letters[e.cells[i]] = value[i];
      message = 'Answer found in verse ${e.word.verse}.';
    });
  }

  Widget _wordContext(PassageWord w) => Card(
          child: ExpansionTile(
              title: Text(activity!.kind == ActivityKind.wordSearch
                  ? w.answer
                  : 'Verse ${w.verse} · Scripture evidence'),
              subtitle: Text(
                  '${activity!.passage!.label}:${w.verse}${found.contains(w.answer) ? ' · Found' : ''}'),
              children: [
            Padding(
                padding: const EdgeInsets.all(16),
                child: Text(verses[w.verse] ?? '')),
            if (activity!.kind == ActivityKind.wordSearch &&
                !found.contains(w.answer))
              TextButton(
                  onPressed: () => setState(() {
                        hinted.add(w.answer);
                        anchor = search!.paths[w.answer]!.first;
                        message =
                            'Start of ${w.answer} selected. Find its last letter.';
                      }),
                  child: const Text('Show starting letter')),
          ]));
}
