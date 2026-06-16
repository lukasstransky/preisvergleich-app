import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const String _storageKey = 'search_history';
  static const int _maxEntries = 8;

  Future<List<String>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return [];
    try {
      return List<String>.from(json.decode(jsonString) as List);
    } catch (_) {
      return [];
    }
  }

  Future<void> addSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final history = await getHistory();
    history.remove(q);
    history.insert(0, q);
    if (history.length > _maxEntries) history.removeLast();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, json.encode(history));
  }

  Future<void> removeSearch(String query) async {
    final history = await getHistory();
    history.remove(query);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, json.encode(history));
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
