import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:preisvergleich_app/providers/app_state.dart';
import 'package:preisvergleich_app/models/product.dart';
import 'package:preisvergleich_app/models/price_alert.dart';
import 'package:preisvergleich_app/services/algolia_service.dart';
import 'package:preisvergleich_app/services/price_alert_service.dart';
import 'package:preisvergleich_app/services/shopping_list_service.dart';
import 'package:preisvergleich_app/services/favorites_service.dart';
import 'package:preisvergleich_app/services/premium_service.dart';
import 'package:preisvergleich_app/services/analytics_service.dart';

// ── Inline mocks ──────────────────────────────────────────────────────────────

class _MockAlgolia implements AlgoliaServiceBase {
  final List<Product> products;
  bool throwOnSearch;
  int searchCallCount = 0;

  _MockAlgolia(this.products, {this.throwOnSearch = false});

  @override
  Future<SearchResult> searchProducts({
    required String query,
    Set<String>? supermarkets,
    String? category,
    SortOrder sortOrder = SortOrder.relevance,
    bool onlyPromotions = false,
    int hitsPerPage = 200,
  }) async {
    searchCallCount++;
    if (throwOnSearch) throw Exception('network error');
    if (query.trim().isEmpty) {
      return SearchResult(products: [], categoryCounts: {});
    }
    final q = query.toLowerCase();
    var filtered = products.where((p) {
      final matchesQuery = p.name.toLowerCase().contains(q);
      final matchesSupermarket = supermarkets == null ||
          supermarkets.isEmpty ||
          supermarkets.contains(p.supermarket.toLowerCase());
      final matchesCategory =
          category == null || p.normalizedCategory == category;
      final matchesPromo = !onlyPromotions || p.inPromotion;
      return matchesQuery && matchesSupermarket && matchesCategory && matchesPromo;
    }).toList();

    if (sortOrder == SortOrder.unitPrice) {
      filtered.sort((a, b) =>
          (a.unitPrice ?? a.price).compareTo(b.unitPrice ?? b.price));
    }

    final counts = <String, int>{};
    for (final p in filtered) {
      if (p.normalizedCategory != null) {
        counts[p.normalizedCategory!] =
            (counts[p.normalizedCategory!] ?? 0) + 1;
      }
    }
    return SearchResult(products: filtered, categoryCounts: counts);
  }

  @override
  void dispose() {}
}

class _MockAlerts implements PriceAlertServiceBase {
  final List<PriceAlert> _alerts;

  _MockAlerts([List<PriceAlert>? initial]) : _alerts = List.from(initial ?? []);

  @override
  Future<List<PriceAlert>> getAlerts() async => List.from(_alerts);

