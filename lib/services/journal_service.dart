import 'dart:convert';
import 'package:level_up_your_faith/models/journal_entry.dart';
import 'package:level_up_your_faith/services/storage_service.dart';
import '../utils/integrity/serial_queue.dart';
import 'package:uuid/uuid.dart';

class JournalService {
  static const String _storageKey = 'journal_entries';
  static final _writes = SerialQueue();
  final StorageService _storage;
  final _uuid = const Uuid();
  JournalService(this._storage);

  List<dynamic> _rawEntries() {
    final raw = _storage.getString(_storageKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException(
          'Journal data needs recovery; original data preserved');
    }
    return List<dynamic>.from(decoded);
  }

  JournalEntry? _entry(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    try {
      final entry = JournalEntry.fromJson(raw);
      return entry.id.isEmpty || entry.userId.isEmpty ? null : entry;
    } catch (_) {
      return null;
    }
  }

  Future<List<JournalEntry>> getEntriesForUser(String userId) async {
    final entries = <JournalEntry>[];
    for (final raw in _rawEntries()) {
      final entry = _entry(raw);
      if (entry != null && entry.userId == userId) entries.add(entry);
    }
    return entries;
  }

  Future<void> addEntry(JournalEntry entry) => _writes.run(() async {
        final all =
            _rawEntries(); // Invalid top-level JSON blocks writes, never resets.
        final toAdd = entry.id.isEmpty
            ? entry.copyWith(
                id: _uuid.v4(), updatedAt: entry.updatedAt ?? entry.createdAt)
            : entry;
        if (all.any((raw) => _entry(raw)?.id == toAdd.id)) return;
        all.add(toAdd.toJson());
        await _saveRaw(all);
      });

  Future<void> updateEntry(JournalEntry entry) => _writes.run(() async {
        final all = _rawEntries();
        final index = all.indexWhere((raw) {
          final saved = _entry(raw);
          return saved?.id == entry.id && saved?.userId == entry.userId;
        });
        if (index == -1)
          throw StateError('Journal entry not found; no data changed');
        // Retain unknown fields for forward compatibility and recovery.
        all[index] = {
          ...Map<String, dynamic>.from(all[index] as Map),
          ...entry.copyWith(updatedAt: DateTime.now()).toJson()
        };
        await _saveRaw(all);
      });

  Future<void> deleteEntry(String id) => _writes.run(() async {
        final all = _rawEntries();
        all.removeWhere((raw) => _entry(raw)?.id == id);
        await _saveRaw(all);
      });

  Future<void> _saveRaw(List<dynamic> all) async {
    // Preserve the previous exact bytes before any mutation, including malformed rows.
    final original = _storage.getString(_storageKey);
    if (original != null)
      await _storage.save('journal_entries_previous', original);
    await _storage.save(_storageKey, jsonEncode(all));
  }
}
