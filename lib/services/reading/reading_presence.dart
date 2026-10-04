/// Foreground, visible time for one chapter. The clock is monotonic and injectable
/// so lifecycle tests need no delays. It never completes reading or grants XP.
class ReadingPresence {
  final Duration Function() _now;
  Duration _accumulated = Duration.zero;
  Duration? _started;
  String? chapter;
  bool _visible = true, _foreground = true;
  ReadingPresence({Duration Function()? now}) : _now = now ?? _clock();
  static Duration Function() _clock() {
    final watch = Stopwatch()..start();
    return () => watch.elapsed;
  }

  Duration get elapsed =>
      _accumulated + (_started == null ? Duration.zero : _now() - _started!);
  Duration elapsedFor(String key) => chapter == key ? elapsed : Duration.zero;
  bool get qualified => elapsed >= const Duration(seconds: 45);
  void select(String key) {
    if (chapter != key) {
      _accumulated = Duration.zero;
      _started = null;
      chapter = key;
    }
    _sync();
  }

  void setVisible(bool value) {
    _pause();
    _visible = value;
    _sync();
  }

  void setForeground(bool value) {
    _pause();
    _foreground = value;
    _sync();
  }

  void _pause() {
    if (_started != null) _accumulated += _now() - _started!;
    _started = null;
  }

  void _sync() {
    if (chapter != null && _visible && _foreground) _started ??= _now();
  }

  void dispose() {
    _pause();
    _visible = false;
  }
}
