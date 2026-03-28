import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class ShoppingListService {
  static const String _storageKey = 'shopping_list';

  Future<List<Product>> getShoppingList() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((item) => Product.fromJson(item)).toList();
    } catch (e) {
      print('Error loading shopping list: $e');
      return [];
    }
  }

  Future<bool> saveShoppingList(List<Product> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(products.map((p) => p.toJson()).toList());
      return await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      print('Error saving shopping list: $e');
      return false;
    }
  }

  Future<bool> addToShoppingList(Product product) async {
    final currentList = await getShoppingList();
    
    if (currentList.any((p) => p.id == product.id)) {
      return true;
    }
    
    currentList.add(product);
    return await saveShoppingList(currentList);
  }

  Future<bool> removeFromShoppingList(String productId) async {
    final currentList = await getShoppingList();
    currentList.removeWhere((p) => p.id == productId);
    return await saveShoppingList(currentList);
  }

  Future<bool> clearShoppingList() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(_storageKey);
  }

  Future<bool> isInShoppingList(String productId) async {
    final currentList = await getShoppingList();
    return currentList.any((p) => p.id == productId);
  }
}
