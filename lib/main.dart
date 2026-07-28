import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/design/app_theme.dart';
import 'core/services/audio_service.dart';
import 'core/services/storage_service.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemOverlay);
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  final storage = await StorageService.open();
  final audio = AudioService();

  runApp(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(storage),
        audioProvider.overrideWithValue(audio),
      ],
      child: const CinderforgeApp(),
    ),
  );
}
