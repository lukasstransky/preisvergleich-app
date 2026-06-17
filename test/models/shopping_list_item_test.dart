import 'package:flutter_test/flutter_test.dart';
import 'package:preisvergleich_app/models/product.dart';
import 'package:preisvergleich_app/models/shopping_list_item.dart';

Product _product({double price = 1.0}) => Product(
      id: 'p1',
      name: 'Milch',
      price: price,
      inPromotion: false,
      supermarket: 'spar',
    );

void main() {
  group('ShoppingListItem', () {
    test('default quantity is 1', () {
      final item = ShoppingListItem(product: _product());
      expect(item.quantity, 1);
    });

    test('totalPrice equals price * quantity', () {
      final item = ShoppingListItem(product: _product(price: 2.5), quantity: 3);
      expect(item.totalPrice, 7.5);
    });

    test('totalPrice with quantity 1', () {
      final item = ShoppingListItem(product: _product(price: 1.99));
      expect(item.totalPrice, 1.99);
    });

    test('copyWith updates quantity', () {
      final item = ShoppingListItem(product: _product(), quantity: 1);
      final updated = item.copyWith(quantity: 5);
      expect(updated.quantity, 5);
      expect(updated.product.id, item.product.id);
    });

    test('copyWith without arguments keeps current values', () {
      final item = ShoppingListItem(product: _product(price: 3.0), quantity: 2);
      final copy = item.copyWith();
      expect(copy.quantity, 2);
      expect(copy.product.price, 3.0);
    });

    test('fromJson / toJson round-trip preserves quantity and product', () {
      final item = ShoppingListItem(product: _product(price: 3.0), quantity: 4);
      final rt = ShoppingListItem.fromJson(item.toJson());
      expect(rt.quantity, 4);
      expect(rt.product.price, 3.0);
      expect(rt.product.id, 'p1');
    });

    test('fromJson defaults quantity to 1 when key is absent', () {
      final json = {'product': _product().toJson()};
      expect(ShoppingListItem.fromJson(json).quantity, 1);
    });
  });
}
