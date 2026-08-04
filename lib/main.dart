import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/design/app_theme.dart';
import 'core/services/audio_service.dart';
import 'core/services/storage_service.dart';
import 'emberlink/ember_gate.dart';
import 'state/app_state.dart';

/// Background message handler. Kept intentionally empty — the NSE renders rich
/// media, and cold-start taps are captured natively by SceneDelegate.
@pragma('vm:entry-point')
Future<void> _emberBackgroundMessage(RemoteMessage message) async {}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemOverlay);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Firebase and App Check init are independent: the gray flow must run even if
  // App Check debug tokens fail (lessons §5).
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_emberBackgroundMessage);
  } catch (_) {/* push simply unavailable this run */}
  try {
    await FirebaseAppCheck.instance.activate(
      providerApple: const AppleDeviceCheckProvider(),
    );
  } catch (_) {/* App Check optional */}

  final storage = await StorageService.open();
  final audio = AudioService();
  final ember = await EmberServices.boot();

  runApp(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(storage),
        audioProvider.overrideWithValue(audio),
        emberServicesProvider.overrideWithValue(ember),
      ],
      child: const CinderforgeApp(),
    ),
  );
}
