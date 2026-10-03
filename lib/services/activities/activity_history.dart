import 'dart:convert';
import '../storage_service.dart';
import '../../utils/integrity/serial_queue.dart';

/// Additive personal history; stable activity IDs are independent of layout seed.
/// Pending delivery survives a failed reward/quest write and can be retried.
class ActivityHistory {
  final StorageService storage;
  ActivityHistory(this.storage);
  static final _writes = SerialQueue();
  String key(String uid) => 'activities_v1_$uid';
  Map<String, dynamic> read(String uid) {
    final raw = storage.getString(key(uid));
    if (raw == null) return {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>)
      throw const FormatException('Unreadable activity history');
    for (final value in decoded.values) {
      if (value is! Map ||
          value['completedAt'] is! String ||
          value['bestHints'] is! int ||
          value['pending'] is! bool)
        throw const FormatException('Unreadable activity record');
    }
    return decoded;
  }

  Future<bool> record(String uid, String id, int hints) =>
      _writes.run(() async {
        if (hints < 0) throw ArgumentError('Invalid hint count');
        final data = read(uid);
        final record = Map<String, dynamic>.from(data[id] as Map? ??
            {
              'completedAt': DateTime.now().toIso8601String(),
              'bestHints': hints,
              'pending': true,
            });
        if (hints < (record['bestHints'] as int)) record['bestHints'] = hints;
        data[id] = record;
        await storage.save(key(uid), jsonEncode(data));
        return record['pending'] == true;
      });
  Future<void> settle(String uid, String id) => _writes.run(() async {
        final data = read(uid);
        (data[id] as Map)['pending'] = false;
        await storage.save(key(uid), jsonEncode(data));
      });
}
