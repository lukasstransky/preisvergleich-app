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
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1B8A5A), Color(0xFF177A50)],
              ),
            ),
            child: Column(
              children: [
                const SearchBarWidget(),
                const SupermarketFilter(),
              ],
            ),
          ),
          if (appState.searchQuery.isNotEmpty)
            DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 6,
                      offset: Offset(0, 3)),
                ],
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
          color: const Color(0xFF1B8A5A).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1B8A5A).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.notifications_active, size: 16, color: Color(0xFF1B8A5A)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Alarm für "$query" · ${existingAlert.alertDescription}',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF1B8A5A), fontWeight: FontWeight.w500),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
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
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.notifications_none, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Alarm für "$query" setzen',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
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
              color: Color(0xFF9CA3AF),
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
                  color: const Color(0xFFF0F2F7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close_rounded, size: 11, color: Colors.grey[600]),
                    const SizedBox(width: 3),
                    Text('Filter zurücksetzen',
                        style: TextStyle(
                            color: Colors.grey[600],
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
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              appState.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      );
    }

    if (appState.searchQuery.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF4EF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search_rounded,
                    size: 34, color: Color(0xFF1B8A5A)),
              ),
              const SizedBox(height: 20),
              const Text(
                'Preise vergleichen',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Such nach Lebensmitteln und vergleiche die Preise aller Supermärkte auf einen Blick.',
                style: TextStyle(
                    color: Colors.grey[500], fontSize: 14, height: 1.6),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (appState.isSearching) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1B8A5A),
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
                    color: Colors.grey[100], shape: BoxShape.circle),
                child: Icon(Icons.search_off_rounded,
                    size: 34, color: Colors.grey[400]),
              ),
              const SizedBox(height: 20),
              const Text('Keine Ergebnisse',
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4)),
              const SizedBox(height: 8),
              Text(
                'Für "${appState.searchQuery}" wurden keine Produkte gefunden.',
                style: TextStyle(color: Colors.grey[500], fontSize: 14, height: 1.5),
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

class _KeywordAlertDialog extends StatefulWidget {
  final String keyword;
  const _KeywordAlertDialog({required this.keyword});

  @override
  State<_KeywordAlertDialog> createState() => _KeywordAlertDialogState();
}

class _KeywordAlertDialogState extends State<_KeywordAlertDialog> {
  AlertType _selectedType = AlertType.promotion;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

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
              color: const Color(0xFF1B8A5A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search, size: 14, color: Color(0xFF1B8A5A)),
                const SizedBox(width: 6),
                Text(
                  '"${widget.keyword}"',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B8A5A),
                      fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text('Alarm für alle Produkte die diesen Begriff enthalten.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 16),
          RadioListTile<AlertType>(
            value: AlertType.promotion,
            groupValue: _selectedType,
            contentPadding: EdgeInsets.zero,
            activeColor: const Color(0xFF1B8A5A),
            title: const Text('Im Angebot',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Wenn ein passendes Produkt im Angebot ist'),
            onChanged: (v) => setState(() => _selectedType = v!),
          ),
          RadioListTile<AlertType>(
            value: AlertType.targetPrice,
            groupValue: _selectedType,
            contentPadding: EdgeInsets.zero,
            activeColor: const Color(0xFF1B8A5A),
            title: const Text('Zielpreis',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Wenn ein Produkt unter diesen Preis fällt'),
            onChanged: (v) => setState(() => _selectedType = v!),
          ),
          if (_selectedType == AlertType.targetPrice) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Zielpreis',
                prefixText: '€ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1B8A5A), width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
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
            double? targetPrice;
            if (_selectedType == AlertType.targetPrice) {
              targetPrice = double.tryParse(
                  _priceController.text.replaceAll(',', '.'));
              if (targetPrice == null) return;
            }
            final appState = context.read<AppState>();
            final messenger = ScaffoldMessenger.of(context);
            Navigator.pop(context);
            try {
              await appState.setKeywordAlert(
                keyword: widget.keyword,
                alertType: _selectedType,
                targetPrice: targetPrice,
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
