import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/design/app_theme.dart';
import 'core/router/app_router.dart';

class CinderforgeApp extends ConsumerWidget {
  const CinderforgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Cinderforge Trail',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        // Pin text scaling so the dense HUD and cards never overflow.
        final scale = MediaQuery.textScalerOf(context).clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.15,
        );
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scale),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
