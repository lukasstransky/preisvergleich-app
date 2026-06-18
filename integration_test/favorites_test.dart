import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preisvergleich_app/screens/favorites_screen.dart';
import 'helpers/pump_app.dart';

void main() {
  group('Favorites', () {
    testWidgets('favorites screen is empty initially', (tester) async {
      await pumpTestApp(tester);

      await tester.tap(find.byIcon(Icons.favorite_border_rounded).first);
      await tester.pumpAndSettle();

      expect(find.byType(FavoritesScreen), findsOneWidget);
      expect(find.text('Keine Favoriten'), findsOneWidget);
    });

    testWidgets('tapping favorite icon toggles product as favorite',
        (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'Butter');

      // Tap the favorite icon (unfilled heart) — second icon in action column
      await tester.tap(find.byIcon(Icons.favorite_border_rounded).last);
      await tester.pumpAndSettle();

      // Icon should now be filled
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });

    testWidgets('favorited product updates favorites badge in AppBar',
        (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'Butter');

      await tester.tap(find.byIcon(Icons.favorite_border_rounded).last);
      await tester.pumpAndSettle();

      // Badge shows "1" on favorites icon
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('favorited product appears in favorites screen', (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'Butter');
      await tester.tap(find.byIcon(Icons.favorite_border_rounded).last);
      await tester.pumpAndSettle();

      // Navigate to favorites
      await tester.tap(find.byIcon(Icons.favorite_border_rounded).first);
      await tester.pumpAndSettle();

      expect(find.byType(FavoritesScreen), findsOneWidget);
      expect(find.text('Butter 250g'), findsOneWidget);
    });

    testWidgets('unfavoriting removes product from favorites screen',
        (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'Butter');
      await tester.tap(find.byIcon(Icons.favorite_border_rounded).last);
      await tester.pumpAndSettle();

      // Navigate to favorites
      await tester.tap(find.byIcon(Icons.favorite_border_rounded).first);
      await tester.pumpAndSettle();
      expect(find.text('Butter 250g'), findsOneWidget);

      // Unfavorite from the favorites screen
      await tester.tap(find.byIcon(Icons.favorite_rounded).last);
      await tester.pumpAndSettle();

      expect(find.text('Butter 250g'), findsNothing);
      expect(find.text('Keine Favoriten'), findsOneWidget);
    });

    testWidgets('multiple favorites appear in favorites screen', (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'saft');

      // Favorite Apfelsaft
      await tester.tap(find.byIcon(Icons.favorite_border_rounded).last);
      await tester.pumpAndSettle();

      // Favorite Orangensaft
      await tester.tap(find.byIcon(Icons.favorite_border_rounded).last);
      await tester.pumpAndSettle();

      // Navigate to favorites
      await tester.tap(find.byIcon(Icons.favorite_border_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('Apfelsaft 1L'), findsOneWidget);
      expect(find.text('Orangensaft 1L'), findsOneWidget);
    });
  });
}
