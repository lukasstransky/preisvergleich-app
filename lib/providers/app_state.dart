import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/algolia_service.dart';
import '../services/shopping_list_service.dart';

class AppState extends ChangeNotifier {
  final AlgoliaService _algoliaService = AlgoliaService();
  final ShoppingListService _shoppingListService = ShoppingListService();

  List<Product> _searchResults = [];
  List<Product> _shoppingList = [];
  Set<String> _selectedSupermarkets = {'spar', 'billa', 'hofer', 'penny'};
  String _searchQuery = '';
  bool _isSearching = false;
  String? _error;

  List<Product> get searchResults => _searchResults;
  List<Product> get shoppingList => _shoppingList;
  Set<String> get selectedSupermarkets => _selectedSupermarkets;
  String get searchQuery => _searchQuery;
  bool get isSearching => _isSearching;
  String? get error => _error;

  static const List<String> availableSupermarkets = ['spar', 'billa', 'hofer', 'penny'];

  Future<void> initialize() async {
    await loadShoppingList();
  }

  Future<void> loadShoppingList() async {
    _shoppingList = await _shoppingListService.getShoppingList();
    notifyListeners();
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    _error = null;

    if (query.trim().isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      final results = await _algoliaService.searchProducts(
        query: _searchQuery,
        supermarkets: _selectedSupermarkets,
      );
      _searchResults = results;
      _error = null;
    } catch (e) {
      _error = 'Fehler bei der Suche: $e';
      _searchResults = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    _error = null;
    notifyListeners();
  }

  void toggleSupermarket(String supermarket) {
    final lowerSupermarket = supermarket.toLowerCase();
    if (_selectedSupermarkets.contains(lowerSupermarket)) {
      if (_selectedSupermarkets.length > 1) {
        _selectedSupermarkets.remove(lowerSupermarket);
      }
    } else {
      _selectedSupermarkets.add(lowerSupermarket);
    }
    
    if (_searchQuery.isNotEmpty) {
      search(_searchQuery);
    }
    notifyListeners();
  }

  void selectAllSupermarkets() {
    _selectedSupermarkets = Set.from(availableSupermarkets);
    if (_searchQuery.isNotEmpty) {
      search(_searchQuery);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _algoliaService.dispose();
    super.dispose();
  }

  Future<void> addToShoppingList(Product product) async {
    await _shoppingListService.addToShoppingList(product);
    await loadShoppingList();
  }

  Future<void> removeFromShoppingList(String productId) async {
    await _shoppingListService.removeFromShoppingList(productId);
    await loadShoppingList();
  }

  Future<void> clearShoppingList() async {
    await _shoppingListService.clearShoppingList();
    await loadShoppingList();
  }

  bool isInShoppingList(String productId) {
    return _shoppingList.any((p) => p.id == productId);
  }

  double get shoppingListTotal {
    return _shoppingList.fold(0.0, (sum, product) => sum + product.price);
  }
}
