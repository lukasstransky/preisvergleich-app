import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/price_alert.dart';
import '../models/product.dart';

abstract class PriceAlertServiceBase {
  Future<List<PriceAlert>> getAlerts();
  Future<void> createAlert({
    required Product product,
    required AlertType alertType,
    double? targetPrice,
  });
  Future<void> createKeywordAlert({
    required String keyword,
    required AlertType alertType,
    double? targetPrice,
    String? category,
  });
  Future<void> deleteAlert(String alertId);
}

class PriceAlertService implements PriceAlertServiceBase {
  static const String _tokenKey = 'fcm_token';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<NotificationSettings> requestPermission() async {
    return _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<String?> getDeviceToken() async {
    try {
      // requestPermission() is idempotent: if permission was already granted it
      // returns the current status without re-prompting, but crucially it calls
      // registerForRemoteNotifications() on iOS every time. That registration is
      // what actually produces the APNs token, so it must run on *every* launch
      // and not only on first install -- otherwise getAPNSToken() stays null.
      if (kDebugMode) {
        debugPrint('[PriceAlert] ===== getDeviceToken() start =====');
        debugPrint('[PriceAlert] APNs auto-init enabled: ${_messaging.isAutoInitEnabled}');
        final settingsBefore = await _messaging.getNotificationSettings();
        debugPrint('[PriceAlert] Status BEFORE requestPermission: ${settingsBefore.authorizationStatus}');
      }

      // requestPermission() is idempotent: if permission was already granted it
      // returns the current status without re-prompting, but crucially it calls
      // registerForRemoteNotifications() on iOS every time. That registration is
      // what actually produces the APNs token, so it must run on *every* launch
      // and not only on first install -- otherwise getAPNSToken() stays null.
      final settings = await requestPermission();
      if (kDebugMode) debugPrint('[PriceAlert] Status AFTER requestPermission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        throw Exception(
            'Benachrichtigungen sind deaktiviert. Bitte aktiviere sie in den iPhone-Einstellungen unter Benachrichtigungen.');
      }

      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString(_tokenKey);

      if (token == null) {
        if (kDebugMode) debugPrint('[PriceAlert] No cached token, fetching APNs token...');
        final stopwatch = Stopwatch()..start();
        String? apnsToken;
        for (var attempt = 1; attempt <= 5; attempt++) {
          try {
            apnsToken = await _messaging.getAPNSToken();
          } catch (e) {
            if (kDebugMode) debugPrint('[PriceAlert] getAPNSToken() threw on attempt $attempt: $e');
          }
          if (apnsToken != null) {
            if (kDebugMode) {
              debugPrint('[PriceAlert] ✅ APNs token after ${stopwatch.elapsedMilliseconds}ms '
                  '(attempt $attempt): ${apnsToken.substring(0, apnsToken.length.clamp(0, 12))}...');
            }
            break;
          }
          if (kDebugMode) {
            debugPrint('[PriceAlert] APNs token still null (attempt $attempt/5, '
                '${stopwatch.elapsedMilliseconds}ms elapsed), retrying in 1s...');
          }
          await Future.delayed(const Duration(seconds: 1));
        }

        if (apnsToken == null) {
          if (kDebugMode) {
            debugPrint('[PriceAlert] ❌ APNs token NEVER arrived after ${stopwatch.elapsedMilliseconds}ms.');
          }
          throw Exception(
              'APNs-Token nicht verfügbar. Stelle sicher, dass Push-Benachrichtigungen in den iPhone-Einstellungen aktiviert sind.');
        }

        try {
          token = await _messaging.getToken();
        } catch (e) {
          if (kDebugMode) debugPrint('[PriceAlert] ❌ getToken() threw: $e');
          rethrow;
        }
        if (kDebugMode) {
          debugPrint('[PriceAlert] FCM token: ${token != null ? "✅ OK (${token.substring(0, 10)}...)" : "❌ null"}');
        }
        if (token != null) {
          await prefs.setString(_tokenKey, token);
        } else {
          throw Exception(
              'FCM-Token konnte nicht abgerufen werden. Stelle sicher, dass Benachrichtigungen erlaubt sind und du mit dem Internet verbunden bist.');
        }
      } else {
        if (kDebugMode) debugPrint('[PriceAlert] Using cached FCM token (${token.substring(0, 10)}...)');
      }

      _messaging.onTokenRefresh.listen((newToken) async {
        await prefs.setString(_tokenKey, newToken);
      });

      if (kDebugMode) debugPrint('[PriceAlert] ===== getDeviceToken() done OK =====');
      return token;
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('[PriceAlert] getDeviceToken() failed (Exception): $e');
      rethrow;
    } catch (e, stack) {
      if (kDebugMode) debugPrint('[PriceAlert] getDeviceToken() failed (unexpected): $e\n$stack');
      throw Exception('Push-Benachrichtigungen nicht verfügbar: $e');
    }
  }

