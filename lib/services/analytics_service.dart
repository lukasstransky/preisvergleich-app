import 'package:firebase_analytics/firebase_analytics.dart';

abstract class AnalyticsServiceBase {
  Future<void> logSearch(String query, int resultCount);
  Future<void> logProductViewed(String productId, String supermarket, bool inPromotion);
  Future<void> logProductLinkOpened(String productId, String supermarket);
  Future<void> logAddToShoppingList(String productId, String supermarket);
  Future<void> logAddToFavorites(String productId, String supermarket);
  Future<void> logRemoveFromFavorites(String productId);
  Future<void> logPriceAlertCreated(String type); // 'product' | 'keyword'
  Future<void> logPaywallShown(String feature);
  Future<void> logPremiumPurchased();
}

class AnalyticsService implements AnalyticsServiceBase {
  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  @override
  Future<void> logSearch(String query, int resultCount) async {
    // Built-in `search` event powers Firebase's standard funnels…
    await _analytics.logSearch(searchTerm: query);
    // …the custom event carries the result count so we can spot searches that
    // return nothing — the clearest signal of gaps in our product data.
    await _analytics.logEvent(
      name: 'search_performed',
      parameters: {'query': query, 'result_count': resultCount},
    );
  }

  @override
  Future<void> logProductViewed(
          String productId, String supermarket, bool inPromotion) =>
      _analytics.logEvent(
        name: 'product_viewed',
        parameters: {
          'product_id': productId,
          'supermarket': supermarket,
          'in_promotion': inPromotion ? 1 : 0,
        },
      );

  @override
  Future<void> logProductLinkOpened(String productId, String supermarket) =>
      _analytics.logEvent(
        name: 'product_link_opened',
        parameters: {'product_id': productId, 'supermarket': supermarket},
      );

  @override
  Future<void> logAddToShoppingList(String productId, String supermarket) =>
      _analytics.logEvent(
        name: 'add_to_shopping_list',
        parameters: {'product_id': productId, 'supermarket': supermarket},
      );

  @override
  Future<void> logAddToFavorites(String productId, String supermarket) =>
      _analytics.logEvent(
        name: 'add_to_favorites',
        parameters: {'product_id': productId, 'supermarket': supermarket},
      );

  @override
  Future<void> logRemoveFromFavorites(String productId) =>
      _analytics.logEvent(
        name: 'remove_from_favorites',
        parameters: {'product_id': productId},
      );

  @override
  Future<void> logPriceAlertCreated(String type) =>
      _analytics.logEvent(
        name: 'price_alert_created',
        parameters: {'type': type},
      );

  @override
  Future<void> logPaywallShown(String feature) =>
      _analytics.logEvent(
        name: 'paywall_shown',
        parameters: {'feature': feature},
      );

  @override
  Future<void> logPremiumPurchased() =>
      _analytics.logEvent(name: 'premium_purchased');
}

class NoOpAnalyticsService implements AnalyticsServiceBase {
  const NoOpAnalyticsService();

  @override Future<void> logSearch(String query, int resultCount) async {}
  @override Future<void> logProductViewed(String p, String s, bool inPromo) async {}
  @override Future<void> logProductLinkOpened(String p, String s) async {}
  @override Future<void> logAddToShoppingList(String p, String s) async {}
  @override Future<void> logAddToFavorites(String p, String s) async {}
  @override Future<void> logRemoveFromFavorites(String p) async {}
  @override Future<void> logPriceAlertCreated(String type) async {}
  @override Future<void> logPaywallShown(String feature) async {}
  @override Future<void> logPremiumPurchased() async {}
}
