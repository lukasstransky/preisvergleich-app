import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class FavoritesService {
  static const _key = 'favorites_v1';

  Future<List<Product>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = json.decode(raw);
      return list
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveFavorites(List<Product> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, json.encode(favorites.map((p) => p.toJson()).toList()));
  }
}
