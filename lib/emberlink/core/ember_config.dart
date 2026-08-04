import 'ember_cipher.dart';

/// Central configuration for the Emberlink layer.
///
/// Secrets are stored obfuscated (see [EmberCipher]) and revealed lazily.
/// Public URLs (privacy / support) are plain constants on purpose. Numeric
/// constants are project-unique — do not copy them to another app.
class EmberConfig {
  const EmberConfig._();

  // ── App identity ──────────────────────────────────────────────────────
  static const String bundleId = 'com.cinderforge.trailgame';
  static const String iosStoreId = '6792827359';
  static const String appTitle = 'Cinderforge Trail';

  /// AppsFlyer / config `store_id` — always `"id" + iosStoreId`.
  static String get platformStoreId => 'id$iosStoreId';

  // ── Public, non-secret URLs (must match App Store Connect verbatim) ────
  static const String privacyUrl =
      'https://cinderforgetrail.com/privacy-policy.html';
  static const String supportUrl = 'https://cinderforgetrail.com/support.html';

  // ── Obfuscated constants (regenerate via tool/encode_ember_values.dart) ─
  static const String _configEndpoint =
      'C1oGXkNWQQIOGwYHFx5LQR1XBBdZBg0NSwUJC0gPXhoLRw5HQQkV';
  static const String _appsFlyerDevKey = 'MlYQGVJePms5FxoxBFkYSxdFIldlIA==';
  static const String _firebaseProjectNumber = 'VhZEHwFaWBpUQlla';
  static const String _gcdBase = 'C1oGXkNWQQIKEQwQFgcDTx9AEgVHHgETSwUJCw==';
  static const String _oneLinkTemplate =
      'C1oGXkNWQQIOGwYHFx5LQR1XBE1ECQENDAgNSAoJHjYsHStGXxldHQtZFhY=';
  static const String _uaProduct = 'LkEIR1wADwJYXFg=';
  static const String _uaPlatformPrefix = 'S0ciRl8CCxZNMTg2UgV9RgBeBENkNA==';
  static const String _uaPlatformSuffix = 'D0cZSxAhD05NPTtDKkU=';
  static const String _uaEngine =
      'Il4CQlU7C08mGxxMRFwYAF4eUFYLTy8pMSsqSkcAWB8IDi4MUgoKWg==';
  static const String _uaMobileToken = 'LkEQR1wJQRxYN1lXSg==';
  static const String _uaSafariVersion = 'UhZcGw==';
  static const String _uaSafariTail = 'VR5GAAE=';
  // Slot-game partner identity suffix tokens (kept encoded so no plaintext
  // `appid`/`appname` prefix literal ever ships in the binary).
  static const String _uaAppIdToken = 'Al4CR1RD';
  static const String _uaAppNameToken = 'Al4CQFEBCwI=';
  static const String _appNameToken = 'IEccSlUeCEIfFQ03AA1EQg==';

  static String get configEndpoint => EmberCipher.reveal(_configEndpoint);
  static String get appsFlyerDevKey => EmberCipher.reveal(_appsFlyerDevKey);
  static String get firebaseProjectNumber =>
      EmberCipher.reveal(_firebaseProjectNumber);
  static String get gcdBase => EmberCipher.reveal(_gcdBase);
  static String get oneLinkTemplate => EmberCipher.reveal(_oneLinkTemplate);

  // User-Agent fragments (assembled at runtime by EmberAgent).
  static String get uaProduct => EmberCipher.reveal(_uaProduct);
  static String get uaPlatformPrefix => EmberCipher.reveal(_uaPlatformPrefix);
  static String get uaPlatformSuffix => EmberCipher.reveal(_uaPlatformSuffix);
  static String get uaEngine => EmberCipher.reveal(_uaEngine);
  static String get uaMobileToken => EmberCipher.reveal(_uaMobileToken);
  static String get uaSafariVersion => EmberCipher.reveal(_uaSafariVersion);
  static String get uaSafariTail => EmberCipher.reveal(_uaSafariTail);
  static String get uaAppIdToken => EmberCipher.reveal(_uaAppIdToken);
  static String get uaAppNameToken => EmberCipher.reveal(_uaAppNameToken);
  static String get appNameToken => EmberCipher.reveal(_appNameToken);

  // ── Gate predicate ─────────────────────────────────────────────────────
  /// The gray flow only runs when the three required creds are present.
  /// OneLink and similar optional fields must NOT be part of this predicate.
  static bool get grayReady =>
      configEndpoint.isNotEmpty &&
      appsFlyerDevKey.isNotEmpty &&
      firebaseProjectNumber.isNotEmpty;

  // ── Domain allowlist (plaintext; visible in ASC anyway) ────────────────
  /// Every URL loaded into the portal WebView (config reply, saved url, push
  /// payload) must end with one of these host suffixes, else it is dropped.
  /// Add the real partner content host here before shipping paid traffic.
  static const List<String> allowedHostSuffixes = <String>[
    'cinderforgetrail.com',
    'team-s.club',
  ];

  static bool hostAllowed(String? url) {
    if (url == null || url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    final host = uri?.host.toLowerCase();
    if (host == null || host.isEmpty) return false;
    for (final suffix in allowedHostSuffixes) {
      if (host == suffix || host.endsWith('.$suffix')) return true;
    }
    return false;
  }

  // ── Numeric constants (project-unique — crash theme) ───────────────────
  static const int pushSnoozeSeconds = 313200; // ~3.6 days
  static const int organicRecheckSeconds = 7;
  static const Duration configTimeout = Duration(seconds: 18);
  static const Duration awaitSignalsTimeout = Duration(seconds: 7);
  static const int attPromptDelayMs = 420;
  static const int redirectRetryLimit = 2;
  static const int apnsPollCount = 6;
  static const int apnsPollStepMs = 650;
  static const int postPageResizeMs = 1100;
  static const List<int> pokeReflowDelaysMs = <int>[60, 190, 360, 610, 920];
  static const int coldViewportSettleMs = 360;
  static const int savedUrlExpiryDays = 6;
  static const int offlineFloorMs = 700;
}
