import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let bundleId = Bundle.main.bundleIdentifier ?? "unknown"
    NSLog("[APNs] didFinishLaunching bundleId=\(bundleId) apsEnvironment=\(Self.apsEnvironment()) alreadyRegistered=\(application.isRegisteredForRemoteNotifications)")

    // Explicitly trigger APNs registration. With the new implicit-engine
    // AppDelegate, FirebaseMessaging's automatic registration (normally kicked off
    // by requestPermission) is not reliably invoked, so getAPNSToken() never
    // resolves. registerForRemoteNotifications() is idempotent and is the call that
    // actually makes iOS deliver the device token to the didRegister... callback.
    DispatchQueue.main.async {
      NSLog("[APNs] calling registerForRemoteNotifications()")
      application.registerForRemoteNotifications()
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // --- APNs diagnostics: log whether iOS actually delivers/denies the token ---
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
    NSLog("[APNs] ✅ didRegister OK, bytes=\(deviceToken.count) token=\(hex)")
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    let ns = error as NSError
    NSLog("[APNs] ❌ didFailToRegister domain=\(ns.domain) code=\(ns.code) desc=\(ns.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  /// Reads the `aps-environment` entitlement that is actually baked into the
  /// running binary (development / production / missing). This is the value iOS
  /// uses to decide whether to issue an APNs token, so it is the single most
  /// useful thing to know when the token comes back nil.
  private static func apsEnvironment() -> String {
    guard
      let path = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision"),
      let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
      let raw = String(data: data, encoding: .ascii),
      let start = raw.range(of: "<plist"),
      let end = raw.range(of: "</plist>")
    else {
      return "no-provisioning-profile(=App-Store/Simulator build?)"
    }
    let plistString = String(raw[start.lowerBound..<end.upperBound])
    guard
      let plistData = plistString.data(using: .utf8),
      let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any],
      let entitlements = plist["Entitlements"] as? [String: Any],
      let aps = entitlements["aps-environment"] as? String
    else {
      return "MISSING (no aps-environment entitlement → no token!)"
    }
    return aps
  }
}
