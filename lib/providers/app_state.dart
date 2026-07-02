import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/shopping_list.dart';
import '../models/shopping_list_item.dart';
import '../models/price_alert.dart';
import '../services/algolia_service.dart';
import '../services/shopping_list_service.dart';
import '../services/search_history_service.dart';
import '../services/price_alert_service.dart';
import '../services/favorites_service.dart';

class AppState extends ChangeNotifier {
  final AlgoliaServiceBase _algoliaService;
  final ShoppingListService _shoppingListService;
  final SearchHistoryService _searchHistoryService;
  final PriceAlertServiceBase _priceAlertService;
  final FavoritesService _favoritesService;

  String? _initializedForUid;
  StreamSubscription<User?>? _authSubscription;
  final String? Function() _getUid;

  AppState({
    AlgoliaServiceBase? algoliaService,
    ShoppingListService? shoppingListService,
    SearchHistoryService? searchHistoryService,
    PriceAlertServiceBase? priceAlertService,
    FavoritesService? favoritesService,
    Stream<User?> Function()? authChanges,
    String? Function()? getUid,
  })  : _algoliaService = algoliaService ?? AlgoliaService(),
        _shoppingListService = shoppingListService ?? ShoppingListService(),
        _searchHistoryService = searchHistoryService ?? SearchHistoryService(),
        _priceAlertService = priceAlertService ?? PriceAlertService(),
        _favoritesService = favoritesService ?? FavoritesService(),
        _getUid = getUid ?? (() => FirebaseAuth.instance.currentUser?.uid) {
    final stream = authChanges != null
        ? authChanges()
        : FirebaseAuth.instance.authStateChanges();
    _authSubscription = stream.listen((user) {
      if (user?.uid != _initializedForUid && user != null) {
        initialize();
      }
    });
  }

  // Search
  List<Product> _searchResults = [];
  String _searchQuery = '';
  bool _isSearching = false;
  String? _error;
  Set<String> _selectedSupermarkets = {'spar', 'billa', 'hofer', 'penny', 'lidl', 'mpreis'};
  String? _selectedCategory;
  SortOrder _sortOrder = SortOrder.relevance;
  bool _onlyPromotions = false;
  Map<String, int> _categoryCounts = {};
  List<String> _searchHistory = [];

  // Shopping lists
  List<ShoppingList> _lists = [];
  ShoppingList? _activeList;

  // Price alerts
  List<PriceAlert> _priceAlerts = [];
  final Map<String, PriceAlert> _alertsByProductId = {};
  final Map<String, PriceAlert> _alertsByKeyword = {};

  // Favorites
  List<Product> _favorites = [];

  // Search getters
  List<Product> get searchResults => _searchResults;
  String get searchQuery => _searchQuery;
  bool get isSearching => _isSearching;
  String? get error => _error;
  Set<String> get selectedSupermarkets => _selectedSupermarkets;
  String? get selectedCategory => _selectedCategory;
  SortOrder get sortOrder => _sortOrder;
  bool get onlyPromotions => _onlyPromotions;
  Map<String, int> get categoryCounts => _categoryCounts;
  List<String> get searchHistory => _searchHistory;

  Set<String> get supermarketsInResults =>
      _searchResults.map((p) => p.supermarket.toLowerCase()).toSet();

  List<String> get availableCategories {
    final sorted = _categoryCounts.keys.toList()
      ..sort((a, b) =>
          (_categoryCounts[b] ?? 0).compareTo(_categoryCounts[a] ?? 0));
    return sorted;
  }

