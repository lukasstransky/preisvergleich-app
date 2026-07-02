import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'helpers/pump_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Profile tab', () {
    testWidgets('is reachable via bottom navigation', (tester) async {
      await pumpTestApp(tester);

      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Profil'), findsWidgets);
    });

    testWidgets('shows guest state for unauthenticated user', (tester) async {
      await pumpTestApp(tester);

      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Gast'), findsOneWidget);
      expect(find.text('Nicht angemeldet'), findsOneWidget);
    });

    testWidgets('shows sign-in options for guest user', (tester) async {
      await pumpTestApp(tester);

      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Account verknüpfen'), findsOneWidget);
      expect(find.text('Mit Google anmelden'), findsOneWidget);
    });

    testWidgets('does not show sign-out button for guest user', (tester) async {
      await pumpTestApp(tester);

      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Abmelden'), findsNothing);
    });
  });
}
