import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:preisvergleich_app/providers/app_state.dart';
import 'package:preisvergleich_app/screens/home_screen.dart';
import 'package:preisvergleich_app/services/algolia_service.dart';
import 'package:preisvergleich_app/services/price_alert_service.dart';
import 'package:preisvergleich_app/widgets/search_bar_widget.dart';
import 'mock_algolia_service.dart';
import 'mock_price_alert_service.dart';

Future<AppState> pumpTestApp(
  WidgetTester tester, {
  AlgoliaServiceBase? algoliaService,
  PriceAlertServiceBase? priceAlertService,
}) async {
  SharedPreferences.setMockInitialValues({});

  final appState = AppState(
    algoliaService: algoliaService ?? MockAlgoliaService(),
    priceAlertService: priceAlertService ?? MockPriceAlertService(),
  );
  await appState.initialize();

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: appState,
      child: const _TestApp(),
    ),
  );
  await tester.pumpAndSettle();
  return appState;
}

class _TestApp extends StatelessWidget {
  const _TestApp();

  static const _primary = Color(0xFF1B8A5A);
  static const _background = Color(0xFFF4F6FA);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.light,
          surface: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: _background,
        appBarTheme: const AppBarTheme(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

/// Performs a search and waits for results to appear.
Future<void> performSearch(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField).first, query);
  await tester.pumpAndSettle();
  // Scope the search icon to the SearchBarWidget to avoid ambiguity with
  // other search icons on screen (e.g. the keyword alert icon in _AlertTile).
  await tester.tap(find.descendant(
    of: find.byType(SearchBarWidget),
    matching: find.byIcon(Icons.search_rounded),
  ));
  await tester.pumpAndSettle();
}