  @override
  Future<List<PriceAlert>> getAlerts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // Try loading by userId first (supports cross-device sync)
    if (uid != null) {
      try {
        final snapshot = await _firestore
            .collection('price_alerts')
            .where('userId', isEqualTo: uid)
            .where('active', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();
        if (snapshot.docs.isNotEmpty) {
          debugPrint('[PriceAlert] Loaded ${snapshot.docs.length} alerts by userId');
          return snapshot.docs.map((doc) => PriceAlert.fromFirestore(doc)).toList();
        }
      } catch (e) {
        debugPrint('[PriceAlert] getAlerts by userId error: $e');
      }
    }

    // Fall back to deviceToken for alerts created before userId was added
    String? token;
    try {
      token = await getDeviceToken();
    } catch (e) {
      debugPrint('[PriceAlert] getAlerts: token unavailable ($e), returning []');
      return [];
    }
    if (token == null) return [];

    try {
      final snapshot = await _firestore
          .collection('price_alerts')
          .where('deviceToken', isEqualTo: token)
          .where('active', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      debugPrint('[PriceAlert] Loaded ${snapshot.docs.length} alerts by deviceToken');
      return snapshot.docs.map((doc) => PriceAlert.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('[PriceAlert] Firestore getAlerts error: $e');
      rethrow;
    }
  }

  Future<PriceAlert?> getAlertForProduct(String productId) async {
    final token = await getDeviceToken();
    if (token == null) return null;

    final snapshot = await _firestore
        .collection('price_alerts')
        .where('deviceToken', isEqualTo: token)
        .where('productId', isEqualTo: productId)
        .where('active', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return PriceAlert.fromFirestore(snapshot.docs.first);
  }

  Future<String> _requireUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Anonymous sign-in may still be in flight (it's fire-and-forget in main.dart).
      // Wait up to 10 s for auth to settle before giving up.
      user = await FirebaseAuth.instance
          .authStateChanges()
          .where((u) => u != null)
          .first
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => null,
          );
    }
    if (user == null) {
      throw Exception('Nicht angemeldet. Bitte starte die App neu.');
    }
    return user.uid;
  }

  @override
  Future<void> createAlert({
    required Product product,
    required AlertType alertType,
    double? targetPrice,
  }) async {
    final token = await getDeviceToken(); // throws with descriptive message if unavailable
    final userId = await _requireUserId();

    final alert = PriceAlert(
      id: '',
      productId: product.id,
      productName: product.name,
      supermarket: product.supermarket,
      imageUrl: product.imageUrl,
      currentPrice: product.price,
      alertType: alertType,
      targetPrice: targetPrice,
      createdAt: DateTime.now(),
    );

    debugPrint('[PriceAlert] Creating alert for product ${product.id}...');
    await _firestore.collection('price_alerts').add(alert.toFirestore(token!, userId: userId));
    debugPrint('[PriceAlert] Alert created successfully');
  }

  @override
  Future<void> createKeywordAlert({
    required String keyword,
    required AlertType alertType,
    double? targetPrice,
    String? category,
  }) async {
    final token = await getDeviceToken();
    final userId = await _requireUserId();

    final alert = PriceAlert(
      id: '',
      productId: '',
      productName: keyword,
      supermarket: '',
      currentPrice: 0,
      alertType: alertType,
      targetPrice: targetPrice,
      createdAt: DateTime.now(),
      scope: AlertScope.keyword,
      keyword: keyword.toLowerCase(),
      category: category,
    );

    await _firestore.collection('price_alerts').add(alert.toFirestore(token!, userId: userId));
  }

  @override
  Future<void> deleteAlert(String alertId) async {
    await _firestore
        .collection('price_alerts')
        .doc(alertId)
        .update({'active': false});
  }
}
