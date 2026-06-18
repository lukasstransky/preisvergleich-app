import 'package:preisvergleich_app/services/algolia_service.dart';
import 'test_data.dart';

class MockAlgoliaService implements AlgoliaServiceBase {
  @override
  Future<SearchResult> searchProducts({
    required String query,
    Set<String>? supermarkets,
    String? category,
    SortOrder sortOrder = SortOrder.relevance,
    bool onlyPromotions = false,
    int hitsPerPage = 200,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));

    if (query.trim().isEmpty) {
      return SearchResult(products: [], categoryCounts: {});
    }

    final q = query.toLowerCase();
    var results = testProducts.where((p) {
      final matchesQuery = p.name.toLowerCase().contains(q) ||
          (p.category?.toLowerCase().contains(q) ?? false);
      final matchesSupermarket = supermarkets == null ||
          supermarkets.isEmpty ||
          supermarkets.contains(p.supermarket);
      final matchesCategory =
          category == null || p.normalizedCategory == category;
      final matchesPromotion = !onlyPromotions || p.inPromotion;
      return matchesQuery && matchesSupermarket && matchesCategory && matchesPromotion;
    }).toList();

    if (sortOrder == SortOrder.unitPrice) {
      results.sort(
          (a, b) => (a.unitPrice ?? a.price).compareTo(b.unitPrice ?? b.price));
    }

    final categoryCounts = <String, int>{};
    for (final p in results) {
      if (p.normalizedCategory != null) {
        categoryCounts[p.normalizedCategory!] =
            (categoryCounts[p.normalizedCategory!] ?? 0) + 1;
      }
    }

    return SearchResult(products: results, categoryCounts: categoryCounts);
  }

  @override
  void dispose() {}
}
