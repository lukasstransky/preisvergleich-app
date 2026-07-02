import 'package:flutter_test/flutter_test.dart';
import 'package:preisvergleich_app/services/premium_service.dart';
import 'package:preisvergleich_app/widgets/paywall_sheet.dart';
import 'helpers/fake_premium_service.dart';
import 'helpers/mock_price_alert_service.dart';
import 'helpers/pump_app.dart';
import 'helpers/test_data.dart';

void main() {
  group('Premium gating', () {
    testWidgets('hitting the free alert limit opens the paywall',
        (tester) async {
      await pumpTestApp(
        tester,
        // Monetization live, only one free alert allowed…
        premiumService: FakePremiumService(
          config: const PremiumConfig(
              monetizationEnabled: true, freeAlertLimit: 1),
        ),
        // …and the user already has one alert, so the next one is blocked.
        priceAlertService:
            MockPriceAlertService(initialAlerts: [testProductAlert]),
      );

      await performSearch(tester, 'Butter');
      await tester.tap(find.text('Butter 250g'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Preisalarm setzen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      // The paywall is shown instead of a saved-alert confirmation.
      expect(find.byType(PaywallSheet), findsOneWidget);
      expect(find.text('Preisvergleich Premium'), findsOneWidget);
      expect(find.text('Preisalarm gespeichert'), findsNothing);
    });

    testWidgets('premium user can create alerts past the free limit',
        (tester) async {
      await pumpTestApp(
        tester,
        premiumService: FakePremiumService(
          config: const PremiumConfig(
              monetizationEnabled: true, freeAlertLimit: 1),
          premium: true,
        ),
        priceAlertService:
            MockPriceAlertService(initialAlerts: [testProductAlert]),
      );

      await performSearch(tester, 'Butter');
      await tester.tap(find.text('Butter 250g'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Preisalarm setzen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(find.byType(PaywallSheet), findsNothing);
      expect(find.text('Preisalarm gespeichert'), findsOneWidget);
    });

    testWidgets('unlocking premium from the paywall lets the alert be saved',
        (tester) async {
      final appState = await pumpTestApp(
        tester,
        premiumService: FakePremiumService(
          config: const PremiumConfig(
              monetizationEnabled: true, freeAlertLimit: 1),
        ),
        priceAlertService:
            MockPriceAlertService(initialAlerts: [testProductAlert]),
      );

      await performSearch(tester, 'Butter');
      await tester.tap(find.text('Butter 250g'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Preisalarm setzen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(find.byType(PaywallSheet), findsOneWidget);

      await tester.tap(find.text('Premium freischalten'));
      await tester.pumpAndSettle();

      expect(appState.isPremium, isTrue);
      expect(find.byType(PaywallSheet), findsNothing);
    });
  });
}
