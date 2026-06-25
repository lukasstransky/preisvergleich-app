import 'package:preisvergleich_app/models/price_alert.dart';
import 'package:preisvergleich_app/models/product.dart';
import 'package:preisvergleich_app/services/price_alert_service.dart';

class MockPriceAlertService implements PriceAlertServiceBase {
  final List<PriceAlert> _alerts;

  MockPriceAlertService({List<PriceAlert>? initialAlerts})
      : _alerts = List.from(initialAlerts ?? []);

  @override
  Future<List<PriceAlert>> getAlerts() async => List.from(_alerts);

  @override
  Future<void> createAlert({
    required Product product,
    required AlertType alertType,
    double? targetPrice,
  }) async {
    _alerts.add(PriceAlert(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      productId: product.id,
      productName: product.name,
      supermarket: product.supermarket,
      imageUrl: product.imageUrl,
      currentPrice: product.price,
      alertType: alertType,
      targetPrice: targetPrice,
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<void> createKeywordAlert({
    required String keyword,
    required AlertType alertType,
    double? targetPrice,
    String? category,
  }) async {
    _alerts.add(PriceAlert(
      id: 'mock-kw-${DateTime.now().millisecondsSinceEpoch}',
      productId: '',
      productName: keyword,
      supermarket: '',
      currentPrice: 0,
      alertType: alertType,
      targetPrice: targetPrice,
      createdAt: DateTime.now(),
      scope: AlertScope.keyword,
      keyword: keyword.toLowerCase(),
    ));
  }

  @override
  Future<void> deleteAlert(String alertId) async {
    _alerts.removeWhere((a) => a.id == alertId);
  }
}
