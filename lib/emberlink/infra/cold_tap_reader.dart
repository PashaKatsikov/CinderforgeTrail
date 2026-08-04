import 'package:shared_preferences/shared_preferences.dart';

/// Reads the one-shot cold-start push URL written natively by SceneDelegate.
///
/// SceneDelegate writes to UserDefaults key `flutter.cft_launch_route`; the
/// `flutter.` prefix bridges UserDefaults ↔ SharedPreferences, so Dart reads
/// the key WITHOUT the prefix. The two must stay in sync.
///
/// A cold-start tap only happens for a user who already enabled notifications
/// (an opted-in gray user, never an organic/reviewer), so — matching the
/// template — the URL is trusted as delivered. The 2.5.2/2.3.1 reviewer guard
/// lives on the config `destination` (see BeaconExchange), which is the URL an
/// organic/reviewer session could actually receive.
class ColdTapReader {
  const ColdTapReader();

  static const String _key = 'cft_launch_route';

  /// Returns the pending tap URL once, then clears it.
  Future<String?> consume() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      await prefs.remove(_key);
    }
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }
}
