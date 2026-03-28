import 'package:algoliasearch/algoliasearch.dart';
import '../models/product.dart';

class AlgoliaService {
  static const String _applicationId = 'KRWOGKZ99N';
  static const String _apiKey = 'dbe6a272ef0c4fe8233baa8ed189914e';
  static const String _indexName = 'products';

  late final SearchClient _client;

  AlgoliaService() {
    _client = SearchClient(appId: _applicationId, apiKey: _apiKey);
  }

  Future<List<Product>> searchProducts({
    required String query,
    Set<String>? supermarkets,
    int hitsPerPage = 50,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      String? filters;
      if (supermarkets != null && supermarkets.isNotEmpty) {
        final supermarketFilters = supermarkets
            .map((s) => 'supermarket:"$s"')
            .join(' OR ');
        filters = supermarketFilters;
      }

      // TODO: Filter funktioniert erst wenn 'supermarket' in Algolia als Facet konfiguriert ist
      // Algolia Dashboard → Index → Configuration → Facets → supermarket hinzufügen
      final response = await _client.searchSingleIndex(
        indexName: _indexName,
        searchParams: SearchParamsObject(
          query: query,
          hitsPerPage: hitsPerPage,
          filters: filters,
        ),
      );

      final hits = response.hits;
      final products = hits.map((hit) {
        final data = hit.toJson();
        return Product(
          id: data['objectID'] ?? '',
          name: data['name'] ?? '',
          price: (data['price'] ?? 0).toDouble(),
          originalPrice: data['originalPrice']?.toDouble(),
          promotionText: data['promotionText'],
          unitPrice: data['unitPrice']?.toDouble(),
          unitLabel: data['unitLabel'],
          category: data['category'],
          brand: data['brand'],
          sku: data['sku'],
          inPromotion: data['inPromotion'] ?? false,
          imageUrl: data['imageUrl'],
          supermarket: data['supermarket'] ?? '',
        );
      }).toList();

      products.sort((a, b) => a.price.compareTo(b.price));

      return products;
    } catch (e) {
      print('Algolia search error: $e');
      rethrow;
    }
  }

  void dispose() {
    _client.dispose();
  }
}
