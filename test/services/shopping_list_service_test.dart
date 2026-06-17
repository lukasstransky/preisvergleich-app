import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:preisvergleich_app/models/product.dart';
import 'package:preisvergleich_app/models/shopping_list.dart';
import 'package:preisvergleich_app/models/shopping_list_item.dart';
import 'package:preisvergleich_app/services/shopping_list_service.dart';

Product _product() => Product(
      id: 'p1',
      name: 'Milch',
      price: 1.29,
      inPromotion: false,
      supermarket: 'spar',
    );

void main() {
  late ShoppingListService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = ShoppingListService();
  });

  group('ShoppingListService', () {
    test('getAllLists returns empty list initially', () async {
      expect(await service.getAllLists(), isEmpty);
    });

    test('createList creates and persists a list', () async {
      final list = await service.createList('Einkauf');
      expect(list.name, 'Einkauf');
      expect(list.items, isEmpty);
      expect(list.id, isNotEmpty);

      final all = await service.getAllLists();
      expect(all.length, 1);
      expect(all.first.name, 'Einkauf');
    });

    test('createList sets the active list id', () async {
      final list = await service.createList('Wocheneinkauf');
      expect(await service.getActiveListId(), list.id);
    });

    test('multiple createList calls accumulate lists', () async {
      await service.createList('Liste A');
      await service.createList('Liste B');
      expect((await service.getAllLists()).length, 2);
    });

    test('deleteList removes the correct list', () async {
      final a = await service.createList('Liste A');
      // Delay ensures millisecondsSinceEpoch IDs are distinct.
      await Future.delayed(const Duration(milliseconds: 2));
      await service.createList('Liste B');
      await service.deleteList(a.id);
      final all = await service.getAllLists();
      expect(all.length, 1);
      expect(all.first.name, 'Liste B');
    });

    test('deleteList on only list leaves empty storage', () async {
      final list = await service.createList('Zu löschen');
      await service.deleteList(list.id);
      expect(await service.getAllLists(), isEmpty);
    });

    test('updateList updates an existing list', () async {
      final list = await service.createList('Alt');
      final item = ShoppingListItem(product: _product(), quantity: 2);
      await service.updateList(list.copyWith(name: 'Neu', items: [item]));

      final all = await service.getAllLists();
      expect(all.length, 1);
      expect(all.first.name, 'Neu');
      expect(all.first.items.length, 1);
      expect(all.first.items.first.quantity, 2);
    });

    test('updateList inserts if id is not found', () async {
      final orphan = ShoppingList(
        id: 'nonexistent',
        name: 'Orphan',
        items: [],
        createdAt: DateTime.now(),
      );
      await service.updateList(orphan);
      final all = await service.getAllLists();
      expect(all.any((l) => l.id == 'nonexistent'), true);
    });

    test('setActiveListId / getActiveListId round-trip', () async {
      await service.setActiveListId('abc123');
      expect(await service.getActiveListId(), 'abc123');
    });

    test('getActiveListId returns null when not set', () async {
      expect(await service.getActiveListId(), isNull);
    });
  });
}
