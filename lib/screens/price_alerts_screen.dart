import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/price_alert.dart';
import '../theme/app_colors.dart';

class PriceAlertsScreen extends StatelessWidget {
  final VoidCallback? onGoToSearch;

  const PriceAlertsScreen({super.key, this.onGoToSearch});

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
            return Column(
              children: [
                _SearchPromoBanner(onGoToSearch: onGoToSearch),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.notifications_none,
                              size: 40, color: AppColors.textTertiary),
                        ),
                        const SizedBox(height: 16),
                        const Text('Keine Preisalarme',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        Text(
                          'Tippe auf ein Produkt und setze einen\nPreisalarm um benachrichtigt zu werden.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length + 1,
            separatorBuilder: (_, index) =>
                index == 0 ? const SizedBox.shrink() : const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SearchPromoBanner(onGoToSearch: onGoToSearch),
                );
              }
              return _AlertTile(alert: alerts[index - 1]);
            },
          );
        },
      ),
    );
  }
}

class _SearchPromoBanner extends StatelessWidget {
  final VoidCallback? onGoToSearch;

  const _SearchPromoBanner({this.onGoToSearch});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF177A50)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_active_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kein Angebot mehr verpassen!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Produkt oder Suchbegriff speichern & sofort benachrichtigt werden.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onGoToSearch,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Zur Suche',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final PriceAlert alert;

  const _AlertTile({required this.alert});

  Color _getSupermarketColor(String supermarket) => AppColors.supermarket(supermarket);

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
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.search, color: AppColors.primary, size: 28),
              )
            else if (alert.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: CachedNetworkImage(
                    imageUrl: alert.imageUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      color: AppColors.surfaceAlt,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                    errorWidget: (_, _, _) => Container(
                      color: AppColors.surfaceAlt,
                      child: const Icon(Icons.shopping_basket, color: AppColors.textTertiary),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shopping_basket, color: AppColors.textTertiary),
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
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            'Suchbegriff',
                            style: TextStyle(
                                color: AppColors.primary,
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
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        alert.alertDescription,
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  if (!alert.isKeywordAlert) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Aktuell: €${alert.currentPrice.toStringAsFixed(2)}',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.notifications_off_outlined,
                  color: AppColors.danger, size: 22),
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
