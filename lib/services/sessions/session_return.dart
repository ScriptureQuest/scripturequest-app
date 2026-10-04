import 'dart:convert';
import '../storage_service.dart';
import '../../models/connected/passage_reference.dart';

/// A chosen stopping point, never a completion receipt or reading claim.
class SessionReturn {
  final String reference;
  final DateTime stoppedAt;
  const SessionReturn(this.reference, this.stoppedAt);
  bool isToday(DateTime now) =>
      stoppedAt.year == now.year &&
      stoppedAt.month == now.month &&
      stoppedAt.day == now.day;
  static String key(String uid) => 'session_return_v1_$uid';
  static SessionReturn? read(StorageService storage, String uid) {
    final raw = storage.getString(key(uid));
    if (raw == null) return null;
    final value = jsonDecode(raw);
    if (value is! Map ||
        value['reference'] is! String ||
        value['stoppedAt'] is! String ||
        PassageReference.tryParse(value['reference']) == null) {
      throw const FormatException('Unreadable return point');
    }
    return SessionReturn(
        value['reference'], DateTime.parse(value['stoppedAt']));
  }

  static Future<void> save(String uid, PassageReference passage) async {
    final storage = await StorageService.getInstance();
    // Validate existing bytes before writing; malformed records are not reset.
    read(storage, uid);
    await storage.save(
        key(uid),
        jsonEncode({
          'reference': passage.label,
          'stoppedAt': DateTime.now().toIso8601String(),
        }));
  }
}
