import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/app_state.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

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
    final isInList = appState.isInShoppingList(product.id);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showProductDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductImage(),
              const SizedBox(width: 12),
              Expanded(child: _buildProductInfo()),
              _buildActionButton(context, isInList),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 80,
        height: 80,
        child: product.imageUrl != null
            ? CachedNetworkImage(
                imageUrl: product.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.shopping_basket, color: Colors.grey),
                ),
              )
            : Container(
                color: Colors.grey[200],
                child: const Icon(Icons.shopping_basket, color: Colors.grey),
              ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _getSupermarketColor(product.supermarket),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            product.supermarketDisplayName,
            style: TextStyle(
              color: product.supermarket.toLowerCase() == 'billa' 
                  ? Colors.black 
                  : Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (product.brand != null) ...[
          const SizedBox(height: 2),
          Text(
            product.brand!,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              product.formattedPrice,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: product.inPromotion ? Colors.red : Colors.black,
              ),
            ),
            if (product.originalPrice != null) ...[
              const SizedBox(width: 6),
              Text(
                product.formattedOriginalPrice!,
                style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        if (product.formattedUnitPrice != null)
          Text(
            product.formattedUnitPrice!,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, bool isInList) {
    return IconButton(
      icon: Icon(
        isInList ? Icons.check_circle : Icons.add_circle_outline,
        color: isInList ? Colors.green : Theme.of(context).primaryColor,
        size: 28,
      ),
      onPressed: () {
        final appState = context.read<AppState>();
        if (isInList) {
          appState.removeFromShoppingList(product.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} entfernt'),
              duration: const Duration(seconds: 1),
            ),
          );
        } else {
          appState.addToShoppingList(product);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} zur Liste hinzugefügt'),
              duration: const Duration(seconds: 1),
              action: SnackBarAction(
                label: 'Rückgängig',
                onPressed: () => appState.removeFromShoppingList(product.id),
              ),
            ),
          );
        }
      },
    );
  }

  void _showProductDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (product.imageUrl != null)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl!,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (product.brand != null)
              Text('Marke: ${product.brand}'),
            if (product.category != null)
              Text('Kategorie: ${product.category}'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.formattedPrice,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (product.formattedUnitPrice != null)
                      Text(
                        product.formattedUnitPrice!,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getSupermarketColor(product.supermarket),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    product.supermarketDisplayName,
                    style: TextStyle(
                      color: product.supermarket.toLowerCase() == 'billa' 
                          ? Colors.black 
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
