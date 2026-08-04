import 'dart:async';
import 'dart:convert';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';

import '../core/ember_config.dart';
import '../core/ember_log.dart';
import 'ember_agent.dart';

/// Thin wrapper over the AppsFlyer SDK.
///
/// Responsibilities: start the SDK, collect the install-conversion / app-open /
/// deep-link payloads verbatim, and build the flat config-request body. The SDK
/// is started lazily (only after reachability is confirmed) so a first launch
/// with no route out never poisons a memoized failure (see lessons §25).
class TrailAttribution {
  TrailAttribution(this._agent);

  final EmberAgent _agent;

  final Map<String, dynamic> _conversion = {};
  final Map<String, dynamic> _appOpen = {};
  final Map<String, dynamic> _deepLink = {};

  final Completer<void> _conversionDone = Completer<void>();
  bool _started = false;
  String? _afId;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    final options = AppsFlyerOptions(
      afDevKey: EmberConfig.appsFlyerDevKey,
      appId: EmberConfig.iosStoreId,
      showDebug: false,
      timeToWaitForATTUserAuthorization: 0,
    );
    final sdk = AppsflyerSdk(options);

    sdk.onInstallConversionData((data) {
      final payload = _asMap(data['payload'] ?? data['data'] ?? data);
      _conversion
        ..clear()
        ..addAll(payload);
      emberLog(() => '[CFT.attr] conversion $payload');
      if (!_conversionDone.isCompleted) _conversionDone.complete();
    });
    sdk.onAppOpenAttribution((data) {
      _appOpen.addAll(_asMap(data['payload'] ?? data['data'] ?? data));
    });
    sdk.onDeepLinking((res) {
      final values = res.deepLink?.clickEvent;
      if (values != null) _deepLink.addAll(_asMap(values));
      emberLog(() => '[CFT.attr] deeplink ${res.deepLink?.clickEvent}');
    });

    await sdk.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );

    try {
      _afId = await sdk.getAppsFlyerUID();
    } catch (_) {/* uid best-effort */}
  }

  /// Waits for the conversion payload (or times out). Never throws.
  Future<void> awaitSignals({required Duration timeout}) async {
    try {
      await _conversionDone.future.timeout(timeout);
    } catch (_) {/* proceed with whatever arrived */}
    // Organic false-positive: AppsFlyer often reports `Organic` on the very
    // first launch before attribution resolves. Re-query the GCD API once and
    // WRITE the corrected data back into the payload — otherwise a real OneLink
    // user is shipped to the config as organic and misrouted to the white part
    // on the first launch (it only self-corrects on the next launch when the
    // SDK has cached the real attribution). Mirrors the template's _fetchGcd.
    if (_conversion.isEmpty || _conversion['af_status'] == 'Organic') {
      await Future.delayed(
        const Duration(seconds: EmberConfig.organicRecheckSeconds),
      );
      final corrected = await _fetchGcd();
      if (corrected != null && corrected.isNotEmpty) {
        _conversion
          ..clear()
          ..addAll(corrected);
        emberLog(() => '[CFT.attr] conversion replaced by GCD $corrected');
      }
    }
  }

  /// Server-side Get-Conversion-Data lookup. Returns the parsed attribution
  /// map (used to replace an Organic/empty first-launch conversion) or null.
  Future<Map<String, dynamic>?> _fetchGcd() async {
    final uid = _afId;
    if (uid == null || uid.isEmpty) return null;
    final base = EmberConfig.gcdBase;
    final sep = base.contains('?') ? '&' : '?';
    final url = '$base${sep}app_id=${EmberConfig.iosStoreId}&device_id=$uid';
    try {
      final res = await _agent.getJson(
        url,
        headers: {'Authorization': 'Bearer ${EmberConfig.appsFlyerDevKey}'},
        timeout: const Duration(seconds: 12),
      );
      emberLog(() => '[CFT.attr] GCD ${res.statusCode} ${res.body}');
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(res.body);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (e) {
      emberLog(() => '[CFT.attr] GCD failed $e');
      return null;
    }
  }

  String? get afId => _afId;

  /// Builds the flat request body: attribution (verbatim, first-write-wins)
  /// then device-side fields (overwrite). push_token / firebase_project_id are
  /// added by the caller only when a token is ready.
  Map<String, dynamic> buildPayload({
    required String locale,
    String? pushToken,
    String? idfa,
  }) {
    final body = <String, dynamic>{};
    body.addAll(_conversion);
    _appOpen.forEach((key, value) => body.putIfAbsent(key, () => value));
    _deepLink.forEach((key, value) => body.putIfAbsent(key, () => value));

    body['af_id'] = _afId ?? body['af_id'] ?? '';
    body['bundle_id'] = EmberConfig.bundleId;
    body['os'] = 'iOS';
    body['store_id'] = EmberConfig.platformStoreId;
    body['locale'] = locale;
    if (pushToken != null && pushToken.isNotEmpty) {
      body['push_token'] = pushToken;
      body['firebase_project_id'] = EmberConfig.firebaseProjectNumber;
    }
    if (idfa != null && idfa.isNotEmpty) {
      body['sub_id_10'] = idfa;
    }
    return body;
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{};
  }
}
