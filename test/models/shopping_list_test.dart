import 'package:flutter_test/flutter_test.dart';
import 'package:preisvergleich_app/models/product.dart';
import 'package:preisvergleich_app/models/shopping_list.dart';
import 'package:preisvergleich_app/models/shopping_list_item.dart';

ShoppingListItem _item(double price, int quantity) => ShoppingListItem(
      product: Product(
        id: 'p',
        name: 'n',
        price: price,
        inPromotion: false,
        supermarket: 'spar',
      ),
      quantity: quantity,
    );

ShoppingList _makeList({List<ShoppingListItem> items = const []}) => ShoppingList(
      id: 'list1',
      name: 'Meine Liste',
      items: items,
      createdAt: DateTime(2024, 1, 15),
    );

void main() {
  group('ShoppingList.total', () {
    test('is 0.0 for empty list', () {
      expect(_makeList().total, 0.0);
    });

    test('sums all item totalPrices', () {
      final list = _makeList(items: [_item(2.0, 3), _item(1.5, 2)]);
      expect(list.total, 9.0); // 6.0 + 3.0
    });

    test('handles single item', () {
      expect(_makeList(items: [_item(4.99, 1)]).total, 4.99);
    });
  });

  group('ShoppingList.itemCount', () {
    test('is 0 for empty list', () {
      expect(_makeList().itemCount, 0);
    });

    test('sums quantities across all items', () {
      final list = _makeList(items: [_item(1.0, 2), _item(1.0, 5)]);
      expect(list.itemCount, 7);
    });
  });

  group('ShoppingList.copyWith', () {
    test('updates name', () {
      final updated = _makeList().copyWith(name: 'Neue Liste');
      expect(updated.name, 'Neue Liste');
      expect(updated.id, 'list1');
    });

    test('updates items', () {
      final newItems = [_item(1.0, 1)];
      final updated = _makeList().copyWith(items: newItems);
      expect(updated.items.length, 1);
      expect(updated.name, 'Meine Liste');
    });

    test('preserves unchanged fields', () {
      final list = _makeList(items: [_item(1.0, 1)]);
      final updated = list.copyWith(name: 'X');
      expect(updated.items.length, 1);
      expect(updated.createdAt, DateTime(2024, 1, 15));
    });
  });

  group('ShoppingList fromJson / toJson round-trip', () {
    test('preserves all fields', () {
      final list = _makeList(items: [_item(1.99, 2)]);
      final rt = ShoppingList.fromJson(list.toJson());
      expect(rt.id, 'list1');
      expect(rt.name, 'Meine Liste');
      expect(rt.createdAt, DateTime(2024, 1, 15));
      expect(rt.items.length, 1);
      expect(rt.items.first.quantity, 2);
      expect(rt.items.first.product.price, 1.99);
    });

    test('empty items list survives round-trip', () {
      final rt = ShoppingList.fromJson(_makeList().toJson());
      expect(rt.items, isEmpty);
    });

    test('multiple items survive round-trip', () {
      final list = _makeList(items: [_item(1.0, 1), _item(2.0, 3)]);
      final rt = ShoppingList.fromJson(list.toJson());
      expect(rt.items.length, 2);
      expect(rt.total, list.total);
      expect(rt.itemCount, list.itemCount);
    });
  });
}
