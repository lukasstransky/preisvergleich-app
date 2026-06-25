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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preisvergleich'),
        centerTitle: true,
        actions: const [],
      ),
      body: Column(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.bg,
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Column(
              children: [
                SearchBarWidget(),
                SupermarketFilter(),
              ],
            ),
          ),
          if (appState.searchQuery.isNotEmpty)
            DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
              ),
              child: Column(
                children: [
                  const FilterSection(),
                  _buildKeywordAlertBanner(context, appState),
                ],
              ),
            ),
          _buildResultsInfo(appState),
          Expanded(child: _buildProductList(appState)),
        ],
      ),
    );
  }

  Widget _buildKeywordAlertBanner(BuildContext context, AppState appState) {
    final query = appState.searchQuery.trim();
    if (query.isEmpty) return const SizedBox.shrink();

    final existingAlert = appState.getKeywordAlert(query);

    if (existingAlert != null) {
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.notifications_active, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Alarm für "$query" · ${existingAlert.alertDescription}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.danger,
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
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: GestureDetector(
        onTap: () => _showKeywordAlertDialog(context, appState, query),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_none, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Alarm für "$query" setzen',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.textTertiary),
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

  Widget _buildResultsInfo(AppState appState) {
    if (appState.isSearching || appState.searchQuery.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: Row(
        children: [
          Text(
            '${appState.searchResults.length} Ergebnisse',
            style: const TextStyle(
              color: AppColors.textSecondary,
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
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.close_rounded, size: 11, color: AppColors.textSecondary),
                    const SizedBox(width: 3),
                    const Text('Filter zurücksetzen',
                        style: TextStyle(
                            color: AppColors.textSecondary,
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

  Widget _buildProductList(AppState appState) {
    if (appState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              appState.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger),
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
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search_rounded,
                    size: 34, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              const Text(
                'Preise vergleichen',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Such nach Lebensmitteln und vergleiche die Preise aller Supermärkte auf einen Blick.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 14, height: 1.6),
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
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
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
                decoration: const BoxDecoration(
                    color: AppColors.surfaceAlt, shape: BoxShape.circle),
                child: const Icon(Icons.search_off_rounded,
                    size: 34, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 20),
              const Text('Keine Ergebnisse',
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'Für "${appState.searchQuery}" wurden keine Produkte gefunden.',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14, height: 1.5),
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
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  '"$keyword"',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Du wirst benachrichtigt wenn ein passendes Produkt im Angebot ist.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
            backgroundColor: const Color(0xFF1B8A5A),
            foregroundColor: Colors.white,
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
