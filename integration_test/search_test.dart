import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/pump_app.dart';

void main() {
  group('Search', () {
    testWidgets('home screen renders with search bar', (tester) async {
      await pumpTestApp(tester);

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Preisvergleich'), findsOneWidget);
    });

    testWidgets('empty state shows no product cards', (tester) async {
      await pumpTestApp(tester);

      // No search performed yet → no product name visible
      expect(find.text('Vollmilch 1L'), findsNothing);
      expect(find.text('Butter 250g'), findsNothing);
    });

    testWidgets('searching returns matching products', (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'Milch');

      expect(find.text('Vollmilch 1L'), findsOneWidget);
      expect(find.text('Bio Vollmilch 1L'), findsOneWidget);
    });

    testWidgets('search result shows product price', (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'Butter');

      expect(find.text('Butter 250g'), findsOneWidget);
      expect(find.textContaining('2,49'), findsWidgets);
    });

    testWidgets('search result shows supermarket badge', (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'Milch');

      expect(find.text('Billa'), findsOneWidget);
      expect(find.text('Spar'), findsOneWidget);
    });

    testWidgets('promotion badge visible on discounted product', (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'Milch');

      expect(find.text('15% SALE'), findsOneWidget);
    });

    testWidgets('search with no matches shows empty list', (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'xyznotfound123');

      expect(find.text('Vollmilch 1L'), findsNothing);
      expect(find.text('Butter 250g'), findsNothing);
    });

    testWidgets('clearing search removes results', (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'Milch');
      expect(find.text('Vollmilch 1L'), findsOneWidget);

      // Tap the clear (×) button
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      expect(find.text('Vollmilch 1L'), findsNothing);
    });

    testWidgets('supermarket filter narrows results', (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'Milch');
      // Both Billa and Spar products visible
      expect(find.text('Vollmilch 1L'), findsOneWidget);
      expect(find.text('Bio Vollmilch 1L'), findsOneWidget);

      // Deselect Spar (tap the Spar chip)
      await tester.tap(find.text('Spar'));
      await tester.pumpAndSettle();

      // Bio Vollmilch from Spar should no longer appear
      expect(find.text('Bio Vollmilch 1L'), findsNothing);
      // Vollmilch from Billa still visible
      expect(find.text('Vollmilch 1L'), findsOneWidget);
    });

    testWidgets('promotions-only filter shows only discounted products',
        (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'Milch');

      // Tap 'Angebote' chip to filter for promotions only
      await tester.tap(find.text('Angebote'));
      await tester.pumpAndSettle();

      expect(find.text('Bio Vollmilch 1L'), findsOneWidget);
      expect(find.text('Vollmilch 1L'), findsNothing);
    });

    testWidgets('search history is saved after search', (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'Butter');

      // Focus the search bar to reveal history
      await tester.tap(find.byType(TextField).first);
      await tester.pumpAndSettle();

      // Clear the text to show history panel
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      expect(find.text('Butter'), findsWidgets);
    });
  });
}
