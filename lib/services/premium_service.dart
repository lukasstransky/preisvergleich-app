import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Thrown when a free-tier user hits a gated limit. The UI catches this and
/// shows the paywall instead of a generic error.
class PremiumRequiredException implements Exception {
  /// Which capability was gated, e.g. `alerts` or `lists`. Useful for analytics
  /// and for the paywall to highlight the relevant benefit.
  final String feature;
  final String message;
  const PremiumRequiredException(this.feature, this.message);

  @override
  String toString() => message;
}

/// Remote-controlled monetization config, stored in Firestore at
/// `config/monetization`. Kept server-side so the free-tier limits can be tuned
/// — and monetization switched on entirely — without shipping an app update.
///
/// Ships **disabled** by default so a fresh install (and every test) behaves
/// exactly like today: nothing is gated. Flip `monetizationEnabled` in Firestore
/// once there is a user base worth converting.
@immutable
class PremiumConfig {
  final bool monetizationEnabled;
  final int freeAlertLimit;
  final int freeListLimit;
  final int priceHistoryFreeDays;

  const PremiumConfig({
    this.monetizationEnabled = false,
    this.freeAlertLimit = 3,
    this.freeListLimit = 1,
    this.priceHistoryFreeDays = 7,
  });

  static const PremiumConfig defaults = PremiumConfig();

  factory PremiumConfig.fromMap(Map<String, dynamic> m) => PremiumConfig(
        monetizationEnabled: m['monetizationEnabled'] as bool? ?? false,
        freeAlertLimit: (m['freeAlertLimit'] as num?)?.toInt() ?? 3,
        freeListLimit: (m['freeListLimit'] as num?)?.toInt() ?? 1,
        priceHistoryFreeDays: (m['priceHistoryFreeDays'] as num?)?.toInt() ?? 7,
      );
}

abstract class PremiumServiceBase {
  /// Loads the remote monetization config (falls back to [PremiumConfig.defaults]).
  Future<PremiumConfig> loadConfig();

  /// One-shot read of the current user's entitlement.
  Future<bool> loadEntitlement();

  /// Live entitlement updates (e.g. right after a purchase webhook lands).
  Stream<bool> entitlementChanges();

  /// Starts the in-app purchase flow. Returns `true` if the user is premium
  /// afterwards.
  Future<bool> startPurchase();

  /// Restores a previous purchase. Returns `true` if premium was restored.
  Future<bool> restorePurchases();

  void dispose();
}

/// Default no-op implementation used in tests and when a real backend is not
/// wired. Monetization is disabled and the user is never premium, so no code
/// path is gated. The real [PremiumService] is injected in `main.dart`.
class DisabledPremiumService implements PremiumServiceBase {
  const DisabledPremiumService();

  @override
  Future<PremiumConfig> loadConfig() async => PremiumConfig.defaults;

  @override
  Future<bool> loadEntitlement() async => false;

  @override
  Stream<bool> entitlementChanges() => const Stream<bool>.empty();

  @override
  Future<bool> startPurchase() async => false;

  @override
  Future<bool> restorePurchases() async => false;

  @override
  void dispose() {}
}

/// Firestore-backed entitlement + config.
///
/// The entitlement (`entitlements/{uid}`) is the single source of truth and is
/// **written only by the server** (the RevenueCat webhook Cloud Function). The
/// client can read it but never write it, so premium cannot be spoofed by a
/// modified app. See `docs/monetization.md`.
class PremiumService implements PremiumServiceBase {
  PremiumService({
    FirebaseFirestore? firestore,
    String? Function()? getUid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _getUid = getUid ?? (() => FirebaseAuth.instance.currentUser?.uid);

  final FirebaseFirestore _firestore;
  final String? Function() _getUid;

  /// Debug-only local override so gating can be tested without a real purchase.
  bool? _debugOverride;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _docSub;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  DocumentReference<Map<String, dynamic>>? get _entitlementDoc {
    final uid = _getUid();
    if (uid == null) return null;
    return _firestore.collection('entitlements').doc(uid);
  }

  bool _isActive(Map<String, dynamic>? data) {
    if (_debugOverride != null) return _debugOverride!;
    if (data == null || data['active'] != true) return false;
    final expires = data['expiresAt'];
    if (expires is Timestamp && expires.toDate().isBefore(DateTime.now())) {
      return false;
    }
    return true;
  }

  @override
  Future<PremiumConfig> loadConfig() async {
    try {
      final snap =
          await _firestore.collection('config').doc('monetization').get();
      if (!snap.exists || snap.data() == null) return PremiumConfig.defaults;
      return PremiumConfig.fromMap(snap.data()!);
    } catch (e) {
      if (kDebugMode) debugPrint('[Premium] loadConfig failed: $e');
      return PremiumConfig.defaults;
    }
  }

  @override
  Future<bool> loadEntitlement() async {
    if (_debugOverride != null) return _debugOverride!;
    final doc = _entitlementDoc;
    if (doc == null) return false;
    try {
      final snap = await doc.get();
      return _isActive(snap.data());
    } catch (e) {
      if (kDebugMode) debugPrint('[Premium] loadEntitlement failed: $e');
      return false;
    }
  }

  @override
  Stream<bool> entitlementChanges() {
    _docSub?.cancel();
    final doc = _entitlementDoc;
    if (doc != null) {
      _docSub = doc.snapshots().listen(
        (snap) => _controller.add(_isActive(snap.data())),
        onError: (_) {},
      );
    }
    return _controller.stream;
  }

  /// Debug-only: flip premium locally to exercise the gating and paywall
  /// without a configured store. No effect in release builds.
  void setDebugPremium(bool value) {
    if (!kDebugMode) return;
    _debugOverride = value;
    _controller.add(value);
  }

  @override
  Future<bool> startPurchase() async {
    // TODO(revenuecat): wire purchases_flutter here. The purchase itself and
    // the entitlement grant are handled by RevenueCat + its webhook Cloud
    // Function, which writes `entitlements/{uid}`. See docs/monetization.md.
    //
    //   final offerings = await Purchases.getOfferings();
    //   final pkg = offerings.current?.availablePackages.first;
    //   final info = await Purchases.purchasePackage(pkg!);
    //   return info.entitlements.active.containsKey('premium');
    if (kDebugMode) {
      setDebugPremium(true);
      return true;
    }
    throw const PremiumRequiredException(
        'purchase', 'In-App-Kauf ist noch nicht konfiguriert.');
  }

  @override
  Future<bool> restorePurchases() async {
    // TODO(revenuecat): final info = await Purchases.restorePurchases();
    if (kDebugMode) {
      setDebugPremium(true);
      return true;
    }
    return loadEntitlement();
  }

  @override
  void dispose() {
    _docSub?.cancel();
    _controller.close();
  }
}
