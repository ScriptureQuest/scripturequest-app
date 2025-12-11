import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  Future<void> save<T>(String key, T value) async {
    try {
      if (_prefs == null) {
        debugPrint('StorageService.save called before init; skipping key="$key"');
        return;
      }
      if (value is String) {
        await _prefs!.setString(key, value);
      } else if (value is int) {
        await _prefs!.setInt(key, value);
      } else if (value is double) {
        await _prefs!.setDouble(key, value);
      } else if (value is bool) {
        await _prefs!.setBool(key, value);
      } else if (value is List<String>) {
        await _prefs!.setStringList(key, value);
      } else {
        await _prefs!.setString(key, jsonEncode(value));
      }
    } catch (e) {
      debugPrint('Error saving to storage: $e');
    }
  }

  T? get<T>(String key) {
    try {
      if (_prefs == null) {
        debugPrint('StorageService.get called before init; key="$key"');
        return null;
      }
      final value = _prefs!.get(key);
      if (value == null) return null;
      return value as T;
    } catch (e) {
      debugPrint('Error getting from storage: $e');
      return null;
    }
  }

  String? getString(String key) {
    if (_prefs == null) {
      debugPrint('StorageService.getString called before init; key="$key"');
      return null;
    }
    return _prefs!.getString(key);
  }

  int? getInt(String key) {
    if (_prefs == null) {
      debugPrint('StorageService.getInt called before init; key="$key"');
      return null;
    }
    return _prefs!.getInt(key);
  }

  double? getDouble(String key) {
    if (_prefs == null) {
      debugPrint('StorageService.getDouble called before init; key="$key"');
      return null;
    }
    return _prefs!.getDouble(key);
  }

  bool? getBool(String key) {
    if (_prefs == null) {
      debugPrint('StorageService.getBool called before init; key="$key"');
      return null;
    }
    return _prefs!.getBool(key);
  }

  List<String>? getStringList(String key) {
    if (_prefs == null) {
      debugPrint('StorageService.getStringList called before init; key="$key"');
      return null;
    }
    return _prefs!.getStringList(key);
  }

  Future<void> delete(String key) async {
    try {
      if (_prefs == null) {
        debugPrint('StorageService.delete called before init; key="$key"');
        return;
      }
      await _prefs!.remove(key);
    } catch (e) {
      debugPrint('Error deleting from storage: $e');
    }
  }

  Future<void> clear() async {
    try {
      if (_prefs == null) {
        debugPrint('StorageService.clear called before init; skipping');
        return;
      }
      await _prefs!.clear();
    } catch (e) {
      debugPrint('Error clearing storage: $e');
    }
  }

  bool containsKey(String key) {
    if (_prefs == null) {
      debugPrint('StorageService.containsKey called before init; key="$key"');
      return false;
    }
    return _prefs!.containsKey(key);
  }
}
