import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:level_up_your_faith/models/journal_entry.dart';
import 'package:level_up_your_faith/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class JournalService {
  static const String _storageKey = 'journal_entries';
  final StorageService _storage;
  final _uuid = const Uuid();

  JournalService(this._storage);

  Future<List<JournalEntry>> getEntriesForUser(String userId) async {
    try {
      final jsonString = _storage.getString(_storageKey);
      if (jsonString == null) return [];
      final List<dynamic> list = jsonDecode(jsonString);
      final entries = <JournalEntry>[];
      for (final item in list) {
        try {
          final entry = JournalEntry.fromJson(item as Map<String, dynamic>);
          if (entry.userId == userId) entries.add(entry);
        } catch (e) {
          debugPrint('Skipping corrupted journal entry: $e');
        }
      }
      return entries;
    } catch (e) {
      debugPrint('Error loading journal entries: $e');
      return [];
    }
  }

  Future<void> addEntry(JournalEntry entry) async {
    try {
      final all = await _getAllEntries();
      final toAdd = entry.id.isEmpty
          ? entry.copyWith(id: _uuid.v4(), updatedAt: entry.updatedAt ?? entry.createdAt)
          : entry;
      all.add(toAdd);
      await _saveAll(all);
    } catch (e) {
      debugPrint('Error adding journal entry: $e');
    }
  }

  Future<void> updateEntry(JournalEntry entry) async {
    try {
      final all = await _getAllEntries();
      final index = all.indexWhere((e) => e.id == entry.id);
      if (index != -1) {
        all[index] = entry.copyWith(updatedAt: DateTime.now());
        await _saveAll(all);
      }
    } catch (e) {
      debugPrint('Error updating journal entry: $e');
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      final all = await _getAllEntries();
      all.removeWhere((e) => e.id == id);
      await _saveAll(all);
    } catch (e) {
      debugPrint('Error deleting journal entry: $e');
    }
  }

  // -------------------- Private helpers --------------------
  Future<List<JournalEntry>> _getAllEntries() async {
    try {
      final jsonString = _storage.getString(_storageKey);
      if (jsonString == null) return [];
      final List<dynamic> list = jsonDecode(jsonString);
      return list
          .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error decoding journal list: $e');
      return [];
    }
  }

  Future<void> _saveAll(List<JournalEntry> all) async {
    final jsonList = all.map((e) => e.toJson()).toList();
    await _storage.save(_storageKey, jsonEncode(jsonList));
  }
}
