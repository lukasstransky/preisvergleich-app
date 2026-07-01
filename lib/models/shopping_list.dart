import 'shopping_list_item.dart';

class ShoppingList {
  final String id;
  final String name;
  final List<ShoppingListItem> items;
  final DateTime createdAt;

  const ShoppingList({
    required this.id,
    required this.name,
    required this.items,
    required this.createdAt,
  });

  ShoppingList copyWith({String? name, List<ShoppingListItem>? items}) => ShoppingList(
        id: id,
        name: name ?? this.name,
        items: items ?? this.items,
        createdAt: createdAt,
      );

  double get total => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  int get distinctItemCount => items.length;

  factory ShoppingList.fromJson(Map<String, dynamic> json) => ShoppingList(
        id: json['id'] as String,
        name: json['name'] as String,
        items: (json['items'] as List<dynamic>)
            .map((e) => ShoppingListItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': items.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };
}
