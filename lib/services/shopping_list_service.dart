import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shopping_list.dart';
import '../models/shopping_list_item.dart';
import '../models/product.dart';

class ShoppingListService {
  static const String _listsKey = 'shopping_lists_v2';
  static const String _activeListIdKey = 'active_list_id';

  Future<List<ShoppingList>> getAllLists() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_listsKey);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((e) => ShoppingList.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveLists(List<ShoppingList> lists) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_listsKey, json.encode(lists.map((e) => e.toJson()).toList()));
  }

  Future<String?> getActiveListId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeListIdKey);
  }

  Future<void> setActiveListId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeListIdKey, id);
  }

  Future<ShoppingList> createList(String name) async {
    final lists = await getAllLists();
    final newList = ShoppingList(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      items: [],
      createdAt: DateTime.now(),
    );
    lists.add(newList);
    await saveLists(lists);
    await setActiveListId(newList.id);
    return newList;
  }

  Future<void> deleteList(String id) async {
    final lists = await getAllLists();
    lists.removeWhere((l) => l.id == id);
    await saveLists(lists);
  }

  Future<void> updateList(ShoppingList list) async {
    final lists = await getAllLists();
    final idx = lists.indexWhere((l) => l.id == list.id);
    if (idx != -1) {
      lists[idx] = list;
    } else {
      lists.add(list);
    }
    await saveLists(lists);
  }
}
