import Flutter
import UIKit

/// Captures a cold-start push tap (app was killed). iOS delivers that tap here,
/// NOT through Firebase's swizzled path (getInitialMessage returns nil), so we
/// extract the URL from the notification payload and stash it in UserDefaults
/// under `flutter.cft_launch_route`. Dart's ColdTapReader consumes it first
/// thing on boot. The `flutter.` prefix bridges UserDefaults ↔ SharedPreferences.
class SceneDelegate: FlutterSceneDelegate {
  static let tapUrlKey = "flutter.cft_launch_route"

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    if let response = connectionOptions.notificationResponse {
      captureTapUrl(from: response.notification.request.content.userInfo)
    }
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }

  private func captureTapUrl(from userInfo: [AnyHashable: Any]) {
    guard let url = Self.extractUrl(userInfo), !url.isEmpty else { return }
    UserDefaults.standard.set(url, forKey: Self.tapUrlKey)
  }

  static func extractUrl(_ userInfo: [AnyHashable: Any]) -> String? {
    let keys = ["url", "link", "target", "deeplink", "deep_link"]
    for key in keys {
      if let value = userInfo[key] as? String, !value.isEmpty { return value }
    }
    // Some senders nest the payload under `data` / `payload`.
    for container in ["data", "payload"] {
      if let nested = userInfo[container] as? [AnyHashable: Any] {
        for key in keys {
          if let value = nested[key] as? String, !value.isEmpty { return value }
        }
      }
    }
    return nil
  }
}
