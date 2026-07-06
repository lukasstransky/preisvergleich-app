import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
  void initState() {
    super.initState();
    if (Firebase.apps.isNotEmpty) {
      // App opened by tapping a notification while in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      // App launched from terminated state by tapping a notification
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) _handleNotificationTap(message);
      });
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final keyword = data['keyword'] as String?;
    final productName = data['productName'] as String?;

    final query = keyword ?? productName;
    if (query == null || query.isEmpty) return;

    // Switch to home tab and trigger search
    setState(() => _currentIndex = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().search(query);
    });
  }

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
