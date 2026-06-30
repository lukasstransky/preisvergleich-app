import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:preisvergleich_app/screens/shopping_list_screen.dart';
import 'helpers/pump_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Shopping list management', () {
    testWidgets('creates a new list via the manage button', (tester) async {
      await pumpTestApp(tester);

      // Navigate to shopping list screen
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined).first);
      await tester.pumpAndSettle();

      expect(find.byType(ShoppingListScreen), findsOneWidget);

      // Open list management screen
      await tester.tap(find.byIcon(Icons.list_alt));
      await tester.pumpAndSettle();

      // Tap the 'Neue Liste' FAB
      await tester.tap(find.widgetWithText(FloatingActionButton, 'Neue Liste'));
      await tester.pumpAndSettle();

      // Enter new list name in the dialog
      await tester.enterText(find.byType(TextField).last, 'Urlaubsliste');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Erstellen'));
      await tester.pumpAndSettle();

      // After creation the new list name should be visible
      expect(find.text('Urlaubsliste'), findsWidgets);
    });

    testWidgets('renames a list via the edit action', (tester) async {
      final appState = await pumpTestApp(tester);

      // Pre-create a second list to ensure renaming works regardless of which
      // list is active
      await appState.createList('Zu umbenennen');
      await tester.pump();

      // Navigate to shopping list screen
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined).first);
      await tester.pumpAndSettle();

      // Open list management screen
      await tester.tap(find.byIcon(Icons.list_alt));
      await tester.pumpAndSettle();

      // Tap the edit / rename icon on the 'Zu umbenennen' list tile
      // The rename action is typically an Icons.edit or accessible via long-press.
      // Try the edit icon first; if not found fall back to long-press on the tile.
      final editIconFinder = find.byIcon(Icons.edit_outlined);
      if (tester.any(editIconFinder)) {
        await tester.tap(editIconFinder.first);
      } else {
        await tester.longPress(find.text('Zu umbenennen'));
      }
      await tester.pumpAndSettle();

      // Clear the text field and enter the new name
      final textField = find.byType(TextField).last;
      await tester.tap(textField);
      await tester.pumpAndSettle();
      await tester.enterText(textField, 'Wocheneinkauf');
      await tester.pumpAndSettle();

      // Confirm the rename
      final speichernButton = find.text('Speichern');
      final umbenennenButton = find.text('Umbenennen');
      if (tester.any(speichernButton)) {
        await tester.tap(speichernButton);
      } else {
        await tester.tap(umbenennenButton);
      }
      await tester.pumpAndSettle();

      expect(find.text('Wocheneinkauf'), findsWidgets);
      expect(find.text('Zu umbenennen'), findsNothing);
    });

    testWidgets('deletes a list and falls back to another', (tester) async {
      final appState = await pumpTestApp(tester);

      // Create a second list so there is something to fall back to
      await appState.createList('Liste B');
      await tester.pump();

      // Navigate to shopping list screen
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined).first);
      await tester.pumpAndSettle();

      // Open list management screen
      await tester.tap(find.byIcon(Icons.list_alt));
      await tester.pumpAndSettle();

      // Tap the delete icon on 'Liste B'
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      // Confirm deletion if a dialog appears
      final confirmFinder = find.text('Löschen');
      if (tester.any(confirmFinder)) {
        await tester.tap(confirmFinder.first);
        await tester.pumpAndSettle();
      }

      // 'Liste B' should be gone; the default 'Einkaufsliste' remains
      expect(find.text('Liste B'), findsNothing);
      expect(find.text('Einkaufsliste'), findsWidgets);
    });

    testWidgets('switches active list and shows correct name', (tester) async {
      final appState = await pumpTestApp(tester);
      final firstId = appState.activeList!.id;

      // Create a second list (becomes active)
      await appState.createList('Zweitliste');
      await tester.pump();

      // Navigate to shopping list screen
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined).first);
      await tester.pumpAndSettle();

      // Open list management screen
      await tester.tap(find.byIcon(Icons.list_alt));
      await tester.pumpAndSettle();

      // Tap on 'Einkaufsliste' tile to switch back to the first list
      await tester.tap(find.text('Einkaufsliste').first);
      await tester.pumpAndSettle();

      // After switching, the active list id should match the first list
      expect(appState.activeList?.id, firstId);
    });

    testWidgets('items are list-specific — switching list shows different items',
        (tester) async {
      await pumpTestApp(tester);

      // Add Butter to the current (first) list via search
      await performSearch(tester, 'Butter');
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      // Navigate to shopping list screen
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined).first);
      await tester.pumpAndSettle();

      expect(find.byType(ShoppingListScreen), findsOneWidget);
      expect(find.text('Butter 250g'), findsOneWidget);

      // Open list management and create a second list
      await tester.tap(find.byIcon(Icons.list_alt));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FloatingActionButton, 'Neue Liste'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'Leere Liste');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Erstellen'));
      await tester.pumpAndSettle();

      // After creation, navigate back to shopping list screen
      // The newly created list is now active and should be empty
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined).first);
      await tester.pumpAndSettle();

      // Butter should not appear in the new (empty) list
      expect(find.text('Butter 250g'), findsNothing);
    });
  });
}
