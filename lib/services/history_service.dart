import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/estimation_result.dart';

class HistoryService {
  static const _key = 'scan_history';
  static const _maxHistory = 50;

  static Future<void> saveResult(WeightEstimationResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    final entry = {
      'objectName': result.objectName,
      'objectNameHindi': result.objectNameHindi,
      'icon': result.icon,
      'estimatedWeightGrams': result.estimatedWeightGrams,
      'minWeightGrams': result.minWeightGrams,
      'maxWeightGrams': result.maxWeightGrams,
      'confidenceScore': result.confidenceScore,
      'category': result.category,
      'timestamp': result.timestamp.toIso8601String(),
    };

    history.insert(0, entry);
    if (history.length > _maxHistory) history.removeLast();

    await prefs.setString(_key, jsonEncode(history));
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(raw));
    } catch (_) {
      return [];
    }
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
