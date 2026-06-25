import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preisvergleich_app/screens/favorites_screen.dart';
import 'package:preisvergleich_app/screens/price_alerts_screen.dart';
import 'package:preisvergleich_app/screens/shopping_list_screen.dart';
import 'helpers/pump_app.dart';
import 'helpers/test_data.dart';

void main() {
  group('Navigation', () {
    testWidgets('home screen shows navigation bar icons', (tester) async {
      await pumpTestApp(tester);

      // Icons live in the bottom NavigationBar — findsWidgets because
      // NavigationBar may keep both icon and selectedIcon in the tree.
      expect(find.byIcon(Icons.favorite_border_rounded), findsWidgets);
      expect(find.byIcon(Icons.notifications_none_rounded), findsWidgets);
      expect(find.byIcon(Icons.shopping_cart_outlined), findsWidgets);
    });

    testWidgets('navigate to favorites screen and back', (tester) async {
      await pumpTestApp(tester);

      await tester.tap(find.byIcon(Icons.favorite_border_rounded).first);
      await tester.pumpAndSettle();

      expect(find.byType(FavoritesScreen), findsOneWidget);
      // 'Favoriten' appears in both the NavigationBar label and the screen AppBar
      expect(find.text('Favoriten'), findsWidgets);

      // Go back via the Suche (home) nav tab.
      await tester.tap(find.text('Suche'));
      await tester.pumpAndSettle();

      expect(find.text('Preisvergleich'), findsOneWidget);
    });

    testWidgets('navigate to price alerts screen and back', (tester) async {
      await pumpTestApp(tester);

      await tester.tap(find.byIcon(Icons.notifications_none_rounded).first);
      await tester.pumpAndSettle();

      expect(find.byType(PriceAlertsScreen), findsOneWidget);
      expect(find.text('Preisalarme'), findsOneWidget);

      await tester.tap(find.text('Suche'));
      await tester.pumpAndSettle();

      expect(find.text('Preisvergleich'), findsOneWidget);
    });

    testWidgets('navigate to shopping list screen and back', (tester) async {
      await pumpTestApp(tester);

      await tester.tap(find.byIcon(Icons.shopping_cart_outlined).first);
      await tester.pumpAndSettle();

      expect(find.byType(ShoppingListScreen), findsOneWidget);

      await tester.tap(find.text('Suche'));
      await tester.pumpAndSettle();

      expect(find.text('Preisvergleich'), findsOneWidget);
    });

    testWidgets('AppBar badges update after adding favorite', (tester) async {
      final appState = await pumpTestApp(tester);

      // Initially no badge numbers
      expect(find.text('1'), findsNothing);

      await performSearch(tester, 'Butter');
      // Toggle via state — heart GestureDetector loses to card InkWell in tests
      await appState.toggleFavorite(testProducts[2]); // Butter 250g
      await tester.pump();

      // Favorites badge shows 1
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('AppBar badges update after adding to shopping list',
        (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'Butter');
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      // Shopping list badge shows 1
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('search results persist after navigating away and back',
        (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'Milch');
      expect(find.text('Vollmilch 1L'), findsOneWidget);

      // Navigate to favorites via the NavigationBar.
      await tester.tap(find.byIcon(Icons.favorite_border_rounded).first);
      await tester.pumpAndSettle();

      // Go back to search via Suche tab.
      await tester.tap(find.text('Suche'));
      await tester.pumpAndSettle();

      // Results should still be visible (IndexedStack preserves state).
      expect(find.text('Vollmilch 1L'), findsOneWidget);
    });
  });
}
