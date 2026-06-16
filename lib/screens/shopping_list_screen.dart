import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_state.dart';
import '../models/shopping_list_item.dart';
import 'shopping_lists_screen.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final Set<String> _checkedItems = {};

  void _toggle(String productId) {
    setState(() {
      if (_checkedItems.contains(productId)) {
        _checkedItems.remove(productId);
      } else {
        _checkedItems.add(productId);
      }
    });
  }

  Color _getSupermarketColor(String supermarket) {
    switch (supermarket.toLowerCase()) {
      case 'spar':   return const Color(0xFF006633);
      case 'billa':  return const Color(0xFFFFCC00);
      case 'hofer':  return const Color(0xFF004A99);
      case 'penny':  return const Color(0xFFCD1719);
      case 'lidl':   return const Color(0xFF0050AA);
      case 'mpreis': return const Color(0xFFE30613);
      default:       return Colors.grey;
    }
  }

  bool _useDarkText(String supermarket) => supermarket.toLowerCase() == 'billa';

  String _displayName(String supermarket) {
    switch (supermarket.toLowerCase()) {
      case 'spar':   return 'Spar';
      case 'billa':  return 'Billa';
      case 'hofer':  return 'Hofer';
      case 'penny':  return 'Penny';
      case 'lidl':   return 'Lidl';
      case 'mpreis': return 'MPreis';
      default:       return supermarket;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final list = appState.activeList;
    final items = appState.shoppingListItems;
    final checkedCount = _checkedItems.intersection(items.map((i) => i.product.id).toSet()).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(list?.name ?? 'Einkaufsliste'),
        centerTitle: true,
        actions: [
          if (_checkedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Abhaken zurücksetzen',
              onPressed: () => setState(() => _checkedItems.clear()),
            ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Alle Listen',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShoppingListsScreen()),
            ),
          ),
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showClearConfirmation(context, appState),
            ),
        ],
      ),
      body: items.isEmpty
          ? _buildEmptyState()
          : _buildBody(context, appState, items),
      bottomNavigationBar: items.isNotEmpty
          ? _buildTotalBar(appState, checkedCount, items.length)
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
          Text('Einkaufsliste ist leer',
              style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Füge Produkte über die Suche hinzu',
              style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppState appState, List<ShoppingListItem> items) {
    final grouped = _groupBySupermarket(items);
    final supermarkets = grouped.keys.toList();

    // unchecked first, checked at bottom within each supermarket group
    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: supermarkets.map((supermarket) {
        final allItems = grouped[supermarket]!;
        final unchecked = allItems.where((i) => !_checkedItems.contains(i.product.id)).toList();
        final checked = allItems.where((i) => _checkedItems.contains(i.product.id)).toList();
        final subtotal = unchecked.fold<double>(0, (s, i) => s + i.totalPrice);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSupermarketHeader(supermarket, allItems.length, subtotal),
            ...unchecked.map((item) => _buildItemTile(context, item, appState, false)),
            ...checked.map((item) => _buildItemTile(context, item, appState, true)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSupermarketHeader(String supermarket, int count, double subtotal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: _getSupermarketColor(supermarket).withValues(alpha: 0.1),
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
                _displayName(supermarket),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text('($count)', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          Text('€${subtotal.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildItemTile(
      BuildContext context, ShoppingListItem item, AppState appState, bool isChecked) {
    return Dismissible(
      key: Key(item.product.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        _checkedItems.remove(item.product.id);
        appState.removeFromShoppingList(item.product.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.product.name} entfernt'),
            action: SnackBarAction(
              label: 'Rückgängig',
              onPressed: () => appState.addToShoppingList(item.product),
            ),
          ),
        );
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isChecked ? 0.45 : 1.0,
        child: InkWell(
          onTap: () => _toggle(item.product.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Checkbox indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isChecked
                        ? const Color(0xFF1B8A5A)
                        : Colors.transparent,
                    border: Border.all(
                      color: isChecked
                          ? const Color(0xFF1B8A5A)
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: isChecked
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 10),
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 46,
                    height: 46,
                    child: item.product.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: item.product.imageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.shopping_basket, size: 22),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.shopping_basket, size: 22),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                // Name + brand
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          decoration: isChecked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (item.product.brand != null)
                        Text(
                          item.product.brand!,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                    ],
                  ),
                ),
                // Price + quantity controls
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '€${item.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        if (item.quantity > 1)
                          Text(
                            '${item.quantity} × €${item.product.price.toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.grey[500], fontSize: 11),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    if (!isChecked) _buildQuantityControls(item, appState),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityControls(ShoppingListItem item, AppState appState) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => appState.decrementQuantity(item.product.id),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                item.quantity == 1 ? Icons.delete_outline : Icons.remove,
                size: 18,
                color: item.quantity == 1 ? Colors.red : Colors.grey[700],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('${item.quantity}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          GestureDetector(
            onTap: () => appState.incrementQuantity(item.product.id),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.add, size: 18, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBar(AppState appState, int checkedCount, int totalCount) {
    final remaining = totalCount - checkedCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
                  checkedCount == 0
                      ? '${appState.shoppingListItemCount} Artikel'
                      : '$checkedCount von $totalCount erledigt',
                  style: TextStyle(
                    color: checkedCount > 0
                        ? const Color(0xFF1B8A5A)
                        : Colors.grey[600],
                    fontSize: 13,
                    fontWeight: checkedCount > 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                Text(
                  remaining == 0 && checkedCount > 0
                      ? 'Alles eingekauft! 🎉'
                      : 'Gesamtsumme',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            Text(
              '€${appState.shoppingListTotal.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<ShoppingListItem>> _groupBySupermarket(List<ShoppingListItem> items) {
    final grouped = <String, List<ShoppingListItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.product.supermarket.toLowerCase(), () => []).add(item);
    }
    return grouped;
  }

  void _showClearConfirmation(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Liste leeren?'),
        content: const Text('Möchtest du alle Produkte aus der Liste entfernen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              _checkedItems.clear();
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
