import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product.dart';
import '../models/price_alert.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import 'price_history_chart.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  static const _primary = AppColors.primary;

  Color _supermarketColor(String s) => AppColors.supermarket(s);

  bool _lightText(String s) => !AppColors.supermarketNeedsDarkText(s);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isInList = appState.isInShoppingList(product.id);
    final isFav = appState.isFavorite(product.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showProductDetails(context),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImage(context),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInfo()),
                  const SizedBox(width: 8),
                  _buildActionColumn(context, isInList, isFav),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final appState = context.watch<AppState>();
    final hasAlert = appState.hasAlert(product.id);
    final isFav = appState.isFavorite(product.id);

    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox.expand(
              child: product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
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
                        child: const Icon(Icons.shopping_basket_outlined,
                            color: AppColors.textTertiary, size: 28),
                      ),
                    )
                  : Container(
                      color: AppColors.surfaceAlt,
                      child: const Icon(Icons.shopping_basket_outlined,
                          color: AppColors.textTertiary, size: 28),
                    ),
            ),
          ),
          if (product.inPromotion)
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: const Text('SALE',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
              ),
            ),
          if (hasAlert)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: const Icon(Icons.notifications_active_rounded,
                    color: Colors.white, size: 11),
              ),
            ),
          if (isFav)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(10),
                    topLeft: Radius.circular(8),
                  ),
                ),
                child: const Icon(Icons.favorite_rounded,
                    color: Colors.white, size: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfo() {
    final color = _supermarketColor(product.supermarket);
    final light = _lightText(product.supermarket);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textPrimary,
            height: 1.3,
            letterSpacing: -0.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                product.supermarketDisplayName,
                style: TextStyle(
                  color: light ? Colors.white : Colors.black87,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            if (product.promotionText != null) ...[
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.promoSoft,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  product.promotionText!,
                  style: const TextStyle(
                    color: AppColors.promo,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              product.formattedPrice,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: product.inPromotion
                    ? AppColors.danger
                    : AppColors.textPrimary,
                letterSpacing: -0.5,
                height: 1,
              ),
            ),
            if (product.originalPrice != null) ...[
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(
                  product.formattedOriginalPrice!,
                  style: TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: AppColors.textTertiary,
                    fontSize: 12,
                    height: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (product.formattedUnitPrice != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              product.formattedUnitPrice!,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                letterSpacing: -0.1,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionColumn(BuildContext context, bool isInList, bool isFav) {
    final appState = context.read<AppState>();

    final favBtn = GestureDetector(
      onTap: () => appState.toggleFavorite(product),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 18,
          color: isFav ? AppColors.danger : AppColors.textTertiary,
        ),
      ),
    );

    if (!isInList) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: GestureDetector(
              onTap: () {
                appState.addToShoppingList(product);
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(SnackBar(
                    content: Text('${product.name} hinzugefügt',
                        style: const TextStyle(fontSize: 13)),
                    duration: const Duration(milliseconds: 1500),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ));
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: AppColors.onPrimary, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 4),
          favBtn,
        ],
      );
    }

    final quantity = context.watch<AppState>().getQuantity(product.id);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Container(
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QtyBtn(
                  icon: quantity == 1
                      ? Icons.delete_outline_rounded
                      : Icons.remove_rounded,
                  color: quantity == 1
                      ? AppColors.danger
                      : AppColors.textSecondary,
                  onTap: () => appState.decrementQuantity(product.id),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '$quantity',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: _primary),
                  ),
                ),
                _QtyBtn(
                  icon: Icons.add_rounded,
                  color: _primary,
                  onTap: () => appState.incrementQuantity(product.id),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        favBtn,
      ],
    );
  }

  void _showProductDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _ProductDetailSheet(product: product),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QtyBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ── Detail sheet ─────────────────────────────────────────────────────────────

class _ProductDetailSheet extends StatelessWidget {
  final Product product;

  const _ProductDetailSheet({required this.product});

  Color _supermarketColor(String s) => AppColors.supermarket(s);

