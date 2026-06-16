import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/price_alert.dart';

class PriceAlertsScreen extends StatelessWidget {
  const PriceAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preisalarme'),
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          final alerts = appState.priceAlerts;

          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.notifications_none,
                        size: 40, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 16),
                  const Text('Keine Preisalarme',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    'Tippe auf ein Produkt und setze einen\nPreisalarm um benachrichtigt zu werden.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return _AlertTile(alert: alert);
            },
          );
        },
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final PriceAlert alert;

  const _AlertTile({required this.alert});

  Color _getSupermarketColor(String supermarket) {
    switch (supermarket.toLowerCase()) {
      case 'spar':
        return const Color(0xFF006633);
      case 'billa':
        return const Color(0xFFFFCC00);
      case 'hofer':
        return const Color(0xFF004A99);
      case 'penny':
        return const Color(0xFFCD1719);
      case 'lidl':
        return const Color(0xFF0050AA);
      case 'mpreis':
        return const Color(0xFFE30613);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (alert.isKeywordAlert)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B8A5A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.search, color: Color(0xFF1B8A5A), size: 28),
              )
            else if (alert.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: CachedNetworkImage(
                    imageUrl: alert.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.shopping_basket, color: Colors.grey),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shopping_basket, color: Colors.grey),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.isKeywordAlert
                        ? '"${alert.keyword ?? alert.productName}"'
                        : alert.productName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (alert.isKeywordAlert)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B8A5A).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: const Color(0xFF1B8A5A).withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            'Suchbegriff',
                            style: TextStyle(
                                color: Color(0xFF1B8A5A),
                                fontSize: 9,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getSupermarketColor(alert.supermarket),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            alert.supermarket.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      const SizedBox(width: 6),
                      Icon(
                        alert.alertType == AlertType.promotion
                            ? Icons.local_offer_outlined
                            : Icons.price_check,
                        size: 13,
                        color: const Color(0xFF1B8A5A),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        alert.alertDescription,
                        style: const TextStyle(
                            color: Color(0xFF1B8A5A),
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  if (!alert.isKeywordAlert) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Aktuell: €${alert.currentPrice.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.notifications_off_outlined,
                  color: Colors.red, size: 22),
              tooltip: 'Alarm entfernen',
              onPressed: () async {
                if (alert.isKeywordAlert) {
                  await appState.removeKeywordAlert(alert.id, alert.keyword ?? '');
                } else {
                  await appState.removePriceAlert(alert.id, alert.productId);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(const SnackBar(
                      content: Text('Preisalarm entfernt'),
                      duration: Duration(milliseconds: 1500),
                      behavior: SnackBarBehavior.floating,
                    ));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
