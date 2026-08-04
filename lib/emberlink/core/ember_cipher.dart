import 'dart:convert';
import 'dart:typed_data';

/// At-rest obfuscation for a handful of build-time constants.
///
/// This is deliberately an *ordinary* primitive — `base64` transport plus a
/// single position-keyed XOR pass against a key derived from the app's stable
/// build identity. It is NOT content-protection encryption: there is no key
/// exchange, no cipher state machine, nothing that would make
/// `ITSAppUsesNonExemptEncryption = false` inaccurate. The point is only to
/// keep a few endpoints out of a trivial `strings` grep.
///
/// The reverse routine lives in `tool/encode_ember_values.dart`; the two files
/// must always share [_keyMaterial] and [_stride]. Regenerate the encoded
/// values whenever either changes.
class EmberCipher {
  const EmberCipher._();

  static const String _keyMaterial =
      'com.cinderforge.trailgame|cft-1.0.0+1-ashfall';
  static const int _stride = 31;

  static List<int> get _key => utf8.encode(_keyMaterial);

  /// Decodes a value produced by `tool/encode_ember_values.dart`.
  static String reveal(String encoded) {
    if (encoded.isEmpty) return '';
    final bytes = base64.decode(encoded);
    final key = _key;
    final out = Uint8List(bytes.length);
    for (var i = 0; i < bytes.length; i++) {
      out[i] = bytes[i] ^ key[(i * _stride) % key.length];
    }
    return utf8.decode(out);
  }
}
