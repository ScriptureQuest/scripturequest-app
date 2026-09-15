import 'dart:convert';
import '../../data/exploration/catalog.dart';
import '../storage_service.dart';
import '../../utils/integrity/serial_queue.dart';

enum RecallOutcome { practiced, helped, independent }

String recallLabel(String value) => switch (value) {
      'helped' => 'Recalled with help',
      'independent' => 'Recalled independently',
      _ => 'Practiced',
    };

/// Additive evidence store. Never rewrites the legacy memory or Journey records.
class ExplorationService {
  final StorageService storage;
  static final _writes = SerialQueue();
  ExplorationService(this.storage);
  String _key(String uid) => 'exploration_v1_$uid';
  Map<String, dynamic> read(String uid) {
    final raw = storage.getString(_key(uid));
    if (raw == null)
      return {
        'discoveries': <String, dynamic>{},
        'learning': <String, dynamic>{},
        'memory': <String, dynamic>{},
        'illustrated': true
      };
    final data = jsonDecode(raw);
    if (data is! Map<String, dynamic>)
      throw const FormatException('Unreadable exploration history');
    for (final field in ['discoveries', 'learning', 'memory']) {
      if (data[field] is! Map<String, dynamic>)
        throw FormatException('Unreadable $field history');
      if ((data[field] as Map).values.any((v) => v is! Map))
        throw FormatException('Unreadable $field record');
    }
    return data;
  }

  Future<void> _save(String uid, Map<String, dynamic> data) =>
      storage.save(_key(uid), jsonEncode(data));
  Future<List<String>> recordReading(String uid, String book, int chapter,
          {required bool qualified}) =>
      _writes.run(() async {
        if (!qualified) return <String>[];
        final state = read(uid);
        final records = state['discoveries'] as Map;
        final earned = <String>[];
        for (final d in discoveries
            .where((d) => d.book == book && d.chapter == chapter)) {
          if (!records.containsKey(d.id)) {
            records[d.id] = {
              'reference': d.reference,
              'earnedAt': DateTime.now().toIso8601String(),
              'source': 'Qualified reading of ${d.reference}'
            };
            earned.add(d.id);
          }
        }
        if (earned.isNotEmpty) await _save(uid, state);
        return earned;
      });
  Future<bool> recordFinding(String uid, String id, int verse) =>
      _writes.run(() async {
        final d = discoveryById(id);
        if (verse != d.answerVerse) return false;
        final state = read(uid);
        final records = state['learning'] as Map;
        records.putIfAbsent(
            id,
            () => {
                  'reference': '${d.reference}:$verse',
                  'foundAt': DateTime.now().toIso8601String()
                });
        await _save(uid, state);
        return true;
      });
  Future<void> recordRecall(
          String uid, String key, RecallOutcome outcome, String sessionId) =>
      _writes.run(() async {
        if (sessionId.isEmpty) throw ArgumentError('Missing practice session');
        final state = read(uid);
        final memory = state['memory'] as Map;
        final record = Map<String, dynamic>.from(memory[key] as Map? ?? {});
        final sessions =
            Map<String, dynamic>.from(record['sessions'] as Map? ?? {});
        // A repeated submit/retry never changes the declared outcome or count.
        sessions.putIfAbsent(
            sessionId,
            () => {
                  'outcome': outcome.name,
                  'at': DateTime.now().toIso8601String()
                });
        record['sessions'] = sessions;
        memory[key] = record;
        await _save(uid, state);
      });
  Future<void> setIllustrated(String uid, bool value) => _writes.run(() async {
        final state = read(uid);
        state['illustrated'] = value;
        await _save(uid, state);
      });
}
