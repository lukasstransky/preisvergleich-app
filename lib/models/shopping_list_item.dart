import 'product.dart';

class ShoppingListItem {
  final Product product;
  final int quantity;

  const ShoppingListItem({required this.product, this.quantity = 1});

  ShoppingListItem copyWith({int? quantity}) =>
      ShoppingListItem(product: product, quantity: quantity ?? this.quantity);

  double get totalPrice => product.price * quantity;

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) => ShoppingListItem(
        product: Product.fromJson(json['product'] as Map<String, dynamic>),
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'quantity': quantity,
      };
}
