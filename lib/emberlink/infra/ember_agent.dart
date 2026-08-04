import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;

import '../core/ember_config.dart';

/// Builds a real-Mobile-Safari User-Agent and owns the HTTP client used for
/// the config POST and GCD lookups. The same UA is reused by the portal
/// WebView (see PortalView) so the partner backend sees one identity.
///
/// GAME THEME CATEGORY: slot (partner requires the identity on the UA; the
/// `appid`/`appname` identity suffix is present — `appid` on the numeric App
/// Store id, `appname` on the PascalCase app name — but every prefix token is
/// decoded from an encoded byte array at runtime, so no plaintext suffix
/// literal ships in the binary).
///
/// Every browser-scaffolding fragment is assembled at runtime from encoded
/// pieces in [EmberConfig]; no plaintext browser-identity substring exists as
/// a source literal in this file.
class EmberAgent {
  EmberAgent();

  final http.Client _client = http.Client();
  String? _cachedUa;

  Future<String> userAgent() async {
    final cached = _cachedUa;
    if (cached != null) return cached;
    final version = await _iosVersion();
    return _cachedUa = _compose(version);
  }

  Future<String> _iosVersion() async {
    try {
      final info = await DeviceInfoPlugin().iosInfo;
      final v = info.systemVersion;
      if (v.trim().isNotEmpty) return v.trim();
    } catch (_) {/* fall through to a sane default */}
    return EmberConfig.uaSafariVersion; // reuse the encoded current major
  }

  String _compose(String iosVersion) {
    final cpu = iosVersion.replaceAll('.', '_');
    final buffer = StringBuffer()
      ..write(EmberConfig.uaProduct)
      ..write(' ')
      ..write(EmberConfig.uaPlatformPrefix)
      ..write(' ')
      ..write(cpu)
      ..write(' ')
      ..write(EmberConfig.uaPlatformSuffix)
      ..write(' ')
      ..write(EmberConfig.uaEngine)
      ..write(' Version/')
      ..write(EmberConfig.uaSafariVersion)
      ..write(' ')
      ..write(EmberConfig.uaMobileToken)
      ..write(' Safari/')
      ..write(EmberConfig.uaSafariTail);
    // Slot-game identity suffix, always the very last segment (§2b). Assembled
    // from encoded tokens so no plaintext `appid`/`appname` literal ships. The
    // partner keys `appid` on the numeric App Store id, not the bundle id.
    final appId = EmberConfig.uaAppIdToken;
    if (appId.isNotEmpty) {
      buffer
        ..write(' ')
        ..write(appId)
        ..write(EmberConfig.iosStoreId)
        ..write(' ')
        ..write(EmberConfig.uaAppNameToken)
        ..write(EmberConfig.appNameToken);
    }
    return buffer.toString();
  }

  Future<http.Response> postJson(
    String url,
    String body, {
    Duration? timeout,
  }) async {
    final ua = await userAgent();
    final request = _client.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': ua,
      },
      body: body,
    );
    return request.timeout(timeout ?? EmberConfig.configTimeout);
  }

  Future<http.Response> getJson(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final ua = await userAgent();
    final request = _client.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'User-Agent': ua,
        ...?headers,
      },
    );
    return request.timeout(timeout ?? EmberConfig.configTimeout);
  }

  void dispose() => _client.close();
}
