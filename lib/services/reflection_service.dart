import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:level_up_your_faith/models/daily_reflection_model.dart';
import 'package:level_up_your_faith/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class ReflectionService {
  static const String _storageKey = 'reflections';
  final StorageService _storage;
  final _uuid = const Uuid();

  ReflectionService(this._storage);

  Future<List<DailyReflectionModel>> getAllReflections() async {
    try {
      final jsonString = _storage.getString(_storageKey);
      if (jsonString == null) return [];
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => DailyReflectionModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading reflections: $e');
      return [];
    }
  }

  Future<DailyReflectionModel?> getTodayReflection() async {
    final reflections = await getAllReflections();
    final today = DateTime.now();
    
    try {
      return reflections.firstWhere((r) => 
        r.date.year == today.year &&
        r.date.month == today.month &&
        r.date.day == today.day
      );
    } catch (e) {
      return null;
    }
  }

  Future<List<DailyReflectionModel>> getReflectionsByDateRange(DateTime start, DateTime end) async {
    final reflections = await getAllReflections();
    return reflections.where((r) => 
      r.date.isAfter(start.subtract(const Duration(days: 1))) &&
      r.date.isBefore(end.add(const Duration(days: 1)))
    ).toList();
  }

  Future<void> saveReflection(DailyReflectionModel reflection) async {
    final reflections = await getAllReflections();
    
    final existingIndex = reflections.indexWhere((r) => r.id == reflection.id);
    if (existingIndex != -1) {
      reflections[existingIndex] = reflection.copyWith(updatedAt: DateTime.now());
    } else {
      reflections.add(reflection);
    }
    
    reflections.sort((a, b) => b.date.compareTo(a.date));
    await _saveReflections(reflections);
  }

  Future<void> deleteReflection(String id) async {
    final reflections = await getAllReflections();
    reflections.removeWhere((r) => r.id == id);
    await _saveReflections(reflections);
  }

  Future<DailyReflectionModel> createReflection(String userId, String verseId, String text, String mood) async {
    final reflection = DailyReflectionModel(
      id: _uuid.v4(),
      userId: userId,
      date: DateTime.now(),
      verseId: verseId,
      reflectionText: text,
      mood: mood,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await saveReflection(reflection);
    return reflection;
  }

  Future<void> _saveReflections(List<DailyReflectionModel> reflections) async {
    final jsonList = reflections.map((r) => r.toJson()).toList();
    await _storage.save(_storageKey, jsonEncode(jsonList));
  }
}
