import 'package:flutter/material.dart';

import 'palette.dart';

/// Two bundled families: Cinzel for display voice, Manrope for everything
/// functional. Both ship with the app so the UI renders identically offline.
abstract final class AppFonts {
  static const display = 'Cinzel';
  static const body = 'Manrope';
}

abstract final class AppText {
  static const _d = AppFonts.display;
  static const _b = AppFonts.body;

  static const hero = TextStyle(
    fontFamily: _d,
    fontSize: 34,
    height: 1.1,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.5,
    color: Palette.textPrimary,
  );

  static const title = TextStyle(
    fontFamily: _d,
    fontSize: 23,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.1,
    color: Palette.textPrimary,
  );

  static const section = TextStyle(
    fontFamily: _d,
    fontSize: 17,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.9,
    color: Palette.textPrimary,
  );

  /// Small all-caps label used for group headers and metric captions.
  static const overline = TextStyle(
    fontFamily: _b,
    fontSize: 10.5,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.2,
    color: Palette.textMuted,
  );

  static const bodyL = TextStyle(
    fontFamily: _b,
    fontSize: 15,
    height: 1.5,
    fontWeight: FontWeight.w500,
    color: Palette.textSecondary,
  );

  static const bodyM = TextStyle(
    fontFamily: _b,
    fontSize: 13.5,
    height: 1.45,
    fontWeight: FontWeight.w500,
    color: Palette.textSecondary,
  );

  static const bodyS = TextStyle(
    fontFamily: _b,
    fontSize: 11.5,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: Palette.textMuted,
  );

  static const label = TextStyle(
    fontFamily: _b,
    fontSize: 13,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    color: Palette.textPrimary,
  );

  static const button = TextStyle(
    fontFamily: _b,
    fontSize: 14,
    height: 1.1,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.4,
    color: Colors.white,
  );

  /// Tabular figures keep counters from jittering as they animate.
  static const numeral = TextStyle(
    fontFamily: _b,
    fontSize: 22,
    height: 1.05,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    color: Palette.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const numeralL = TextStyle(
    fontFamily: _b,
    fontSize: 34,
    height: 1,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
    color: Palette.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