  bool _lightText(String s) => !AppColors.supermarketNeedsDarkText(s);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (_, appState, _) {
        final alert = appState.getAlert(product.id);
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (product.imageUrl != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      height: 140,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                        if (product.brand != null) ...[
                          const SizedBox(height: 4),
                          Text(product.brand!,
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _supermarketColor(product.supermarket),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      product.supermarketDisplayName,
                      style: TextStyle(
                        color: _lightText(product.supermarket)
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    product.formattedPrice,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: product.inPromotion
                          ? AppColors.danger
                          : AppColors.textPrimary,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),
                  if (product.originalPrice != null) ...[
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        product.formattedOriginalPrice!,
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textTertiary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (product.formattedUnitPrice != null)
                    Text(
                      product.formattedUnitPrice!,
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13),
                    ),
                ],
              ),
              if (product.category != null) ...[
                const SizedBox(height: 10),
                Text(
                  product.category!,
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                ),
              ],
              if (product.formattedOfferPeriod != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 13, color: AppColors.textTertiary),
                    const SizedBox(width: 5),
                    Text(
                      'Angebot: ${product.formattedOfferPeriod!}',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
              if (product.productUrl != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text(
                      'Auf ${product.supermarketDisplayName} ansehen',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final uri = Uri.tryParse(product.productUrl!);
                      if (uri != null) await launchUrl(uri);
                    },
                  ),
                ),
              ],
              PriceHistoryChart(product: product),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
              if (alert != null)
                _ActiveAlertRow(
                    sheetContext: context, appState: appState, alert: alert,
                    product: product)
              else
                _SetAlertButton(
                    context: context, product: product),
            ],
          ),
          ),
        );
      },
    );
  }
}

class _ActiveAlertRow extends StatelessWidget {
  final BuildContext sheetContext;
  final AppState appState;
  final PriceAlert alert;
  final Product product;

  const _ActiveAlertRow({
    required this.sheetContext,
    required this.appState,
    required this.alert,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_active_rounded,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Preisalarm aktiv',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
                Text(alert.alertDescription,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () async {
              await appState.removePriceAlert(alert.id, product.id);
              if (sheetContext.mounted) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(
                      content: Text('Preisalarm entfernt'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(milliseconds: 1500)),
                );
              }
            },
            child: const Text('Entfernen',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _SetAlertButton extends StatelessWidget {
  final BuildContext context;
  final Product product;

  const _SetAlertButton({required this.context, required this.product});

  @override
  Widget build(BuildContext _) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.notifications_none_rounded, size: 18),
        label: const Text('Preisalarm setzen',
            style: TextStyle(fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: () => showDialog(
          context: context,
          builder: (_) => _AlertDialog(product: product),
        ),
      ),
    );
  }
}

// ── Alert dialog ─────────────────────────────────────────────────────────────

class _AlertDialog extends StatefulWidget {
  final Product product;
  const _AlertDialog({required this.product});

  @override
  State<_AlertDialog> createState() => _AlertDialogState();
}

class _AlertDialogState extends State<_AlertDialog> {
  AlertType _type = AlertType.promotion;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController(
        text: widget.product.price.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      title: const Text('Preisalarm',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18,
              letterSpacing: -0.4)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.product.name,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 16),
          _AlertOption(
            value: AlertType.promotion,
            group: _type,
            title: 'Im Angebot',
            subtitle: 'Wenn das Produkt reduziert ist',
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 8),
          _AlertOption(
            value: AlertType.targetPrice,
            group: _type,
            title: 'Zielpreis',
            subtitle: 'Wenn der Preis unter deinen Wert fällt',
            onChanged: (v) => setState(() => _type = v!),
          ),
          if (_type == AlertType.targetPrice) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Zielpreis',
                prefixText: '€ ',
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Abbrechen',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () async {
            double? tp;
            if (_type == AlertType.targetPrice) {
              tp = double.tryParse(_priceCtrl.text.replaceAll(',', '.'));
              if (tp == null) return;
            }
            // Read AppState and ScaffoldMessenger BEFORE popping
            final appState = context.read<AppState>();
            final messenger = ScaffoldMessenger.of(context);
            Navigator.pop(context);
            try {
              await appState.setPriceAlert(
                product: widget.product,
                alertType: _type,
                targetPrice: tp,
              );
              messenger
                ..clearSnackBars()
                ..showSnackBar(const SnackBar(
                    content: Text('Preisalarm gespeichert'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(milliseconds: 2000)));
            } catch (e) {
              messenger
                ..clearSnackBars()
                ..showSnackBar(SnackBar(
                    content: Text('Fehler: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating));
            }
          },
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}

class _AlertOption extends StatelessWidget {
  final AlertType value;
  final AlertType group;
  final String title;
  final String subtitle;
  final ValueChanged<AlertType?> onChanged;

  const _AlertOption({
    required this.value,
    required this.group,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == group;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.35)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.textTertiary,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
