import 'dart:convert';

import 'package:flutter/foundation.dart';

/// How the board reacts to a tap.
enum ControlScheme {
  tapTile('Tap a tile', 'Tap any neighbouring tile to step onto it.'),
  swipe('Swipe', 'Swipe in a direction to step that way.'),
  both('Tap and swipe', 'Use whichever feels natural.');

  const ControlScheme(this.label, this.description);
  final String label;
  final String description;
}

@immutable
class AppSettings {
  const AppSettings({
    this.soundEnabled = true,
    this.soundVolume = 0.7,
    this.hapticsEnabled = true,
    this.reduceMotion = false,
    this.showTrailTimers = true,
    this.showGridGuides = true,
    this.confirmRestart = true,
    this.controls = ControlScheme.both,
    this.boardScale = 1.0,
  });

  final bool soundEnabled;
  final double soundVolume;
  final bool hapticsEnabled;

  /// Skips decorative animation for players who prefer a calmer screen.
  final bool reduceMotion;

  /// Numeric countdown badges on cooling trail tiles.
  final bool showTrailTimers;
  final bool showGridGuides;
  final bool confirmRestart;
  final ControlScheme controls;
  final double boardScale;

  AppSettings copyWith({
    bool? soundEnabled,
    double? soundVolume,
    bool? hapticsEnabled,
    bool? reduceMotion,
    bool? showTrailTimers,
    bool? showGridGuides,
    bool? confirmRestart,
    ControlScheme? controls,
    double? boardScale,
  }) =>
      AppSettings(
        soundEnabled: soundEnabled ?? this.soundEnabled,
        soundVolume: soundVolume ?? this.soundVolume,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
        reduceMotion: reduceMotion ?? this.reduceMotion,
        showTrailTimers: showTrailTimers ?? this.showTrailTimers,
        showGridGuides: showGridGuides ?? this.showGridGuides,
        confirmRestart: confirmRestart ?? this.confirmRestart,
        controls: controls ?? this.controls,
        boardScale: boardScale ?? this.boardScale,
      );

  Map<String, dynamic> toJson() => {
        'soundEnabled': soundEnabled,
        'soundVolume': soundVolume,
        'hapticsEnabled': hapticsEnabled,
        'reduceMotion': reduceMotion,
        'showTrailTimers': showTrailTimers,
        'showGridGuides': showGridGuides,
        'confirmRestart': confirmRestart,
        'controls': controls.name,
        'boardScale': boardScale,
      };

  String encode() => jsonEncode(toJson());

  static AppSettings decode(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AppSettings(
        soundEnabled: json['soundEnabled'] as bool? ?? true,
        soundVolume: (json['soundVolume'] as num?)?.toDouble() ?? 0.7,
        hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
        reduceMotion: json['reduceMotion'] as bool? ?? false,
        showTrailTimers: json['showTrailTimers'] as bool? ?? true,
        showGridGuides: json['showGridGuides'] as bool? ?? true,
        confirmRestart: json['confirmRestart'] as bool? ?? true,
        controls: ControlScheme.values.firstWhere(
          (c) => c.name == json['controls'],
          orElse: () => ControlScheme.both,
        ),
        boardScale: (json['boardScale'] as num?)?.toDouble() ?? 1.0,
      );
    } catch (_) {
      return const AppSettings();
    }
  }
}
