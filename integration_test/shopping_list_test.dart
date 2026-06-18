import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preisvergleich_app/screens/shopping_list_screen.dart';
import 'helpers/pump_app.dart';

void main() {
  group('Shopping List', () {
    testWidgets('add product shows snackbar confirmation', (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'Butter');
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('hinzugefügt'), findsOneWidget);
    });

    testWidgets('add product updates cart badge count', (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'Butter');
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      // Badge shows "1"
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('product appears in shopping list screen after adding',
        (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'Butter');
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      // Navigate to shopping list
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(ShoppingListScreen), findsOneWidget);
      expect(find.text('Butter 250g'), findsOneWidget);
    });

    testWidgets('shopping list shows item total price', (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'Butter');
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
      await tester.pumpAndSettle();

      // Total should contain the price 2.49
      expect(find.textContaining('2,49'), findsWidgets);
    });

    testWidgets('increment quantity updates count on product card',
        (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'Butter');
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      // After adding, the add button becomes quantity controls
      // The quantity starts at 1 — tap + to make it 2
      await tester.tap(find.byIcon(Icons.add_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('2'), findsWidgets);
    });

    testWidgets('decrement quantity from 2 to 1', (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'Butter');
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      // Increment to 2
      await tester.tap(find.byIcon(Icons.add_rounded).first);
      await tester.pumpAndSettle();
      expect(find.text('2'), findsWidgets);

      // Decrement back to 1
      await tester.tap(find.byIcon(Icons.remove_rounded).first);
      await tester.pumpAndSettle();
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('decrement from 1 removes product from list', (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'Butter');
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      // Tap the delete icon (shown at quantity=1)
      await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
      await tester.pumpAndSettle();

      // Product card reverts to showing the + add button
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('multiple products can be added to cart', (tester) async {
      await pumpTestApp(tester);

      await performSearch(tester, 'saft');
      expect(find.text('Apfelsaft 1L'), findsOneWidget);
      expect(find.text('Orangensaft 1L'), findsOneWidget);

      // Add both
      final addButtons = find.byIcon(Icons.add);
      await tester.tap(addButtons.first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      // Navigate to shopping list
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Apfelsaft 1L'), findsOneWidget);
      expect(find.text('Orangensaft 1L'), findsOneWidget);
    });

    testWidgets('create a new shopping list', (tester) async {
      await pumpTestApp(tester);

      // Navigate to shopping list screen
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(ShoppingListScreen), findsOneWidget);

      // Tap the 'Alle Listen' icon button (Icons.list_alt)
      await tester.tap(find.byIcon(Icons.list_alt));
      await tester.pumpAndSettle();

      // Tap the 'Neue Liste' FAB
      await tester.tap(find.widgetWithText(FloatingActionButton, 'Neue Liste'));
      await tester.pumpAndSettle();

      // Enter new list name in the dialog
      await tester.enterText(find.byType(TextField).last, 'Wocheneinkauf');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Erstellen'));
      await tester.pumpAndSettle();

      // After creation the screen is popped back; the active list name is shown
      expect(find.text('Wocheneinkauf'), findsWidgets);
    });
  });
}
