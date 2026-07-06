import 'package:algoliasearch/algoliasearch.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';

enum SortOrder { relevance, unitPrice }

class SearchResult {
  final List<Product> products;
  final Map<String, int> categoryCounts;

  SearchResult({required this.products, required this.categoryCounts});
}

abstract class AlgoliaServiceBase {
  Future<SearchResult> searchProducts({
    required String query,
    Set<String>? supermarkets,
    String? category,
    SortOrder sortOrder = SortOrder.relevance,
    bool onlyPromotions = false,
    int hitsPerPage = 200,
  });
  void dispose();
}

class AlgoliaService implements AlgoliaServiceBase {
  static const String _applicationId = 'KRWOGKZ99N';
  static const String _apiKey = 'dbe6a272ef0c4fe8233baa8ed189914e';
  static const String _indexRelevance = 'products';
  static const String _indexUnitPrice = 'products_unitprice_asc';

  late final SearchClient _client;

  AlgoliaService() {
    _client = SearchClient(appId: _applicationId, apiKey: _apiKey);
  }

  @override
  Future<SearchResult> searchProducts({
    required String query,
    Set<String>? supermarkets,
    String? category,
    SortOrder sortOrder = SortOrder.relevance,
    bool onlyPromotions = false,
    int hitsPerPage = 200,
  }) async {
    if (query.trim().isEmpty) {
      return SearchResult(products: [], categoryCounts: {});
    }

    try {
      final filterParts = <String>[];

      if (supermarkets != null && supermarkets.isNotEmpty) {
        final supermarketFilters = supermarkets
            .map((s) => 'supermarket:"$s"')
            .join(' OR ');
        filterParts.add('($supermarketFilters)');
      }

      if (category != null && category.isNotEmpty) {
        filterParts.add('normalizedCategory:"$category"');
      }

      if (onlyPromotions) {
        filterParts.add('inPromotion:true');
      }

final filters = filterParts.isNotEmpty ? filterParts.join(' AND ') : null;
      final indexName = sortOrder == SortOrder.unitPrice ? _indexUnitPrice : _indexRelevance;

      final response = await _client.searchSingleIndex(
        indexName: indexName,
        searchParams: SearchParamsObject(
          query: query,
          hitsPerPage: hitsPerPage,
          filters: filters,
          facets: ['normalizedCategory', 'supermarket', 'inPromotion'],
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
          normalizedCategory: data['normalizedCategory'],
          nameLength: data['nameLength'],
          productUrl: data['productUrl'],
        );
      }).toList();

      final categoryCounts = <String, int>{};
      final facets = response.facets;
      if (facets != null && facets.containsKey('normalizedCategory')) {
        final categoryFacets = facets['normalizedCategory'];
        if (categoryFacets != null) {
          for (final entry in categoryFacets.entries) {
            categoryCounts[entry.key] = entry.value;
          }
        }
      }

      return SearchResult(products: products, categoryCounts: categoryCounts);
    } catch (e) {
      debugPrint('Algolia search error: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _client.dispose();
  }
}
