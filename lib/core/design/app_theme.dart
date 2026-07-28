import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'palette.dart';
import 'typography.dart';

/// Spacing, radii and elevation constants shared by every screen.
abstract final class Insets {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// Horizontal page gutter.
  static const page = 20.0;
}

abstract final class Corners {
  static const s = BorderRadius.all(Radius.circular(10));
  static const m = BorderRadius.all(Radius.circular(16));
  static const l = BorderRadius.all(Radius.circular(22));
  static const xl = BorderRadius.all(Radius.circular(28));
  static const pill = BorderRadius.all(Radius.circular(999));
}

abstract final class Motion {
  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 520);
  static const curve = Curves.easeOutCubic;
  static const emphasized = Curves.easeOutBack;
}

abstract final class AppTheme {
  static const systemOverlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Palette.base,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static ThemeData build() {
    const scheme = ColorScheme.dark(
      primary: Palette.ember,
      onPrimary: Colors.white,
      secondary: Palette.gold,
      onSecondary: Palette.void0,
      surface: Palette.surface,
      onSurface: Palette.textPrimary,
      error: Palette.danger,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: Palette.base,
      canvasColor: Palette.base,
      fontFamily: AppFonts.body,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: systemOverlay,
        titleTextStyle: AppText.section,
        iconTheme: IconThemeData(color: Palette.textPrimary, size: 22),
      ),
      dividerTheme: const DividerThemeData(
        color: Palette.hairline,
        thickness: 1,
        space: 1,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: Palette.ember,
        inactiveTrackColor: Palette.surfaceTop,
        thumbColor: Palette.gold,
        overlayColor: Color(0x22FF6B2C),
        trackHeight: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? Colors.white
              : Palette.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? Palette.ember
              : Palette.surfaceTop,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(
          color: Palette.surfaceTop,
          borderRadius: Corners.s,
        ),
        textStyle: AppText.bodyS,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Palette.surfaceTop,
        contentTextStyle: AppText.bodyM,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: Corners.m),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Palette.ember,
        selectionColor: Color(0x55FF6B2C),
        selectionHandleColor: Palette.ember,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
