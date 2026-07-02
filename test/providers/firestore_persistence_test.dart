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

class _NoOpAlgolia implements AlgoliaServiceBase {
  @override
  Future<SearchResult> searchProducts({
    required String query,
    Set<String>? supermarkets,
    String? category,
    SortOrder sortOrder = SortOrder.relevance,
    bool onlyPromotions = false,
    int hitsPerPage = 200,
  }) async => SearchResult(products: [], categoryCounts: {});

  @override
  void dispose() {}
}

class _NoOpAlerts implements PriceAlertServiceBase {
  @override
  Future<List<PriceAlert>> getAlerts() async => [];
  @override
  Future<void> createAlert({required Product product, required AlertType alertType, double? targetPrice}) async {}
  @override
  Future<void> createKeywordAlert({required String keyword, required AlertType alertType, double? targetPrice, String? category}) async {}
  @override
  Future<void> deleteAlert(String alertId) async {}
}

AppState _makeState(FakeFirebaseFirestore firestore, String uid) {
  SharedPreferences.setMockInitialValues({});
  return AppState(
    algoliaService: _NoOpAlgolia(),
    priceAlertService: _NoOpAlerts(),
    shoppingListService: ShoppingListService(firestore: firestore, getUid: () => uid),
    favoritesService: FavoritesService(firestore: firestore, getUid: () => uid),
    authChanges: () => const Stream.empty(),
    getUid: () => uid,
  );
}

Product _product(String id) => Product(
      id: id,
      name: 'Produkt $id',
      price: 1.0,
      inPromotion: false,
      supermarket: 'spar',
    );

void main() {
  group('Firestore persistence', () {
    test('shopping list survives app restart (same uid)', () async {
      final firestore = FakeFirebaseFirestore();

      // First "launch" — initialize() creates a default list, then we rename it
      final state1 = _makeState(firestore, 'uid-1');
      await state1.initialize();
      await state1.renameList(state1.lists.first.id, 'Wocheneinkauf');

      // Second "launch" — fresh AppState, same Firestore (= same device)
      final state2 = _makeState(firestore, 'uid-1');
      await state2.initialize();
      expect(state2.lists.length, 1);
      expect(state2.lists.first.name, 'Wocheneinkauf');
    });

    test('favorites survive app restart (same uid)', () async {
      final firestore = FakeFirebaseFirestore();

      final state1 = _makeState(firestore, 'uid-1');
      await state1.initialize();
      await state1.toggleFavorite(_product('p1'));
      expect(state1.favorites.length, 1);

      final state2 = _makeState(firestore, 'uid-1');
      await state2.initialize();
      expect(state2.favorites.length, 1);
      expect(state2.favorites.first.id, 'p1');
    });

    test('shopping list items are added and persisted', () async {
      final firestore = FakeFirebaseFirestore();
      final state = _makeState(firestore, 'uid-1');
      await state.initialize();

      final product = _product('p42');
      await state.addToShoppingList(product);
      expect(state.shoppingListItemCount, 1);

      final state2 = _makeState(firestore, 'uid-1');
      await state2.initialize();
      expect(state2.shoppingListItemCount, 1);
      expect(state2.shoppingListItems.first.product.id, 'p42');
    });

    test('data is isolated between different uids', () async {
      final firestore = FakeFirebaseFirestore();

      final stateA = _makeState(firestore, 'uid-a');
      await stateA.initialize();
      await stateA.createList('Liste von A');
      await stateA.toggleFavorite(_product('p1'));

      final stateB = _makeState(firestore, 'uid-b');
      await stateB.initialize();
      // uid-b gets a default list, but not the one created by uid-a
      expect(stateB.lists.every((l) => l.name != 'Liste von A'), true);
      expect(stateB.favorites, isEmpty);
    });

    test('initialize() is idempotent for same uid', () async {
      final firestore = FakeFirebaseFirestore();
      final state = _makeState(firestore, 'uid-1');

      await state.initialize();
      await state.createList('Nur einmal');

      // Second initialize() with same uid should be a no-op
      await state.initialize();
      // Still only the default list + the one we created
      expect(state.lists.any((l) => l.name == 'Nur einmal'), true);
    });

    test('new uid gets fresh empty state after re-init', () async {
      final firestore = FakeFirebaseFirestore();

      final state = _makeState(firestore, 'uid-anon-1');
      await state.initialize();
      await state.createList('Meine Liste');

      // Simulate sign-out → new anonymous user → different uid
      // (in production this triggers via authStateChanges listener)
      final stateNew = _makeState(firestore, 'uid-anon-2');
      await stateNew.initialize();

      expect(stateNew.lists.every((l) => l.name != 'Meine Liste'), true);
    });
  });
}
