import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/firestore_service.dart';
import '../services/shopping_list_service.dart';

class AppState extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final ShoppingListService _shoppingListService = ShoppingListService();

  List<Product> _allProducts = [];
  List<Product> _searchResults = [];
  List<Product> _shoppingList = [];
  Set<String> _selectedSupermarkets = {'spar', 'billa', 'hofer', 'penny'};
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;

  List<Product> get allProducts => _allProducts;
  List<Product> get searchResults => _searchResults;
  List<Product> get shoppingList => _shoppingList;
  Set<String> get selectedSupermarkets => _selectedSupermarkets;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const List<String> availableSupermarkets = ['spar', 'billa', 'hofer', 'penny'];

  Future<void> initialize() async {
    await loadShoppingList();
  }

  Future<void> loadAllProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allProducts = await _firestoreService.getAllProducts();
      _applyFiltersAndSearch();
    } catch (e) {
      _error = 'Fehler beim Laden der Produkte: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadShoppingList() async {
    _shoppingList = await _shoppingListService.getShoppingList();
    notifyListeners();
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await _firestoreService.searchProductsOnServer(
        query,
        limit: 50,
        supermarkets: _selectedSupermarkets,
      );
    } catch (e) {
      _error = 'Fehler bei der Suche: $e';
    }

    _isLoading = false;
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
  }

  void selectAllSupermarkets() {
    _selectedSupermarkets = Set.from(availableSupermarkets);
    if (_searchQuery.isNotEmpty) {
      search(_searchQuery);
    } else {
      notifyListeners();
    }
  }

  void _applyFiltersAndSearch() {
    var filtered = _firestoreService.filterBySupermarkets(
      _allProducts, 
      _selectedSupermarkets,
    );
    
    if (_searchQuery.isNotEmpty) {
      filtered = _firestoreService.searchProducts(filtered, _searchQuery);
    }
    
    _searchResults = _firestoreService.sortByPrice(filtered);
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
