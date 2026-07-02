import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preisvergleich_app/services/premium_service.dart';

const _uid = 'test-uid';

PremiumService _makeService(FakeFirebaseFirestore firestore) =>
    PremiumService(firestore: firestore, getUid: () => _uid);

Future<void> _setConfig(FakeFirebaseFirestore fs, Map<String, dynamic> data) =>
    fs.collection('config').doc('monetization').set(data);

Future<void> _setEntitlement(
        FakeFirebaseFirestore fs, Map<String, dynamic> data) =>
    fs.collection('entitlements').doc(_uid).set(data);

void main() {
  group('PremiumConfig.fromMap', () {
    test('parses a full config', () {
      final c = PremiumConfig.fromMap({
        'monetizationEnabled': true,
        'freeAlertLimit': 5,
        'freeListLimit': 2,
        'priceHistoryFreeDays': 14,
      });
      expect(c.monetizationEnabled, isTrue);
      expect(c.freeAlertLimit, 5);
      expect(c.freeListLimit, 2);
      expect(c.priceHistoryFreeDays, 14);
    });

    test('falls back to defaults for missing keys', () {
      final c = PremiumConfig.fromMap({'monetizationEnabled': true});
      expect(c.monetizationEnabled, isTrue);
      expect(c.freeAlertLimit, PremiumConfig.defaults.freeAlertLimit);
      expect(c.freeListLimit, PremiumConfig.defaults.freeListLimit);
      expect(c.priceHistoryFreeDays, PremiumConfig.defaults.priceHistoryFreeDays);
    });
  });

  group('PremiumService.loadConfig', () {
    late FakeFirebaseFirestore fs;
    setUp(() => fs = FakeFirebaseFirestore());

    test('returns defaults (monetization off) when no config doc exists',
        () async {
      final config = await _makeService(fs).loadConfig();
      expect(config.monetizationEnabled, isFalse);
      expect(config.freeAlertLimit, PremiumConfig.defaults.freeAlertLimit);
    });

    test('reads the stored config doc', () async {
      await _setConfig(fs, {'monetizationEnabled': true, 'freeAlertLimit': 1});
      final config = await _makeService(fs).loadConfig();
      expect(config.monetizationEnabled, isTrue);
      expect(config.freeAlertLimit, 1);
    });
  });

  group('PremiumService.loadEntitlement', () {
    late FakeFirebaseFirestore fs;
    setUp(() => fs = FakeFirebaseFirestore());

    test('false when no entitlement doc exists', () async {
      expect(await _makeService(fs).loadEntitlement(), isFalse);
    });

    test('false when active is not true', () async {
      await _setEntitlement(fs, {'active': false});
      expect(await _makeService(fs).loadEntitlement(), isFalse);
    });

    test('true when active and no expiry', () async {
      await _setEntitlement(fs, {'active': true});
      expect(await _makeService(fs).loadEntitlement(), isTrue);
    });

    test('true when active and not yet expired', () async {
      await _setEntitlement(fs, {
        'active': true,
        'expiresAt': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 30))),
      });
      expect(await _makeService(fs).loadEntitlement(), isTrue);
    });

    test('false when the entitlement has expired', () async {
      await _setEntitlement(fs, {
        'active': true,
        'expiresAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 1))),
      });
      expect(await _makeService(fs).loadEntitlement(), isFalse);
    });
  });

  group('PremiumService.entitlementChanges', () {
    test('emits when the entitlement doc is written', () async {
      final fs = FakeFirebaseFirestore();
      final service = _makeService(fs);

      // The stream emits the current state first (no doc → false); wait for the
      // write to flip it to true.
      final future = service.entitlementChanges().firstWhere((v) => v);
      await _setEntitlement(fs, {'active': true});

      expect(await future, isTrue);
      service.dispose();
    });
  });
}
