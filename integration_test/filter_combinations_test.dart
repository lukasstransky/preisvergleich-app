import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'helpers/pump_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Filter combinations', () {
    testWidgets('supermarket + category filter combined narrows results correctly',
        (tester) async {
      await pumpTestApp(tester);

      // Search returns 3 Milchprodukte (billa, spar, hofer) + 2 Getränke (penny, lidl)
      await performSearch(tester, 'Milch');

      // Initially both Vollmilch (billa) and Bio Vollmilch (spar) are visible
      expect(find.text('Vollmilch 1L'), findsOneWidget);
      expect(find.text('Bio Vollmilch 1L'), findsOneWidget);

      // Deselect Spar — only Billa product should remain
      await tester.tap(find.text('Spar').first);
      await tester.pumpAndSettle();

      expect(find.text('Vollmilch 1L'), findsOneWidget);
      expect(find.text('Bio Vollmilch 1L'), findsNothing);

      // Also deselect Hofer — only Vollmilch from Billa remains
      await tester.tap(find.text('Hofer').first);
      await tester.pumpAndSettle();

      expect(find.text('Vollmilch 1L'), findsOneWidget);
      expect(find.text('Butter 250g'), findsNothing);
    });

    testWidgets('promotions filter combined with supermarket filter',
        (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'Milch');

      // Both Vollmilch (billa, no promo) and Bio Vollmilch (spar, promo) visible
      expect(find.text('Vollmilch 1L'), findsOneWidget);
      expect(find.text('Bio Vollmilch 1L'), findsOneWidget);

      // Apply promotions-only filter
      await tester.tap(find.text('Angebote'));
      await tester.pumpAndSettle();

      // Only Bio Vollmilch (inPromotion=true) should remain
      expect(find.text('Bio Vollmilch 1L'), findsOneWidget);
      expect(find.text('Vollmilch 1L'), findsNothing);

      // Now deselect Spar as well — no products match both filters
      await tester.tap(find.text('Spar').first);
      await tester.pumpAndSettle();

      expect(find.text('Bio Vollmilch 1L'), findsNothing);
    });

    testWidgets('sort by unit price orders results ascending', (tester) async {
      await pumpTestApp(tester);

      // Search for saft: p4 Apfelsaft 0.99 and p5 Orangensaft 1.49
      await performSearch(tester, 'saft');

      expect(find.text('Apfelsaft 1L'), findsOneWidget);
      expect(find.text('Orangensaft 1L'), findsOneWidget);

      // Apply €/kg sort
      await tester.tap(find.text('€/kg'));
      await tester.pumpAndSettle();

      // Both products still visible — cheapest first (Apfelsaft 0.99)
      expect(find.text('Apfelsaft 1L'), findsOneWidget);
      expect(find.text('Orangensaft 1L'), findsOneWidget);

      // Verify ordering: Apfelsaft (0.99) should appear before Orangensaft (1.49)
      final apfelOffset = tester.getTopLeft(find.text('Apfelsaft 1L'));
      final orangeOffset = tester.getTopLeft(find.text('Orangensaft 1L'));
      expect(apfelOffset.dy, lessThan(orangeOffset.dy));
    });

    testWidgets('clearFilters resets all active filters', (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'Milch');

      // Apply multiple filters
      await tester.tap(find.text('Spar').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Angebote'));
      await tester.pumpAndSettle();

      // Only Bio Vollmilch visible (spar, promotion)
      expect(find.text('Bio Vollmilch 1L'), findsNothing);

      // Tap 'Filter zurücksetzen' to clear all filters
      await tester.tap(find.text('Filter zurücksetzen'));
      await tester.pumpAndSettle();

      // All Milch products should be visible again
      expect(find.text('Vollmilch 1L'), findsOneWidget);
      expect(find.text('Bio Vollmilch 1L'), findsOneWidget);
      expect(find.text('Butter 250g'), findsOneWidget);
    });

    testWidgets('hasActiveFilters shows reset button when filters active',
        (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'Milch');

      // No active filters — reset button should not be visible
      expect(find.text('Filter zurücksetzen'), findsNothing);

      // Toggle a supermarket off
      await tester.tap(find.text('Billa').first);
      await tester.pumpAndSettle();

      // Now a filter is active — reset button appears
      expect(find.text('Filter zurücksetzen'), findsOneWidget);

      // Clear filters removes the reset button
      await tester.tap(find.text('Filter zurücksetzen'));
      await tester.pumpAndSettle();

      expect(find.text('Filter zurücksetzen'), findsNothing);
    });
  });
}
