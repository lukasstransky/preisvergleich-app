import 'package:preisvergleich_app/services/premium_service.dart';

/// Test double for [PremiumServiceBase] that lets a test pin the monetization
/// config and entitlement without touching Firestore or a real store.
class FakePremiumService implements PremiumServiceBase {
  final PremiumConfig config;
  bool premium;

  FakePremiumService({PremiumConfig? config, this.premium = false})
      : config = config ?? PremiumConfig.defaults;

  @override
  Future<PremiumConfig> loadConfig() async => config;

  @override
  Future<bool> loadEntitlement() async => premium;

  @override
  Stream<bool> entitlementChanges() => const Stream<bool>.empty();

  @override
  Future<bool> startPurchase() async => premium = true;

  @override
  Future<bool> restorePurchases() async => premium;

  @override
  void dispose() {}
}