  @override
  Future<void> createAlert({
    required Product product,
    required AlertType alertType,
    double? targetPrice,
  }) async {
    _alerts.add(PriceAlert(
      id: 'a-${_alerts.length}',
      productId: product.id,
      productName: product.name,
      supermarket: product.supermarket,
      currentPrice: product.price,
      alertType: alertType,
      targetPrice: targetPrice,
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<void> createKeywordAlert({
    required String keyword,
    required AlertType alertType,
    double? targetPrice,
    String? category,
  }) async {
    _alerts.add(PriceAlert(
      id: 'kw-${_alerts.length}',
      productId: '',
      productName: keyword,
      supermarket: '',
      currentPrice: 0,
      alertType: alertType,
      createdAt: DateTime.now(),
      scope: AlertScope.keyword,
      keyword: keyword.toLowerCase(),
    ));
  }

  @override
  Future<void> deleteAlert(String id) async =>
      _alerts.removeWhere((a) => a.id == id);
}

class _FakePremium implements PremiumServiceBase {
  final PremiumConfig config;
  bool premium;
  _FakePremium({PremiumConfig? config, this.premium = false})
      : config = config ?? PremiumConfig.defaults;

  @override
  Future<PremiumConfig> loadConfig() async => config;
  @override
  Future<bool> loadEntitlement() async => premium;
  @override
  Stream<bool> entitlementChanges() => const Stream<bool>.empty();
  @override
  Future<bool> startPurchase() async => premium = true;
  @override
  Future<bool> restorePurchases() async => premium;
  @override
  void dispose() {}
}

// ── Test data ─────────────────────────────────────────────────────────────────

final _p1 = Product(
  id: 'p1',
  name: 'Vollmilch 1L',
  price: 1.29,
  inPromotion: false,
  supermarket: 'billa',
  category: 'Milchprodukte',
  normalizedCategory: 'milchprodukte',
);

final _p2 = Product(
  id: 'p2',
  name: 'Bio Vollmilch 1L',
  price: 1.59,
  originalPrice: 1.89,
  promotionText: '15% SALE',
  inPromotion: true,
  supermarket: 'spar',
  category: 'Milchprodukte',
  normalizedCategory: 'milchprodukte',
);

final _p3 = Product(
  id: 'p3',
  name: 'Butter 250g',
  price: 2.49,
  inPromotion: false,
  supermarket: 'hofer',
  category: 'Milchprodukte',
  normalizedCategory: 'milchprodukte',
);

final _p4 = Product(
  id: 'p4',
  name: 'Apfelsaft 1L',
  price: 0.99,
  originalPrice: 1.29,
  promotionText: '25% SALE',
  inPromotion: true,
  supermarket: 'penny',
  category: 'Getränke',
  normalizedCategory: 'getränke',
);

final _p5 = Product(
  id: 'p5',
  name: 'Orangensaft 1L',
  price: 1.49,
  inPromotion: false,
  supermarket: 'lidl',
  category: 'Getränke',
  normalizedCategory: 'getränke',
);

final _allProducts = [_p1, _p2, _p3, _p4, _p5];

// ── Helper ────────────────────────────────────────────────────────────────────

Future<AppState> _makeState({
  List<Product>? products,
  bool throwOnSearch = false,
  List<PriceAlert>? initialAlerts,
  FakeFirebaseFirestore? firestore,
  PremiumServiceBase? premiumService,
}) async {
  SharedPreferences.resetStatic();
  SharedPreferences.setMockInitialValues({});
  final fs = firestore ?? FakeFirebaseFirestore();
  final state = AppState(
    algoliaService: _MockAlgolia(
      products ?? _allProducts,
      throwOnSearch: throwOnSearch,
    ),
    priceAlertService: _MockAlerts(initialAlerts),
    shoppingListService: ShoppingListService(firestore: fs, getUid: () => 'test-uid'),
    favoritesService: FavoritesService(firestore: fs, getUid: () => 'test-uid'),
    premiumService: premiumService,
    analytics: const NoOpAnalyticsService(),
    authChanges: () => const Stream.empty(),
    getUid: () => 'test-uid',
  );
  await state.initialize();
  return state;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── Search ──────────────────────────────────────────────────────────────────

  group('search', () {
    test('search() sets query and returns results', () async {
      final state = await _makeState();

      await state.search('milch');

      expect(state.searchQuery, 'milch');
      // p1 Vollmilch + p2 Bio Vollmilch match; p3 Butter does not
      expect(state.searchResults.length, 2);
      expect(state.isSearching, false);
    });

    test('search() adds query to search history', () async {
      final state = await _makeState();

      await state.search('milch');

      expect(state.searchHistory.contains('milch'), true);
    });

    test('search() handles error gracefully', () async {
      final state = await _makeState(throwOnSearch: true);

      await state.search('milch');

      expect(state.searchResults, isEmpty);
      expect(state.error, isNotNull);
      expect(state.isSearching, false);
    });

    test('search() with empty query clears results', () async {
      final state = await _makeState();
      await state.search('milch');
      expect(state.searchResults, isNotEmpty);

      await state.search('');

      expect(state.searchResults, isEmpty);
      expect(state.searchQuery, '');
    });

    test('clearSearch() resets all search state', () async {
      final state = await _makeState();
      await state.search('milch');
      state.setCategory('milchprodukte');

      state.clearSearch();

      expect(state.searchQuery, '');
      expect(state.searchResults, isEmpty);
      expect(state.selectedCategory, isNull);
    });
  });

  // ── Filters ─────────────────────────────────────────────────────────────────

  group('filters', () {
    test('toggleSupermarket() removes supermarket from selection', () async {
      final state = await _makeState();

      state.toggleSupermarket('billa');

      expect(state.selectedSupermarkets.contains('billa'), false);
    });

    test('toggleSupermarket() cannot remove the last remaining supermarket',
        () async {
      final state = await _makeState();
      // Remove all except 'billa'
      for (final s in ['spar', 'hofer', 'penny', 'lidl', 'mpreis']) {
        state.toggleSupermarket(s);
      }
      expect(state.selectedSupermarkets.length, 1);

      // Attempt to remove the last one
      state.toggleSupermarket('billa');

      expect(state.selectedSupermarkets.length, 1);
      expect(state.selectedSupermarkets.contains('billa'), true);
    });

    test('selectAllSupermarkets() resets selection to all 6', () async {
      final state = await _makeState();
      state.toggleSupermarket('billa');
      state.toggleSupermarket('spar');
      expect(state.selectedSupermarkets.length, 4);

      state.selectAllSupermarkets();

      expect(state.selectedSupermarkets.length, 6);
    });

    test('setCategory() updates selectedCategory', () async {
      final state = await _makeState();

      state.setCategory('milchprodukte');

      expect(state.selectedCategory, 'milchprodukte');
    });

    test('setSortOrder() does not re-trigger search when order is unchanged',
        () async {
      final algolia = _MockAlgolia(_allProducts);
      final fs = FakeFirebaseFirestore();
      SharedPreferences.setMockInitialValues({});
      final state = AppState(
        algoliaService: algolia,
        priceAlertService: _MockAlerts(),
        shoppingListService: ShoppingListService(firestore: fs, getUid: () => 'test-uid'),
        favoritesService: FavoritesService(firestore: fs, getUid: () => 'test-uid'),
        analytics: const NoOpAnalyticsService(),
        authChanges: () => const Stream.empty(),
        getUid: () => 'test-uid',
      );
      await state.initialize();

      await state.search('milch');
      final countAfterSearch = algolia.searchCallCount;

      // sortOrder is already relevance — setSortOrder with same value is a no-op
      state.setSortOrder(SortOrder.relevance);

      expect(algolia.searchCallCount, countAfterSearch);
    });

    test('setSortOrder() triggers re-search when order changes', () async {
      final algolia = _MockAlgolia(_allProducts);
      final fs = FakeFirebaseFirestore();
      SharedPreferences.setMockInitialValues({});
      final state = AppState(
        algoliaService: algolia,
        priceAlertService: _MockAlerts(),
        shoppingListService: ShoppingListService(firestore: fs, getUid: () => 'test-uid'),
        favoritesService: FavoritesService(firestore: fs, getUid: () => 'test-uid'),
        analytics: const NoOpAnalyticsService(),
        authChanges: () => const Stream.empty(),
        getUid: () => 'test-uid',
      );
      await state.initialize();

      await state.search('milch');
      final countAfterSearch = algolia.searchCallCount;

      state.setSortOrder(SortOrder.unitPrice);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(algolia.searchCallCount, greaterThan(countAfterSearch));
    });

    test('toggleOnlyPromotions() flips the flag', () async {
      final state = await _makeState();
      expect(state.onlyPromotions, false);

      state.toggleOnlyPromotions();
      expect(state.onlyPromotions, true);

      state.toggleOnlyPromotions();
      expect(state.onlyPromotions, false);
    });

    test('clearFilters() resets all filters to defaults', () async {
      final state = await _makeState();
      state.setCategory('milchprodukte');
      state.toggleOnlyPromotions();
      state.toggleSupermarket('billa');

      state.clearFilters();

      expect(state.selectedCategory, isNull);
      expect(state.onlyPromotions, false);
      expect(state.selectedSupermarkets.length, 6);
      expect(state.hasActiveFilters, false);
    });

    test('hasActiveFilters returns false for fresh AppState', () async {
      final state = await _makeState();

      expect(state.hasActiveFilters, false);
    });

    test('hasActiveFilters returns true when category is set', () async {
      final state = await _makeState();
      state.setCategory('milchprodukte');

      expect(state.hasActiveFilters, true);
    });

    test('hasActiveFilters returns true when onlyPromotions is true', () async {
      final state = await _makeState();
      state.toggleOnlyPromotions();

      expect(state.hasActiveFilters, true);
    });

    test('hasActiveFilters returns true when not all supermarkets selected',
        () async {
      final state = await _makeState();
      state.toggleSupermarket('billa');

      expect(state.hasActiveFilters, true);
    });
  });

  // ── dominantCategory ─────────────────────────────────────────────────────────

  group('dominantCategory', () {
    test('dominantCategory returns null when no search done', () async {
      final state = await _makeState();

      expect(state.dominantCategory, isNull);
    });

    test('dominantCategory returns normalizedCategory with most products',
        () async {
      final state = await _makeState();
      // 'milch' matches p1 (Vollmilch) + p2 (Bio Vollmilch) — both milchprodukte
      await state.search('milch');

      expect(state.dominantCategory, 'milchprodukte');
    });

    test('dominantCategory returns getränke when only juice products match',
        () async {
      final state = await _makeState();
      // 'saft' matches p4 Apfelsaft + p5 Orangensaft — both getränke
      await state.search('saft');

      expect(state.dominantCategory, 'getränke');
    });
  });

  // ── Shopping list items ──────────────────────────────────────────────────────

  group('shopping list items', () {
    test('addToShoppingList() adds item with quantity 1', () async {
      final state = await _makeState();

      await state.addToShoppingList(_p1);

      expect(state.shoppingListItems.length, 1);
      expect(state.getQuantity('p1'), 1);
    });

    test('addToShoppingList() increments quantity for existing item', () async {
      final state = await _makeState();

      await state.addToShoppingList(_p1);
      await state.addToShoppingList(_p1);

      expect(state.getQuantity('p1'), 2);
      expect(state.shoppingListItems.length, 1);
    });

    test('removeFromShoppingList() removes item', () async {
      final state = await _makeState();
      await state.addToShoppingList(_p1);

      await state.removeFromShoppingList('p1');

      expect(state.shoppingListItems, isEmpty);
    });

    test('incrementQuantity() increases count by 1', () async {
      final state = await _makeState();
      await state.addToShoppingList(_p1);

      await state.incrementQuantity('p1');

      expect(state.getQuantity('p1'), 2);
    });

    test('decrementQuantity() decreases count by 1', () async {
      final state = await _makeState();
      await state.addToShoppingList(_p1);
      await state.incrementQuantity('p1'); // qty = 2

      await state.decrementQuantity('p1');

      expect(state.getQuantity('p1'), 1);
    });

    test('decrementQuantity() removes item when quantity reaches 0', () async {
      final state = await _makeState();
      await state.addToShoppingList(_p1); // qty = 1

      await state.decrementQuantity('p1');

      expect(state.shoppingListItems, isEmpty);
      expect(state.isInShoppingList('p1'), false);
    });

    test('clearShoppingList() empties all items', () async {
      final state = await _makeState();
      await state.addToShoppingList(_p1);
      await state.addToShoppingList(_p2);

      await state.clearShoppingList();

      expect(state.shoppingListItems, isEmpty);
    });

    test('isInShoppingList() returns correct value', () async {
      final state = await _makeState();
      await state.addToShoppingList(_p1);

      expect(state.isInShoppingList('p1'), true);
      expect(state.isInShoppingList('p2'), false);
    });

    test('shoppingListItemCount returns number of distinct items', () async {
      final state = await _makeState();
      await state.addToShoppingList(_p1);
      await state.addToShoppingList(_p1); // qty 2 — still 1 distinct item
      await state.addToShoppingList(_p2); // 2nd distinct item

      expect(state.shoppingListItemCount, 2);
    });

    test('shoppingListTotal returns sum of (price × quantity)', () async {
      final state = await _makeState();
      await state.addToShoppingList(_p1); // 1.29
      await state.addToShoppingList(_p3); // 2.49

      expect(state.shoppingListTotal, closeTo(3.78, 0.001));
    });
  });

  // ── Shopping list management ─────────────────────────────────────────────────

  group('shopping list management', () {
    test('initialize() creates default list when none exists', () async {
      final state = await _makeState();

      expect(state.lists.length, 1);
      expect(state.lists.first.name, 'Einkaufsliste');
    });

    test('createList() adds new list and makes it active', () async {
      final state = await _makeState();

      await state.createList('Urlaubsliste');

      expect(state.lists.length, 2);
      expect(state.activeList?.name, 'Urlaubsliste');
    });

    test('switchList() changes active list', () async {
      final state = await _makeState();
      final firstId = state.activeList!.id;
      await state.createList('Liste B');
      expect(state.activeList?.name, 'Liste B');

      await state.switchList(firstId);

      expect(state.activeList?.id, firstId);
    });

    test('renameList() updates active list name', () async {
      final state = await _makeState();
      final id = state.activeList!.id;

      await state.renameList(id, 'Wocheneinkauf');

      expect(state.activeList?.name, 'Wocheneinkauf');
    });

    test('deleteList() removes list and activates another', () async {
      final state = await _makeState();
      await state.renameList(state.activeList!.id, 'Liste A');
      await state.createList('Liste B');
      final secondId = state.activeList!.id;

      await state.deleteList(secondId);

      expect(state.lists.length, 1);
      expect(state.activeList?.name, 'Liste A');
    });

    test('deleteList() recreates default list when deleting the last list',
        () async {
      final state = await _makeState();
      final onlyId = state.activeList!.id;

      await state.deleteList(onlyId);

      expect(state.lists.length, 1);
      expect(state.lists.first.name, 'Einkaufsliste');
    });
  });

  // ── Favorites ────────────────────────────────────────────────────────────────

  group('favorites', () {
    test('toggleFavorite() adds product to favorites', () async {
      final state = await _makeState();

      await state.toggleFavorite(_p1);

      expect(state.isFavorite('p1'), true);
    });

    test('toggleFavorite() removes product already in favorites', () async {
      final state = await _makeState();
      await state.toggleFavorite(_p1);

      await state.toggleFavorite(_p1);

      expect(state.isFavorite('p1'), false);
    });

    test('favorites list contains the added product', () async {
      final state = await _makeState();

      await state.toggleFavorite(_p1);

      expect(state.favorites.first.id, 'p1');
    });

    test('favorites persists across re-initialization', () async {
      SharedPreferences.setMockInitialValues({});
      final fs = FakeFirebaseFirestore();
      final state1 = AppState(
        algoliaService: _MockAlgolia(_allProducts),
        priceAlertService: _MockAlerts(),
        shoppingListService: ShoppingListService(firestore: fs, getUid: () => 'test-uid'),
        favoritesService: FavoritesService(firestore: fs, getUid: () => 'test-uid'),
        analytics: const NoOpAnalyticsService(),
        authChanges: () => const Stream.empty(),
        getUid: () => 'test-uid',
      );
      await state1.initialize();
      await state1.toggleFavorite(_p1);

      final state2 = AppState(
        algoliaService: _MockAlgolia(_allProducts),
        priceAlertService: _MockAlerts(),
        shoppingListService: ShoppingListService(firestore: fs, getUid: () => 'test-uid'),
        favoritesService: FavoritesService(firestore: fs, getUid: () => 'test-uid'),
        analytics: const NoOpAnalyticsService(),
        authChanges: () => const Stream.empty(),
        getUid: () => 'test-uid',
      );
      await state2.initialize();

      expect(state2.isFavorite('p1'), true);
    });
  });

  // ── Price alerts ─────────────────────────────────────────────────────────────

  group('price alerts', () {
    test('setPriceAlert() creates alert and updates state', () async {
      final state = await _makeState();

      await state.setPriceAlert(
        product: _p1,
        alertType: AlertType.promotion,
      );

      expect(state.hasAlert('p1'), true);
      expect(state.priceAlerts.length, 1);
    });

    test('setPriceAlert() with targetPrice stores value correctly', () async {
      final state = await _makeState();

      await state.setPriceAlert(
        product: _p1,
        alertType: AlertType.targetPrice,
        targetPrice: 1.00,
      );

      expect(state.getAlert('p1')?.targetPrice, closeTo(1.00, 0.001));
    });

    test('removePriceAlert() removes alert', () async {
      final state = await _makeState();
      await state.setPriceAlert(product: _p1, alertType: AlertType.promotion);
      final alertId = state.getAlert('p1')!.id;

      await state.removePriceAlert(alertId, 'p1');

      expect(state.hasAlert('p1'), false);
    });

    test('setKeywordAlert() creates keyword alert', () async {
      final state = await _makeState();

      await state.setKeywordAlert(
        keyword: 'milch',
        alertType: AlertType.promotion,
      );

      expect(state.hasKeywordAlert('milch'), true);
    });

    test('removeKeywordAlert() removes keyword alert', () async {
      final state = await _makeState();
      await state.setKeywordAlert(
        keyword: 'milch',
        alertType: AlertType.promotion,
      );
      final alertId = state.getKeywordAlert('milch')!.id;

      await state.removeKeywordAlert(alertId, 'milch');

      expect(state.hasKeywordAlert('milch'), false);
    });

    test('initialize() loads existing alerts from service', () async {
      final preSeeded = [
        PriceAlert(
          id: 'alert-1',
          productId: 'p1',
          productName: 'Vollmilch 1L',
          supermarket: 'billa',
          currentPrice: 1.29,
          alertType: AlertType.promotion,
          createdAt: DateTime(2025, 1, 1),
        ),
        PriceAlert(
          id: 'alert-2',
          productId: '',
          productName: 'milch',
          supermarket: '',
          currentPrice: 0,
          alertType: AlertType.promotion,
          createdAt: DateTime(2025, 1, 2),
          scope: AlertScope.keyword,
          keyword: 'milch',
        ),
      ];

      final state = await _makeState(initialAlerts: preSeeded);

      expect(state.priceAlerts.length, 2);
    });
  });

  // ── Freemium gating ─────────────────────────────────────────────────────────

  group('freemium gating', () {
    test('monetization disabled: alerts stay unlimited', () async {
      final state = await _makeState(
        premiumService: _FakePremium(
          config: const PremiumConfig(monetizationEnabled: false, freeAlertLimit: 1),
        ),
      );

      await state.setKeywordAlert(keyword: 'milch', alertType: AlertType.promotion);
      await state.setKeywordAlert(keyword: 'butter', alertType: AlertType.promotion);

      expect(state.priceAlerts.length, 2);
      expect(state.canCreateAlert, isTrue);
    });

    test('free tier blocks alert creation past the limit', () async {
      final state = await _makeState(
        premiumService: _FakePremium(
          config: const PremiumConfig(monetizationEnabled: true, freeAlertLimit: 2),
        ),
      );

      await state.setKeywordAlert(keyword: 'milch', alertType: AlertType.promotion);
      await state.setKeywordAlert(keyword: 'butter', alertType: AlertType.promotion);

      expect(state.canCreateAlert, isFalse);
      expect(
        () => state.setKeywordAlert(keyword: 'brot', alertType: AlertType.promotion),
        throwsA(isA<PremiumRequiredException>()),
      );
      expect(state.priceAlerts.length, 2);
    });

    test('premium user bypasses the limit', () async {
      final state = await _makeState(
        premiumService: _FakePremium(
          config: const PremiumConfig(monetizationEnabled: true, freeAlertLimit: 1),
          premium: true,
        ),
      );

      await state.setKeywordAlert(keyword: 'milch', alertType: AlertType.promotion);
      await state.setKeywordAlert(keyword: 'butter', alertType: AlertType.promotion);

      expect(state.isPremium, isTrue);
      expect(state.priceAlerts.length, 2);
    });

    test('startPremiumPurchase unlocks and lifts the limit', () async {
      final premium = _FakePremium(
        config: const PremiumConfig(monetizationEnabled: true, freeAlertLimit: 1),
      );
      final state = await _makeState(premiumService: premium);

      await state.setKeywordAlert(keyword: 'milch', alertType: AlertType.promotion);
      expect(state.canCreateAlert, isFalse);

      final ok = await state.startPremiumPurchase();

      expect(ok, isTrue);
      expect(state.isPremium, isTrue);
      expect(state.canCreateAlert, isTrue);
      await state.setKeywordAlert(keyword: 'butter', alertType: AlertType.promotion);
      expect(state.priceAlerts.length, 2);
    });
  });
}
