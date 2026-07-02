import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preisvergleich_app/models/product.dart';
import 'package:preisvergleich_app/services/favorites_service.dart';

const _uid = 'test-uid';

Product _product(String id, String name, {double price = 1.0}) => Product(
      id: id,
      name: name,
      price: price,
      inPromotion: false,
      supermarket: 'spar',
    );

FavoritesService _makeService(FakeFirebaseFirestore firestore) =>
    FavoritesService(firestore: firestore, getUid: () => _uid);

void main() {
  group('FavoritesService (Firestore)', () {
    late FakeFirebaseFirestore firestore;
    late FavoritesService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = _makeService(firestore);
    });

    test('getFavorites returns empty list initially', () async {
      expect(await service.getFavorites(), isEmpty);
    });

    test('saveFavorites persists products', () async {
      await service.saveFavorites([
        _product('p1', 'Milch'),
        _product('p2', 'Butter'),
      ]);
      final loaded = await service.getFavorites();
      expect(loaded.length, 2);
      expect(loaded[0].id, 'p1');
      expect(loaded[1].id, 'p2');
    });

    test('saveFavorites with empty list clears favorites', () async {
      await service.saveFavorites([_product('p1', 'Milch')]);
      await service.saveFavorites([]);
      expect(await service.getFavorites(), isEmpty);
    });

    test('overwriting favorites replaces previous data', () async {
      await service.saveFavorites([_product('p1', 'Milch')]);
      await service.saveFavorites([_product('p2', 'Butter')]);
      final loaded = await service.getFavorites();
      expect(loaded.length, 1);
      expect(loaded.first.id, 'p2');
    });

    test('round-trip preserves all product fields', () async {
      final product = Product(
        id: 'p99',
        name: 'Käse',
        price: 3.49,
        originalPrice: 4.99,
        promotionText: '30% Rabatt',
        unitPrice: 6.98,
        unitLabel: 'kg',
        inPromotion: true,
        supermarket: 'billa',
        brand: 'Lattella',
        category: 'Molkerei',
        sku: 'SKU-K',
        imageUrl: 'https://example.com/kaese.jpg',
      );
      await service.saveFavorites([product]);
      final p = (await service.getFavorites()).first;
      expect(p.id, 'p99');
      expect(p.name, 'Käse');
      expect(p.price, 3.49);
      expect(p.originalPrice, 4.99);
      expect(p.promotionText, '30% Rabatt');
      expect(p.unitPrice, 6.98);
      expect(p.unitLabel, 'kg');
      expect(p.inPromotion, true);
      expect(p.supermarket, 'billa');
      expect(p.brand, 'Lattella');
      expect(p.category, 'Molkerei');
      expect(p.sku, 'SKU-K');
      expect(p.imageUrl, 'https://example.com/kaese.jpg');
    });

    test('favorites are isolated per uid', () async {
      final serviceA = FavoritesService(firestore: firestore, getUid: () => 'uid-a');
      final serviceB = FavoritesService(firestore: firestore, getUid: () => 'uid-b');

      await serviceA.saveFavorites([_product('p1', 'Milch')]);
      expect(await serviceB.getFavorites(), isEmpty);
    });

    test('data persists when new service instance reads same uid', () async {
      await service.saveFavorites([_product('p1', 'Milch')]);

      final service2 = _makeService(firestore);
      final loaded = await service2.getFavorites();
      expect(loaded.length, 1);
      expect(loaded.first.id, 'p1');
    });
  });
}
