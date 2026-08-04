import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../core/ember_config.dart';
import '../core/ember_log.dart';
import 'ember_vault.dart';

/// Owns Firebase Messaging: APNs/FCM token warmup, permission prompt, and
/// routing a URL carried by a tapped push into the live portal. (The killed-app
/// cold-start tap is handled natively by SceneDelegate + ColdTapReader.)
class SignalHub {
  SignalHub(this._vault);

  final EmberVault _vault;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  bool _requesting = false;
  bool _initialChecked = false;

  /// Set by the live [PortalView] so a push tapped while it is on screen loads
  /// the URL directly into the WebView. When null (no portal live), a tapped
  /// push URL is stashed for the next portal entry instead.
  void Function(String url)? onDestination;

  /// Warms the token subsystem and the push-tap routing. Idempotent: safe to
  /// call from both the routing pipeline and the portal. [onToken] fires
  /// whenever a fresh token becomes available so the caller can re-POST config.
  Future<void> bootstrap({void Function(String token)? onToken}) async {
    try {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {/* non-fatal */}

    // A push that launched the app (warm start through Firebase's swizzle,
    // not the killed-app SceneDelegate path) surfaces here once. Stash it so
    // the next portal entry consumes it.
    if (!_initialChecked) {
      _initialChecked = true;
      try {
        final initial = await _messaging.getInitialMessage();
        final url = _extractUrl(initial);
        if (url != null) await _vault.stashPushUrl(url);
      } catch (_) {/* best effort */}
    }

    _openedSub ??= FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final url = _extractUrl(message);
      if (url == null) return;
      final callback = onDestination;
      if (callback != null) {
        callback(url);
      } else {
        unawaited(_vault.stashPushUrl(url));
      }
    });

    if (onToken != null) {
      _tokenSub ??= _messaging.onTokenRefresh.listen((token) {
        if (token.isNotEmpty) onToken(token);
      });
    }
  }

  /// iOS returns a null FCM token until APNs registers; poll the APNs token
  /// first, then read the FCM token. Counts/steps are project-unique.
  Future<String?> awaitToken() async {
    for (var i = 0; i < EmberConfig.apnsPollCount; i++) {
      try {
        final apns = await _messaging.getAPNSToken();
        if (apns != null && apns.isNotEmpty) break;
      } catch (_) {/* keep polling */}
      await Future.delayed(
        const Duration(milliseconds: EmberConfig.apnsPollStepMs),
      );
    }
    try {
      return await _messaging.getToken();
    } catch (e) {
      emberLog(() => '[CFT.push] getToken failed $e');
      return null;
    }
  }

  /// Presents the system push permission dialog. Returns true if authorized.
  Future<bool> requestConsent() async {
    if (_requesting) return false;
    _requesting = true;
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      emberLog(() => '[CFT.push] requestPermission failed $e');
      return false;
    } finally {
      _requesting = false;
    }
  }

  static String? _extractUrl(RemoteMessage? message) {
    if (message == null) return null;
    return _extractFrom(message.data);
  }

  static String? _extractFrom(Map<String, dynamic> payload) {
    const keys = ['deep_link', 'target', 'url', 'deeplink', 'link'];
    for (final key in keys) {
      final value = payload[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    // Some senders nest the link under `data` / `payload`.
    for (final container in const ['payload', 'data']) {
      final nested = payload[container];
      if (nested is Map) {
        final found = _extractFrom(
          nested.map((k, v) => MapEntry(k.toString(), v)),
        );
        if (found != null) return found;
      }
    }
    return null;
  }
}
