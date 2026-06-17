import 'package:flutter_test/flutter_test.dart';
import 'package:preisvergleich_app/models/price_alert.dart';

PriceAlert _makeAlert({
  AlertType alertType = AlertType.promotion,
  double? targetPrice,
  AlertScope scope = AlertScope.product,
  String? keyword,
}) =>
    PriceAlert(
      id: 'alert1',
      productId: 'p1',
      productName: 'Milch',
      supermarket: 'spar',
      currentPrice: 1.29,
      alertType: alertType,
      targetPrice: targetPrice,
      createdAt: DateTime(2024, 1, 1),
      scope: scope,
      keyword: keyword,
    );

void main() {
  group('PriceAlert.alertDescription', () {
    test('returns "Bei Angebot" for promotion type', () {
      expect(_makeAlert().alertDescription, 'Bei Angebot');
    });

    test('returns formatted target price for targetPrice type', () {
      final alert = _makeAlert(
        alertType: AlertType.targetPrice,
        targetPrice: 2.50,
      );
      expect(alert.alertDescription, 'Unter €2.50');
    });

    test('formats target price with two decimal places', () {
      final alert = _makeAlert(
        alertType: AlertType.targetPrice,
        targetPrice: 1.0,
      );
      expect(alert.alertDescription, 'Unter €1.00');
    });
  });

  group('PriceAlert.isKeywordAlert', () {
    test('is false for product scope', () {
      expect(_makeAlert(scope: AlertScope.product).isKeywordAlert, false);
    });

    test('is true for keyword scope', () {
      final alert = _makeAlert(scope: AlertScope.keyword, keyword: 'Milch');
      expect(alert.isKeywordAlert, true);
    });
  });

  group('PriceAlert defaults', () {
    test('default scope is product', () {
      final alert = PriceAlert(
        id: 'a',
        productId: 'p',
        productName: 'n',
        supermarket: 's',
        currentPrice: 1.0,
        alertType: AlertType.promotion,
        createdAt: DateTime.now(),
      );
      expect(alert.scope, AlertScope.product);
      expect(alert.isKeywordAlert, false);
    });
  });
}
