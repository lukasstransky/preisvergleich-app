import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_state.dart';
import '../models/product.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  Color _getSupermarketColor(String supermarket) {
    switch (supermarket.toLowerCase()) {
      case 'spar':
        return const Color(0xFF006633);
      case 'billa':
        return const Color(0xFFFFCC00);
      case 'hofer':
        return const Color(0xFF004A99);
      case 'penny':
        return const Color(0xFFCD1719);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einkaufsliste'),
        centerTitle: true,
        actions: [
          if (appState.shoppingList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showClearConfirmation(context, appState),
            ),
        ],
      ),
      body: appState.shoppingList.isEmpty
          ? _buildEmptyState()
          : _buildShoppingList(context, appState),
      bottomNavigationBar: appState.shoppingList.isNotEmpty
          ? _buildTotalBar(appState)
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Deine Einkaufsliste ist leer',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Füge Produkte über die Suche hinzu',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingList(BuildContext context, AppState appState) {
    final groupedProducts = _groupBySupermarket(appState.shoppingList);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: groupedProducts.length,
      itemBuilder: (context, index) {
        final supermarket = groupedProducts.keys.elementAt(index);
        final products = groupedProducts[supermarket]!;
        final supermarketTotal = products.fold<double>(
          0, (sum, p) => sum + p.price,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: _getSupermarketColor(supermarket).withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getSupermarketColor(supermarket),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getSupermarketDisplayName(supermarket),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${products.length})',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  Text(
                    '€${supermarketTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ...products.map((product) => _buildProductTile(context, product, appState)),
          ],
        );
      },
    );
  }

  Widget _buildProductTile(BuildContext context, Product product, AppState appState) {
    return Dismissible(
      key: Key(product.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        appState.removeFromShoppingList(product.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} entfernt'),
            action: SnackBarAction(
              label: 'Rückgängig',
              onPressed: () => appState.addToShoppingList(product),
            ),
          ),
        );
      },
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 50,
            height: 50,
            child: product.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: product.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.shopping_basket, size: 24),
                    ),
                  )
                : Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.shopping_basket, size: 24),
                  ),
          ),
        ),
        title: Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: product.brand != null 
            ? Text(product.brand!, style: TextStyle(color: Colors.grey[600]))
            : null,
        trailing: Text(
          product.formattedPrice,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildTotalBar(AppState appState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${appState.shoppingList.length} Produkte',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                const Text(
                  'Gesamtsumme',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Text(
              '€${appState.shoppingListTotal.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<Product>> _groupBySupermarket(List<Product> products) {
    final grouped = <String, List<Product>>{};
    for (final product in products) {
      final key = product.supermarket.toLowerCase();
      grouped.putIfAbsent(key, () => []).add(product);
    }
    return grouped;
  }

  String _getSupermarketDisplayName(String supermarket) {
    switch (supermarket.toLowerCase()) {
      case 'spar':
        return 'Spar';
      case 'billa':
        return 'Billa';
      case 'hofer':
        return 'Hofer';
      case 'penny':
        return 'Penny';
      default:
        return supermarket;
    }
  }

  void _showClearConfirmation(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Liste leeren?'),
        content: const Text('Möchtest du alle Produkte aus der Einkaufsliste entfernen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              appState.clearShoppingList();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leeren'),
          ),
        ],
      ),
    );
  }
}
