import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preisvergleich_app/screens/favorites_screen.dart';
import 'helpers/pump_app.dart';
import 'helpers/test_data.dart';

void main() {
  group('Favorites', () {
    testWidgets('favorites screen is empty initially', (tester) async {
      await pumpTestApp(tester);

      await tester.tap(find.byIcon(Icons.favorite_border_rounded).first);
      await tester.pumpAndSettle();

      expect(find.byType(FavoritesScreen), findsOneWidget);
      expect(find.text('Keine Favoriten'), findsOneWidget);
    });

    testWidgets('favorited product shows filled heart icon', (tester) async {
      final appState = await pumpTestApp(tester);

      await performSearch(tester, 'Butter');

      // Toggle via state — the heart GestureDetector is inside the card
      // InkWell which wins the gesture arena in the test environment
      await appState.toggleFavorite(testProducts[2]); // Butter 250g
      await tester.pump();

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });

    testWidgets('favorited product updates favorites badge in AppBar',
        (tester) async {
      final appState = await pumpTestApp(tester);

      await performSearch(tester, 'Butter');

      await appState.toggleFavorite(testProducts[2]); // Butter 250g
      await tester.pump();

      expect(find.text('1'), findsWidgets);
    });

    testWidgets('favorited product appears in favorites screen', (tester) async {
      final appState = await pumpTestApp(tester);

      await performSearch(tester, 'Butter');
      await appState.toggleFavorite(testProducts[2]); // Butter 250g
      await tester.pump();

      // Navigate to favorites via AppBar icon
      await tester.tap(find.byIcon(Icons.favorite_border_rounded).first);
      await tester.pumpAndSettle();

      expect(find.byType(FavoritesScreen), findsOneWidget);
      expect(find.text('Butter 250g'), findsOneWidget);
    });

    testWidgets('unfavoriting removes product from favorites screen',
        (tester) async {
      final appState = await pumpTestApp(tester);

      await performSearch(tester, 'Butter');
      await appState.toggleFavorite(testProducts[2]); // Butter 250g → favorited
      await tester.pump();

      // Navigate to favorites
      await tester.tap(find.byIcon(Icons.favorite_border_rounded).first);
      await tester.pumpAndSettle();
      expect(find.text('Butter 250g'), findsOneWidget);

      // Unfavorite via state
      await appState.toggleFavorite(testProducts[2]); // Butter 250g → unfavorited
      await tester.pump();

      expect(find.text('Butter 250g'), findsNothing);
      expect(find.text('Keine Favoriten'), findsOneWidget);
    });

    testWidgets('multiple favorites appear in favorites screen', (tester) async {
      final appState = await pumpTestApp(tester);

      await performSearch(tester, 'saft');

      await appState.toggleFavorite(testProducts[3]); // Apfelsaft 1L
      await appState.toggleFavorite(testProducts[4]); // Orangensaft 1L
      await tester.pump();

      // Navigate to favorites
      await tester.tap(find.byIcon(Icons.favorite_border_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('Apfelsaft 1L'), findsOneWidget);
      expect(find.text('Orangensaft 1L'), findsOneWidget);
    });
  });
}
