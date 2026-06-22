import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preisvergleich_app/models/price_history_entry.dart';
import 'package:preisvergleich_app/models/product.dart';
import 'package:preisvergleich_app/widgets/price_history_chart.dart';
import 'helpers/pump_app.dart';
import 'helpers/test_data.dart';

// Pumps a standalone PriceHistoryChart inside the full app theme.
Future<void> _pumpChart(
  WidgetTester tester,
  Product product,
  Future<List<PriceHistoryEntry>> Function(String, String) loader,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: PriceHistoryChart(product: product, loader: loader),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('PriceHistoryChart — integration', () {
    // ── Chart rendering with controlled data ───────────────────────────────

    testWidgets('renders chart and heading with ≥ 2 data points',
        (tester) async {
      await _pumpChart(
        tester,
        testProducts[0], // Vollmilch 1L, price: 1.29
        (_, __) async => [
          PriceHistoryEntry(price: 1.09, date: '2026-06-17'),
          PriceHistoryEntry(price: 1.19, date: '2026-06-18'),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Preisverlauf'), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.byIcon(Icons.show_chart_rounded), findsOneWidget);
    });

    testWidgets('hides chart when history is empty', (tester) async {
      await _pumpChart(
        tester,
        testProducts[0],
        (_, __) async => [],
      );
      await tester.pumpAndSettle();

      expect(find.text('Preisverlauf'), findsNothing);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('shows loading indicator before data arrives', (tester) async {
      await _pumpChart(
        tester,
        testProducts[0],
        (_, __) async {
          await Future.delayed(const Duration(milliseconds: 200));
          return [
            PriceHistoryEntry(price: 1.09, date: '2026-06-17'),
          ];
        },
      );

      // Before future resolves
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Preisverlauf'), findsNothing);

      await tester.pumpAndSettle();

      // 1 past + today = 2 → chart shown
      expect(find.text('Preisverlauf'), findsOneWidget);
    });

    testWidgets('does not show chart for promotion product with no past history',
        (tester) async {
      await _pumpChart(
        tester,
        testProducts[1], // Bio Vollmilch 1L (inPromotion: true, price: 1.59)
        (_, __) async => [],
      );
      await tester.pumpAndSettle();

      expect(find.text('Preisverlauf'), findsNothing);
    });
  });

  // ── Product detail sheet flow ─────────────────────────────────────────────

  group('Product detail sheet — price history section', () {
    testWidgets('tapping product opens detail sheet', (tester) async {
      await pumpTestApp(tester);
      await performSearch(tester, 'Milch');

      await tester.tap(find.text('Vollmilch 1L').first);
      await tester.pumpAndSettle();

      // Detail sheet opened: product name visible in the sheet header
      expect(find.text('Vollmilch 1L'), findsWidgets);
      expect(find.textContaining('1.29'), findsWidgets);
    });

    testWidgets('detail sheet shows price alert section', (tester) async {
      await pumpTestApp(tester);
      await performSearch(tester, 'Butter');

      await tester.tap(find.text('Butter 250g').first);
      await tester.pumpAndSettle();

      // Alert button is present in the sheet
      expect(find.text('Preisalarm setzen'), findsOneWidget);
    });

    testWidgets('detail sheet for promotion product shows original price',
        (tester) async {
      await pumpTestApp(tester);
      await performSearch(tester, 'Milch');

      await tester.tap(find.text('Bio Vollmilch 1L').first);
      await tester.pumpAndSettle();

      // Both current (1.59) and original (1.89) price visible in sheet
      expect(find.textContaining('1.59'), findsWidgets);
      expect(find.textContaining('1.89'), findsWidgets);
    });

    testWidgets('chart section absent without Firebase data in test environment',
        (tester) async {
      // In tests, Firebase is not initialized → FirestoreService returns [] →
      // 0 history + 1 current = 1 point → chart hidden (< 2 entries).
      await pumpTestApp(tester);
      await performSearch(tester, 'Butter');

      await tester.tap(find.text('Butter 250g').first);
      await tester.pumpAndSettle();

      expect(find.text('Preisverlauf'), findsNothing);
    });

    testWidgets('closing detail sheet returns to search results', (tester) async {
      await pumpTestApp(tester);
      await performSearch(tester, 'Butter');

      await tester.tap(find.text('Butter 250g').first);
      await tester.pumpAndSettle();
      expect(find.text('Preisalarm setzen'), findsOneWidget);

      // Close the bottom sheet by tapping outside it (the scrim)
      await tester.tapAt(const Offset(200, 10));
      await tester.pumpAndSettle();

      expect(find.text('Preisalarm setzen'), findsNothing);
      expect(find.text('Butter 250g'), findsOneWidget); // still in search list
    });
  });
}
