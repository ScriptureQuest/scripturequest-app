import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:level_up_your_faith/models/settings.dart';
import 'package:level_up_your_faith/services/storage_service.dart';

class SettingsService {
  static const _key = 'app_settings_v1';

  final StorageService _storage;

  SettingsService._(this._storage);

  static Future<SettingsService> getInstance() async {
    final storage = await StorageService.getInstance();
    return SettingsService._(storage);
  }

  Future<Settings> load() async {
    try {
      final raw = _storage.getString(_key);
      if (raw == null || raw.isEmpty) {
        return Settings.defaults();
      }
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return Settings.fromJson(decoded);
    } catch (e) {
      debugPrint('SettingsService.load error: $e');
      return Settings.defaults();
    }
  }

  Future<void> save(Settings settings) async {
    try {
      await _storage.save<String>(_key, jsonEncode(settings.toJson()));
    } catch (e) {
      debugPrint('SettingsService.save error: $e');
    }
  }
}
