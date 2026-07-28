import 'package:flutter/material.dart';

/// Colour tokens for the whole app.
///
/// The palette is deliberately narrow: a near-black volcanic base, one ember
/// accent, and one colour per trail stage. Everything else is derived from
/// opacity so screens stay minimal and consistent.
abstract final class Palette {
  // Base surfaces, darkest to lightest.
  static const void0 = Color(0xFF07060A);
  static const base = Color(0xFF0B0A0F);
  static const surface = Color(0xFF141119);
  static const surfaceHigh = Color(0xFF1C1824);
  static const surfaceTop = Color(0xFF262031);

  // Ember accent family.
  static const ember = Color(0xFFFF6B2C);
  static const emberSoft = Color(0xFFFF8A4C);
  static const emberDeep = Color(0xFFD8410E);
  static const gold = Color(0xFFFFB347);

  // Trail stages.
  static const magma = Color(0xFFFF4713);
  static const cinder = Color(0xFFE2622B);
  static const metal = Color(0xFFFFC46B);
  static const obsidian = Color(0xFF7C8299);

  // Semantic.
  static const ice = Color(0xFF6FD3FF);
  static const success = Color(0xFF4ADE80);
  static const danger = Color(0xFFFF4D6D);
  static const arcane = Color(0xFFB086FF);

  // Type.
  static const textPrimary = Color(0xFFF6F2EC);
  static const textSecondary = Color(0xFFA79FB4);
  static const textMuted = Color(0xFF6E677C);

  static const hairline = Color(0x14FFFFFF);
  static const hairlineStrong = Color(0x26FFFFFF);

  /// Signature diagonal ember gradient used on primary actions.
  static const emberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8A3D), Color(0xFFF2400F)],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD98A), Color(0xFFFF9A2E)],
  );

  /// Vertical scrim that keeps foreground text legible over artwork.
  static const scrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xE60B0A0F), Color(0x990B0A0F), Color(0xF20B0A0F)],
    stops: [0, 0.45, 1],
  );
}
