import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/ember_config.dart';
import '../models/trail_route.dart';

/// Persistence for the Emberlink layer.
///
/// Routing mode + push-prompt bookkeeping live in SharedPreferences; the saved
/// content URL lives in the Keychain (flutter_secure_storage). All keys use the
/// project-unique `ember.trail.*` prefix.
class EmberVault {
  EmberVault(this._prefs);

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _modeKey = 'ember.trail.mode';
  static const _savedUrlKey = 'ember.trail.saved_url';
  static const _savedExpiresKey = 'ember.trail.saved_url_expires';
  static const _pushDeniedKey = 'ember.trail.push_os_denied';
  static const _inviteSnoozeKey = 'ember.trail.invite_snooze_until';
  static const _pendingPushKey = 'ember.trail.pending_push_url';

  static Future<EmberVault> open() async =>
      EmberVault(await SharedPreferences.getInstance());

  // ── Routing mode ───────────────────────────────────────────────────────
  RouteMode readMode() => routeModeFromName(_prefs.getString(_modeKey));

  Future<void> writeMode(RouteMode mode) =>
      _prefs.setString(_modeKey, mode.name);

  // ── Saved content URL (Keychain) with expiry ──────────────────────────
  Future<void> saveDestination(String url, {int? expiresAt}) async {
    await _secure.write(key: _savedUrlKey, value: url);
    final expiry = expiresAt ??
        (DateTime.now()
                .add(const Duration(days: EmberConfig.savedUrlExpiryDays))
                .millisecondsSinceEpoch ~/
            1000);
    await _prefs.setInt(_savedExpiresKey, expiry);
  }

  /// Returns the saved URL only if it is still present and unexpired. The URL
  /// was already validated on write (config destinations pass the allowlist in
  /// BeaconExchange; cold-start URLs are trusted like in the template).
  Future<String?> readSavedDestination() async {
    final url = await _secure.read(key: _savedUrlKey);
    if (url == null || url.isEmpty) return null;
    final expires = _prefs.getInt(_savedExpiresKey);
    if (expires != null) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (now >= expires) return null;
    }
    return url;
  }

  Future<void> clearSavedDestination() async {
    await _secure.delete(key: _savedUrlKey);
    await _prefs.remove(_savedExpiresKey);
  }

  // ── Pending push URL (one-shot) ────────────────────────────────────────
  /// Stashes a URL carried by a tapped push for the case where no portal is
  /// live to receive it yet (app in the game / backgrounded / just launched).
  /// Trusted as delivered — same contract as the template.
  Future<void> stashPushUrl(String url) async {
    if (url.trim().isEmpty) return;
    await _prefs.setString(_pendingPushKey, url.trim());
  }

  /// Returns the stashed push URL once, then clears it.
  Future<String?> consumePushUrl() async {
    final url = _prefs.getString(_pendingPushKey);
    if (url == null) return null;
    await _prefs.remove(_pendingPushKey);
    return url;
  }

  // ── Push prompt bookkeeping ────────────────────────────────────────────
  bool get pushOsDenied => _prefs.getBool(_pushDeniedKey) ?? false;

  Future<void> markPushOsDenied() => _prefs.setBool(_pushDeniedKey, true);

  /// Whether the invitation may be shown now (not OS-denied and past snooze).
  bool get canOfferInvite {
    if (pushOsDenied) return false;
    final until = _prefs.getInt(_inviteSnoozeKey);
    if (until == null) return true;
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= until;
  }

  Future<void> snoozeInvite() {
    final until = DateTime.now().millisecondsSinceEpoch ~/ 1000 +
        EmberConfig.pushSnoozeSeconds;
    return _prefs.setInt(_inviteSnoozeKey, until);
  }
}
