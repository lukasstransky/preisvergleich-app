import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import '../models/price_alert.dart';
import '../providers/app_state.dart';
import '../widgets/product_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/supermarket_filter.dart';
import '../widgets/filter_section.dart';
import '../theme/app_colors.dart';
import 'price_alerts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().initialize();
    });
    if (Firebase.apps.isNotEmpty) {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.title ?? 'Preisalarm',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              if (notification.body != null) Text(notification.body!),
            ],
          ),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Alarme',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const PriceAlertsScreen()),
            ),
          ),
        ));
      }
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final c = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preisvergleich'),
        centerTitle: true,
        actions: const [],
      ),
      body: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: c.bg,
              border: Border(
                bottom: BorderSide(color: c.border),
              ),
            ),
            child: const Column(
              children: [
                SearchBarWidget(),
                SupermarketFilter(),
              ],
            ),
          ),
          if (appState.searchQuery.isNotEmpty)
            DecoratedBox(
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(
                  bottom: BorderSide(color: c.border),
                ),
              ),
              child: Column(
                children: [
                  const FilterSection(),
                  _buildKeywordAlertBanner(context, appState),
                ],
              ),
            ),
          _buildResultsInfo(context, appState),
          Expanded(child: _buildProductList(context, appState)),
        ],
      ),
    );
  }

  Widget _buildKeywordAlertBanner(BuildContext context, AppState appState) {
    final c = AppColors.of(context);
    final query = appState.searchQuery.trim();
    if (query.isEmpty) return const SizedBox.shrink();

    final existingAlert = appState.getKeywordAlert(query);

    if (existingAlert != null) {
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: c.primarySoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.primary.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_active, size: 16, color: c.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Alarm für "$query" · ${existingAlert.alertDescription}',
                style: TextStyle(
                    fontSize: 12, color: c.primary, fontWeight: FontWeight.w500),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: c.danger,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => appState.removeKeywordAlert(existingAlert.id, query),
              child: const Text('Entfernen', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: GestureDetector(
        onTap: () => _showKeywordAlertDialog(context, appState, query),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: c.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Icon(Icons.notifications_none, size: 16, color: c.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Alarm für "$query" setzen',
                style: TextStyle(fontSize: 12, color: c.textSecondary),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, size: 16, color: c.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  void _showKeywordAlertDialog(BuildContext context, AppState appState, String keyword) {
    showDialog(
      context: context,
      builder: (_) => _KeywordAlertDialog(keyword: keyword),
    );
  }

  Widget _buildResultsInfo(BuildContext context, AppState appState) {
    final c = AppColors.of(context);
    if (appState.isSearching || appState.searchQuery.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: Row(
        children: [
          Text(
            '${appState.searchResults.length} Ergebnisse',
            style: TextStyle(
              color: c.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
            ),
          ),
          if (appState.hasActiveFilters) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: appState.clearFilters,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.surfaceAlt,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close_rounded, size: 11, color: c.textSecondary),
                    const SizedBox(width: 3),
                    Text('Filter zurücksetzen',
                        style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductList(BuildContext context, AppState appState) {
    final c = AppColors.of(context);

    if (appState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: c.danger),
            const SizedBox(height: 16),
            Text(
              appState.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.danger),
            ),
          ],
        ),
      );
    }

    if (appState.searchQuery.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: c.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.search_rounded,
                    size: 34, color: c.primary),
              ),
              const SizedBox(height: 20),
              Text(
                'Preise vergleichen',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Such nach Lebensmitteln und vergleiche die Preise aller Supermärkte auf einen Blick.',
                style: TextStyle(
                    color: c.textSecondary, fontSize: 14, height: 1.6),
                textAlign: TextAlign.center,
              ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (appState.isSearching) {
      return Center(
        child: CircularProgressIndicator(
          color: c.primary,
          strokeWidth: 2,
        ),
      );
    }

    if (appState.searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                    color: c.surfaceAlt, shape: BoxShape.circle),
                child: Icon(Icons.search_off_rounded,
                    size: 34, color: c.textTertiary),
              ),
              const SizedBox(height: 20),
              Text('Keine Ergebnisse',
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: c.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'Für "${appState.searchQuery}" wurden keine Produkte gefunden.',
                style: TextStyle(
                    color: c.textSecondary, fontSize: 14, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: appState.clearFilters,
                child: const Text('Filter zurücksetzen'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: appState.searchResults.length,
      itemBuilder: (context, index) {
        return ProductCard(product: appState.searchResults[index]);
      },
    );
  }
}

class _KeywordAlertDialog extends StatelessWidget {
  final String keyword;
  const _KeywordAlertDialog({required this.keyword});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Preisalarm setzen',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: c.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search, size: 14, color: c.primary),
                const SizedBox(width: 6),
                Text(
                  '"$keyword"',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: c.primary,
                      fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Du wirst benachrichtigt wenn ein passendes Produkt im Angebot ist.',
            style: TextStyle(color: c.textSecondary, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: c.primary,
            foregroundColor: c.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () async {
            final appState = context.read<AppState>();
            final messenger = ScaffoldMessenger.of(context);
            Navigator.pop(context);
            try {
              await appState.setKeywordAlert(
                keyword: keyword,
                alertType: AlertType.promotion,
              );
              messenger
                ..clearSnackBars()
                ..showSnackBar(const SnackBar(
                  content: Text('Preisalarm gespeichert'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(milliseconds: 2000),
                ));
            } catch (e) {
              messenger
                ..clearSnackBars()
                ..showSnackBar(SnackBar(
                  content: Text('Fehler: $e'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ));
            }
          },
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
