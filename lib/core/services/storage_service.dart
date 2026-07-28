import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/profile.dart';
import '../../data/models/settings.dart';

/// Thin persistence layer over [SharedPreferences].
///
/// Everything is stored on the device, so the game keeps full progress with no
/// network of any kind.
class StorageService {
  StorageService(this._prefs);

  static const _profileKey = 'cinderforge.profile.v1';
  static const _settingsKey = 'cinderforge.settings.v1';
  static const _onboardedKey = 'cinderforge.onboarded.v1';

  final SharedPreferences _prefs;

  static Future<StorageService> open() async =>
      StorageService(await SharedPreferences.getInstance());

  PlayerProfile loadProfile() {
    final raw = _prefs.getString(_profileKey);
    return raw == null ? const PlayerProfile() : PlayerProfile.decode(raw);
  }

  Future<void> saveProfile(PlayerProfile profile) =>
      _prefs.setString(_profileKey, profile.encode());

  AppSettings loadSettings() {
    final raw = _prefs.getString(_settingsKey);
    return raw == null ? const AppSettings() : AppSettings.decode(raw);
  }

  Future<void> saveSettings(AppSettings settings) =>
      _prefs.setString(_settingsKey, settings.encode());

  bool get hasOnboarded => _prefs.getBool(_onboardedKey) ?? false;

  Future<void> setOnboarded() => _prefs.setBool(_onboardedKey, true);

  Future<void> resetProgress() async {
    await _prefs.remove(_profileKey);
  }
}