  String? get dominantCategory {
    if (_categoryCounts.isEmpty) return null;
    return _categoryCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  bool get hasActiveFilters =>
      _selectedCategory != null ||
      _onlyPromotions ||
      _selectedSupermarkets.length != availableSupermarkets.length;

  // Favorites getters
  List<Product> get favorites => _favorites;
  bool isFavorite(String productId) => _favorites.any((p) => p.id == productId);

  // Price alert getters
  List<PriceAlert> get priceAlerts => _priceAlerts;
  bool hasAlert(String productId) => _alertsByProductId.containsKey(productId);
  PriceAlert? getAlert(String productId) => _alertsByProductId[productId];
  bool hasKeywordAlert(String keyword) => _alertsByKeyword.containsKey(keyword.toLowerCase());
  PriceAlert? getKeywordAlert(String keyword) => _alertsByKeyword[keyword.toLowerCase()];

  // Shopping list getters
  List<ShoppingList> get lists => _lists;
  ShoppingList? get activeList => _activeList;
  List<ShoppingListItem> get shoppingListItems => _activeList?.items ?? [];
  int get shoppingListItemCount => _activeList?.distinctItemCount ?? 0;
  double get shoppingListTotal => _activeList?.total ?? 0;

  // Backward-compat: returns products in active list (used for badge)
  List<Product> get shoppingList => shoppingListItems.map((i) => i.product).toList();

  static const List<String> availableSupermarkets = [
    'billa', 'spar', 'hofer', 'penny', 'lidl', 'mpreis',
  ];

  Future<void> initialize() async {
    final uid = _getUid();
    if (uid == null) return;
    _initializedForUid = uid;
    // _loadPriceAlerts() requests notification permission itself (via
    // getDeviceToken), so no separate requestPermission() call is needed here.
    await Future.wait([_loadLists(), _loadSearchHistory(), _loadPriceAlerts(), _loadFavorites()]);
  }

  // ── Search ──────────────────────────────────────────────────────────────

  Future<void> search(String query) async {
    _searchQuery = query;
    _error = null;

    if (query.trim().isEmpty) {
      _searchResults = [];
      _categoryCounts = {};
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      final result = await _algoliaService.searchProducts(
        query: _searchQuery,
        supermarkets: _selectedSupermarkets,
        category: _selectedCategory,
        sortOrder: _sortOrder,
        onlyPromotions: _onlyPromotions,
      );
      _searchResults = result.products;
      _categoryCounts = result.categoryCounts;
      _error = null;
      await _searchHistoryService.addSearch(query.trim());
      _searchHistory = await _searchHistoryService.getHistory();
    } catch (e) {
      _error = 'Fehler bei der Suche: $e';
      _searchResults = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  void _triggerSearch() {
    if (_searchQuery.isNotEmpty) search(_searchQuery);
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    _categoryCounts = {};
    _selectedCategory = null;
    _error = null;
    notifyListeners();
  }

  void toggleSupermarket(String supermarket) {
    final s = supermarket.toLowerCase();
    if (_selectedSupermarkets.contains(s)) {
      if (_selectedSupermarkets.length > 1) _selectedSupermarkets.remove(s);
    } else {
      _selectedSupermarkets.add(s);
    }
    _triggerSearch();
    notifyListeners();
  }

  void selectAllSupermarkets() {
    _selectedSupermarkets = Set.from(availableSupermarkets);
    _triggerSearch();
    notifyListeners();
  }

  void setCategory(String? category) {
    _selectedCategory = category;
    _triggerSearch();
    notifyListeners();
  }

  void setSortOrder(SortOrder order) {
    if (_sortOrder != order) {
      _sortOrder = order;
      _triggerSearch();
      notifyListeners();
    }
  }

  void toggleOnlyPromotions() {
    _onlyPromotions = !_onlyPromotions;
    _triggerSearch();
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = null;
    _sortOrder = SortOrder.relevance;
    _onlyPromotions = false;
    _selectedSupermarkets = Set.from(availableSupermarkets);
    _triggerSearch();
    notifyListeners();
  }

  Future<void> removeFromSearchHistory(String query) async {
    await _searchHistoryService.removeSearch(query);
    _searchHistory = await _searchHistoryService.getHistory();
    notifyListeners();
  }

  Future<void> clearSearchHistory() async {
    await _searchHistoryService.clearHistory();
    _searchHistory = [];
    notifyListeners();
  }

  // ── Shopping lists ───────────────────────────────────────────────────────

  Future<void> _loadLists() async {
    _lists = await _shoppingListService.getAllLists();
    final activeId = await _shoppingListService.getActiveListId();

    if (_lists.isEmpty) {
      final defaultList = await _shoppingListService.createList('Einkaufsliste');
      _lists = [defaultList];
      _activeList = defaultList;
    } else {
      _activeList = _lists.firstWhere(
        (l) => l.id == activeId,
        orElse: () => _lists.first,
      );
    }
    notifyListeners();
  }

  Future<void> _loadSearchHistory() async {
    _searchHistory = await _searchHistoryService.getHistory();
    notifyListeners();
  }

  Future<void> _saveActiveList() async {
    if (_activeList == null) return;
    await _shoppingListService.updateList(_activeList!);
    final idx = _lists.indexWhere((l) => l.id == _activeList!.id);
    if (idx != -1) _lists[idx] = _activeList!;
  }

  Future<void> switchList(String id) async {
    _activeList = _lists.firstWhere((l) => l.id == id);
    await _shoppingListService.setActiveListId(id);
    notifyListeners();
  }

  Future<void> createList(String name) async {
    final newList = await _shoppingListService.createList(name);
    _lists = await _shoppingListService.getAllLists();
    _activeList = newList;
    notifyListeners();
  }

  Future<void> deleteList(String id) async {
    await _shoppingListService.deleteList(id);
    _lists = await _shoppingListService.getAllLists();

    if (_lists.isEmpty) {
      final defaultList = await _shoppingListService.createList('Einkaufsliste');
      _lists = [defaultList];
      _activeList = defaultList;
    } else if (_activeList?.id == id) {
      _activeList = _lists.first;
      await _shoppingListService.setActiveListId(_activeList!.id);
    }
    notifyListeners();
  }

  Future<void> renameList(String id, String newName) async {
    final idx = _lists.indexWhere((l) => l.id == id);
    if (idx == -1) return;
    final updated = _lists[idx].copyWith(name: newName);
    _lists[idx] = updated;
    if (_activeList?.id == id) _activeList = updated;
    await _shoppingListService.updateList(updated);
    notifyListeners();
  }

  // ── Shopping list items ──────────────────────────────────────────────────

  bool isInShoppingList(String productId) =>
      _activeList?.items.any((i) => i.product.id == productId) ?? false;

  int getQuantity(String productId) =>
      _activeList?.items.firstWhere(
        (i) => i.product.id == productId,
        orElse: () => ShoppingListItem(product: Product(id: '', name: '', price: 0, inPromotion: false, supermarket: '')),
      ).quantity ?? 0;

  Future<void> addToShoppingList(Product product) async {
    if (_activeList == null) return;
    final items = List<ShoppingListItem>.from(_activeList!.items);
    final idx = items.indexWhere((i) => i.product.id == product.id);
    if (idx != -1) {
      items[idx] = items[idx].copyWith(quantity: items[idx].quantity + 1);
    } else {
      items.add(ShoppingListItem(product: product));
    }
    _activeList = _activeList!.copyWith(items: items);
    await _saveActiveList();
    notifyListeners();
  }

  Future<void> removeFromShoppingList(String productId) async {
    if (_activeList == null) return;
    final items = _activeList!.items.where((i) => i.product.id != productId).toList();
    _activeList = _activeList!.copyWith(items: items);
    await _saveActiveList();
    notifyListeners();
  }

  Future<void> incrementQuantity(String productId) async {
    if (_activeList == null) return;
    final items = List<ShoppingListItem>.from(_activeList!.items);
    final idx = items.indexWhere((i) => i.product.id == productId);
    if (idx != -1) {
      items[idx] = items[idx].copyWith(quantity: items[idx].quantity + 1);
      _activeList = _activeList!.copyWith(items: items);
      await _saveActiveList();
      notifyListeners();
    }
  }

  Future<void> decrementQuantity(String productId) async {
    if (_activeList == null) return;
    final items = List<ShoppingListItem>.from(_activeList!.items);
    final idx = items.indexWhere((i) => i.product.id == productId);
    if (idx != -1) {
      if (items[idx].quantity > 1) {
        items[idx] = items[idx].copyWith(quantity: items[idx].quantity - 1);
        _activeList = _activeList!.copyWith(items: items);
      } else {
        items.removeAt(idx);
        _activeList = _activeList!.copyWith(items: items);
      }
      await _saveActiveList();
      notifyListeners();
    }
  }

  Future<void> clearShoppingList() async {
    if (_activeList == null) return;
    _activeList = _activeList!.copyWith(items: []);
    await _saveActiveList();
    notifyListeners();
  }

  // ── Price alerts ─────────────────────────────────────────────────────────

  Future<void> _loadPriceAlerts() async {
    _priceAlerts = await _priceAlertService.getAlerts();
    _alertsByProductId.clear();
    _alertsByKeyword.clear();
    for (final alert in _priceAlerts) {
      if (alert.scope == AlertScope.keyword && alert.keyword != null) {
        _alertsByKeyword[alert.keyword!.toLowerCase()] = alert;
      } else {
        _alertsByProductId[alert.productId] = alert;
      }
    }
    notifyListeners();
  }

  Future<void> setPriceAlert({
    required Product product,
    required AlertType alertType,
    double? targetPrice,
  }) async {
    await _priceAlertService.createAlert(
      product: product,
      alertType: alertType,
      targetPrice: targetPrice,
    );
    await _loadPriceAlerts();
  }

  Future<void> setKeywordAlert({
    required String keyword,
    required AlertType alertType,
    double? targetPrice,
    String? category,
  }) async {
    await _priceAlertService.createKeywordAlert(
      keyword: keyword,
      alertType: alertType,
      targetPrice: targetPrice,
      category: category,
    );
    await _loadPriceAlerts();
  }

  Future<void> removePriceAlert(String alertId, String productId) async {
    await _priceAlertService.deleteAlert(alertId);
    _alertsByProductId.remove(productId);
    _priceAlerts.removeWhere((a) => a.id == alertId);
    notifyListeners();
  }

  Future<void> removeKeywordAlert(String alertId, String keyword) async {
    await _priceAlertService.deleteAlert(alertId);
    _alertsByKeyword.remove(keyword.toLowerCase());
    _priceAlerts.removeWhere((a) => a.id == alertId);
    notifyListeners();
  }

  // ── Favorites ────────────────────────────────────────────────────────────

  Future<void> _loadFavorites() async {
    _favorites = await _favoritesService.getFavorites();
    notifyListeners();
  }

  Future<void> toggleFavorite(Product product) async {
    if (isFavorite(product.id)) {
      _favorites.removeWhere((p) => p.id == product.id);
    } else {
      _favorites.add(product);
    }
    await _favoritesService.saveFavorites(_favorites);
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _algoliaService.dispose();
    super.dispose();
  }
}
