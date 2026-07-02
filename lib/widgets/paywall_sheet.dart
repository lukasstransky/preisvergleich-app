import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';

/// Shows the premium upsell as a modal bottom sheet. Call this whenever a
/// [PremiumRequiredException] is caught, or from an explicit "Upgrade" action.
Future<void> showPaywall(BuildContext context, {String? reason}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PaywallSheet(reason: reason),
  );
}

class PaywallSheet extends StatefulWidget {
  /// Optional context line explaining why the paywall appeared (e.g. the
  /// message from a [PremiumRequiredException]).
  final String? reason;
  const PaywallSheet({super.key, this.reason});

  @override
  State<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<PaywallSheet> {
  bool _busy = false;

  static const _benefits = [
    (Icons.notifications_active_rounded, 'Unbegrenzte Preisalarme',
        'Setze so viele Produkt- und Suchbegriff-Alarme wie du willst.'),
    (Icons.show_chart_rounded, 'Voller Preisverlauf',
        'Sieh die komplette Preis-Historie statt nur der letzten Tage.'),
    (Icons.playlist_add_check_rounded, 'Mehrere Einkaufslisten',
        'Organisiere deine Einkäufe in beliebig vielen Listen.'),
    (Icons.block_rounded, 'Keine Werbung',
        'Nutze die App komplett werbefrei.'),
  ];

  Future<void> _purchase() async {
    final appState = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final ok = await appState.startPremiumPurchase();
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context);
        messenger
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(
            content: Text('Premium freigeschaltet – viel Spaß!'),
            behavior: SnackBarBehavior.floating,
          ));
      }
    } catch (e) {
      if (!mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('$e'),
          behavior: SnackBarBehavior.floating,
        ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final appState = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final ok = await appState.restorePremium();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context);
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(ok ? 'Premium wiederhergestellt.' : 'Kein Kauf gefunden.'),
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [c.primary, const Color(0xFF177A50)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(height: 16),
            Text('Preisvergleich Premium',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: c.textPrimary)),
            if (widget.reason != null) ...[
              const SizedBox(height: 8),
              Text(widget.reason!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: c.textSecondary, height: 1.4)),
            ],
            const SizedBox(height: 20),
            ..._benefits.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(b.$1, color: c.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.$2,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: c.textPrimary)),
                            const SizedBox(height: 2),
                            Text(b.$3,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: c.textSecondary,
                                    height: 1.3)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _purchase,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Premium freischalten'),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: _busy ? null : _restore,
              child: Text('Kauf wiederherstellen',
                  style: TextStyle(color: c.textSecondary, fontSize: 13)),
            ),
            if (kDebugMode)
              Text('Debug-Build: „Freischalten“ schaltet Premium lokal ohne Kauf.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: c.textTertiary)),
          ],
        ),
      ),
    );
  }
}
