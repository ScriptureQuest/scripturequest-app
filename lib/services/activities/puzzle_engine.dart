import 'dart:math';
import '../../models/activities/activity.dart';

class GridCell {
  final int row, col;
  const GridCell(this.row, this.col);
  @override
  bool operator ==(Object other) =>
      other is GridCell && row == other.row && col == other.col;
  @override
  int get hashCode => Object.hash(row, col);
}

class PlacedWord {
  final PassageWord word;
  final int row, col;
  final bool across;
  const PlacedWord(this.word, this.row, this.col, this.across);
  List<GridCell> get cells => List.generate(word.answer.length,
      (i) => GridCell(row + (across ? 0 : i), col + (across ? i : 0)));
}

class WordSearchPuzzle {
  final List<List<String>> grid;
  final Map<String, List<GridCell>> paths;
  WordSearchPuzzle._(this.grid, this.paths);
  factory WordSearchPuzzle(List<PassageWord> words,
      {int seed = 0, bool challenge = false}) {
    const size = 10;
    final random = Random(seed), paths = <String, List<GridCell>>{};
    final grid = List.generate(size, (_) => List.filled(size, ''));
    final dirs = challenge
        ? [(0, 1), (1, 0), (1, 1), (0, -1), (-1, 0), (-1, -1)]
        : [(0, 1), (1, 0)];
    for (final word in [...words]
      ..sort((a, b) => b.answer.length.compareTo(a.answer.length))) {
      final candidates = <List<GridCell>>[];
      for (var r = 0; r < size; r++)
        for (var c = 0; c < size; c++)
          for (final d in dirs) {
            final cells = List.generate(word.answer.length,
                (i) => GridCell(r + i * d.$1, c + i * d.$2));
            if (cells.every((p) =>
                    p.row >= 0 && p.col >= 0 && p.row < size && p.col < size) &&
                List.generate(
                        cells.length,
                        (i) =>
                            grid[cells[i].row][cells[i].col].isEmpty ||
                            grid[cells[i].row][cells[i].col] == word.answer[i])
                    .every((v) => v)) candidates.add(cells);
          }
      if (candidates.isEmpty) throw StateError('Words do not fit');
      final cells = candidates[random.nextInt(candidates.length)];
      paths[word.answer] = cells;
      for (var i = 0; i < cells.length; i++)
        grid[cells[i].row][cells[i].col] = word.answer[i];
    }
    for (final row in grid)
      for (var c = 0; c < size; c++)
        if (row[c].isEmpty)
          row[c] = String.fromCharCode(65 + random.nextInt(26));
    return WordSearchPuzzle._(grid, paths);
  }
  List<GridCell> line(GridCell a, GridCell b) {
    final dr = b.row - a.row, dc = b.col - a.col;
    if (dr != 0 && dc != 0 && dr.abs() != dc.abs()) return [];
    return List.generate(max(dr.abs(), dc.abs()) + 1,
        (i) => GridCell(a.row + dr.sign * i, a.col + dc.sign * i));
  }

  String? match(GridCell start, GridCell end) {
    final cells = line(start, end);
    if (cells.any((p) =>
        p.row < 0 || p.col < 0 || p.row >= grid.length || p.col >= grid.length))
      return null;
    final value = cells.map((p) => grid[p.row][p.col]).join();
    for (final answer in paths.keys)
      if (value == answer || value.split('').reversed.join() == answer)
        return answer;
    return null;
  }
}

/// A small connected crossword builder: crossings agree, words cannot touch
/// side-by-side, and endpoints remain empty. It fails explicitly if no fit exists.
class CrosswordPuzzle {
  final List<PlacedWord> entries;
  final Map<GridCell, String> letters;
  final int rows, cols;
  CrosswordPuzzle._(this.entries, this.letters, this.rows, this.cols);
  factory CrosswordPuzzle(List<PassageWord> words) {
    final sorted = [...words]
      ..sort((a, b) => b.answer.length.compareTo(a.answer.length));
    List<PlacedWord>? solve(
        List<PlacedWord> placed, List<PassageWord> remaining) {
      if (remaining.isEmpty) return placed;
      final occupied = <GridCell, String>{};
      for (final p in placed)
        for (var i = 0; i < p.cells.length; i++)
          occupied[p.cells[i]] = p.word.answer[i];
      for (final w in remaining)
        for (final p in placed)
          for (var i = 0; i < p.word.answer.length; i++)
            for (var j = 0; j < w.answer.length; j++) {
              if (p.word.answer[i] != w.answer[j]) continue;
              final cross = p.cells[i], across = !p.across;
              final candidate = PlacedWord(w, cross.row - (across ? 0 : j),
                  cross.col - (across ? j : 0), across);
              final cells = candidate.cells;
              final before = GridCell(candidate.row - (across ? 0 : 1),
                  candidate.col - (across ? 1 : 0));
              final last = cells.last,
                  after = GridCell(
                      last.row + (across ? 0 : 1), last.col + (across ? 1 : 0));
              if (occupied.containsKey(before) || occupied.containsKey(after))
                continue;
              var valid = true;
              for (var k = 0; k < cells.length; k++) {
                final cell = cells[k], old = occupied[cell];
                if (old != null) {
                  if (old != w.answer[k] ||
                      placed.any(
                          (e) => e.across == across && e.cells.contains(cell)))
                    valid = false;
                } else if (occupied.containsKey(GridCell(
                        cell.row + (across ? 1 : 0),
                        cell.col + (across ? 0 : 1))) ||
                    occupied.containsKey(GridCell(cell.row - (across ? 1 : 0),
                        cell.col - (across ? 0 : 1)))) {
                  valid = false;
                }
              }
              final all = [...occupied.keys, ...cells];
              if (all.map((c) => c.row).reduce(max) -
                          all.map((c) => c.row).reduce(min) >
                      14 ||
                  all.map((c) => c.col).reduce(max) -
                          all.map((c) => c.col).reduce(min) >
                      14) valid = false;
              if (!valid) continue;
              final result = solve([...placed, candidate],
                  remaining.where((e) => e != w).toList());
              if (result != null) return result;
            }
      return null;
    }

    final result =
        solve([PlacedWord(sorted.first, 0, 0, true)], sorted.skip(1).toList());
    if (result == null) throw StateError('No connected crossword for this set');
    final r0 = result.expand((p) => p.cells).map((p) => p.row).reduce(min),
        c0 = result.expand((p) => p.cells).map((p) => p.col).reduce(min);
    final entries = result
        .map((p) => PlacedWord(p.word, p.row - r0, p.col - c0, p.across))
        .toList();
    final letters = <GridCell, String>{};
    for (final p in entries)
      for (var i = 0; i < p.cells.length; i++)
        letters[p.cells[i]] = p.word.answer[i];
    return CrosswordPuzzle._(
        entries,
        letters,
        letters.keys.map((p) => p.row).reduce(max) + 1,
        letters.keys.map((p) => p.col).reduce(max) + 1);
  }
}
