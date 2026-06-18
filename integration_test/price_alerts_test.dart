import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preisvergleich_app/screens/price_alerts_screen.dart';
import 'helpers/mock_price_alert_service.dart';
import 'helpers/pump_app.dart';
import 'helpers/test_data.dart';

void main() {
  group('Price Alerts', () {
    testWidgets('price alerts screen is empty initially', (tester) async {
      await pumpTestApp(tester);

      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(PriceAlertsScreen), findsOneWidget);
      expect(find.text('Keine Preisalarme'), findsOneWidget);
    });

    testWidgets('pre-existing alert is shown in alerts screen', (tester) async {
      await pumpTestApp(
        tester,
        priceAlertService:
            MockPriceAlertService(initialAlerts: [testProductAlert]),
      );

      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(PriceAlertsScreen), findsOneWidget);
      expect(find.text('Vollmilch 1L'), findsOneWidget);
    });

    testWidgets('product with active alert shows bell icon on card',
        (tester) async {
      await pumpTestApp(
        tester,
        priceAlertService:
            MockPriceAlertService(initialAlerts: [testProductAlert]),
      );

      await performSearch(tester, 'Milch');

      // The Vollmilch 1L card should show the active alert bell badge
      expect(find.byIcon(Icons.notifications_active_rounded), findsWidgets);
    });

    testWidgets('set promotion alert via product detail sheet', (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'Butter');

      // Tap the product card to open detail sheet
      await tester.tap(find.text('Butter 250g'));
      await tester.pumpAndSettle();

      // Tap 'Preisalarm setzen' button
      await tester.tap(find.text('Preisalarm setzen'));
      await tester.pumpAndSettle();

      // 'Im Angebot' is pre-selected — tap 'Speichern'
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      // Confirmation snackbar
      expect(find.text('Preisalarm gespeichert'), findsOneWidget);
    });

    testWidgets('saved alert appears in price alerts screen', (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'Butter');
      await tester.tap(find.text('Butter 250g'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Preisalarm setzen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      // Dismiss the modal bottom sheet with the system back gesture
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(PriceAlertsScreen), findsOneWidget);
      expect(find.text('Butter 250g'), findsOneWidget);
    });

    testWidgets('remove alert via detail sheet', (tester) async {
      await pumpTestApp(
        tester,
        priceAlertService:
            MockPriceAlertService(initialAlerts: [testProductAlert]),
      );

      await performSearch(tester, 'Milch');

      // Tap Vollmilch card to open detail sheet
      await tester.tap(find.text('Vollmilch 1L'));
      await tester.pumpAndSettle();

      expect(find.text('Preisalarm aktiv'), findsOneWidget);

      // Tap 'Entfernen'
      await tester.tap(find.text('Entfernen'));
      await tester.pumpAndSettle();

      expect(find.text('Preisalarm entfernt'), findsOneWidget);
    });

    testWidgets('remove alert from price alerts screen', (tester) async {
      await pumpTestApp(
        tester,
        priceAlertService:
            MockPriceAlertService(initialAlerts: [testProductAlert]),
      );

      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Vollmilch 1L'), findsOneWidget);

      // Tap the notifications_off IconButton to remove the alert
      await tester.tap(find.byIcon(Icons.notifications_off_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Vollmilch 1L'), findsNothing);
    });

    testWidgets('keyword alert shown with keyword label', (tester) async {
      await pumpTestApp(
        tester,
        priceAlertService:
            MockPriceAlertService(initialAlerts: [testKeywordAlert]),
      );

      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(PriceAlertsScreen), findsOneWidget);
      // Keyword alert shows the keyword as the label
      expect(find.textContaining('milch'), findsWidgets);
    });

    testWidgets('alerts screen badge updates when alerts exist', (tester) async {
      await pumpTestApp(
        tester,
        priceAlertService:
            MockPriceAlertService(initialAlerts: [testProductAlert]),
      );

      // Badge count should show "1"
      expect(find.text('1'), findsWidgets);
    });
  });
}
