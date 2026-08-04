/// Parsed response from the config endpoint.
///
/// `{ "ok": true, "url": "https://…", "expires": 1710000000 }`
class BeaconReply {
  const BeaconReply({
    required this.granted,
    this.answered = true,
    this.destination,
    this.expiresAt,
  });

  /// True only when the backend returned `ok:true` with a usable URL.
  final bool granted;

  /// True when the server gave a definitive answer (any HTTP status, including
  /// a 404 / ok:false). False for a transient failure (socket / DNS / timeout).
  /// A first launch must only commit the native path on a definitive answer —
  /// never on a transient failure (invariant #3).
  final bool answered;

  /// The URL to load in the portal, loaded unchanged. Null when not granted.
  final String? destination;

  /// Unix seconds after which a saved copy of [destination] must be refetched.
  final int? expiresAt;

  /// Transient failure — no usable answer from the server.
  const BeaconReply.unreachable()
      : granted = false,
        answered = false,
        destination = null,
        expiresAt = null;

  /// Definitive negative from the server (e.g. organic → 404 / ok:false).
  const BeaconReply.declined()
      : granted = false,
        answered = true,
        destination = null,
        expiresAt = null;

  factory BeaconReply.fromJson(Map<String, dynamic> json) {
    final ok = json['ok'] == true;
    final url = json['url'];
    final expires = json['expires'];
    final hasUrl = url is String && url.isNotEmpty;
    return BeaconReply(
      granted: ok && hasUrl,
      answered: true,
      destination: hasUrl ? url : null,
      expiresAt: expires is int
          ? expires
          : (expires is String ? int.tryParse(expires) : null),
    );
  }
}
