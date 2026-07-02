import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'home_screen.dart';
import 'favorites_screen.dart';
import 'price_alerts_screen.dart';
import 'shopping_list_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final screens = [
      const HomeScreen(),
      const FavoritesScreen(),
      PriceAlertsScreen(onGoToSearch: () => setState(() => _currentIndex = 0)),
      const ShoppingListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.search_rounded),
            label: 'Suche',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: appState.favorites.isNotEmpty,
              label: Text('${appState.favorites.length}',
                  style: const TextStyle(fontSize: 10)),
              child: const Icon(Icons.favorite_border_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: appState.favorites.isNotEmpty,
              label: Text('${appState.favorites.length}',
                  style: const TextStyle(fontSize: 10)),
              child: const Icon(Icons.favorite_rounded),
            ),
            label: 'Favoriten',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: appState.priceAlerts.isNotEmpty,
              label: Text('${appState.priceAlerts.length}',
                  style: const TextStyle(fontSize: 10)),
              child: const Icon(Icons.notifications_none_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: appState.priceAlerts.isNotEmpty,
              label: Text('${appState.priceAlerts.length}',
                  style: const TextStyle(fontSize: 10)),
              child: const Icon(Icons.notifications_rounded),
            ),
            label: 'Alarme',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: appState.shoppingListItemCount > 0,
              label: Text('${appState.shoppingListItemCount}',
                  style: const TextStyle(fontSize: 10)),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: appState.shoppingListItemCount > 0,
              label: Text('${appState.shoppingListItemCount}',
                  style: const TextStyle(fontSize: 10)),
              child: const Icon(Icons.shopping_cart_rounded),
            ),
            label: 'Einkaufsliste',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
