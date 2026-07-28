import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Every one-shot cue the UI can fire.
enum Sfx {
  tap('button_tap.mp3'),
  hover('button_hover.mp3'),
  confirm('confirmation.mp3'),
  cancel('cancel.mp3'),
  error('error.mp3'),
  menuOpen('menu_open.mp3'),
  menuClose('menu_close.mp3'),
  popup('popup_appears.mp3'),
  toggleOn('toggle_on.mp3'),
  toggleOff('toggle_off.mp3'),
  levelStart('level_start.mp3'),
  levelComplete('level_complete.mp3'),
  levelFailed('level_failed.mp3'),
  reward('reward_received.mp3'),
  progress('progress_complete.mp3'),
  notify('notification.mp3');

  const Sfx(this.file);
  final String file;

  String get asset => 'app/audio/$file';
}

/// Plays short interface cues from bundled assets.
///
/// A small pool of players is reused so rapid taps never allocate, and every
/// failure is swallowed: audio is never allowed to break gameplay.
class AudioService {
  AudioService();

  static const _poolSize = 4;

  final List<AudioPlayer> _pool = [];
  int _next = 0;
  bool _ready = false;

  bool enabled = true;
  double volume = 0.7;
  bool haptics = true;

  Future<void> warmUp() async {
    if (_ready) return;
    try {
      for (var i = 0; i < _poolSize; i++) {
        final player = AudioPlayer()
          ..setReleaseMode(ReleaseMode.stop)
          ..setPlayerMode(PlayerMode.lowLatency);
        await player.setVolume(volume);
        _pool.add(player);
      }
      _ready = true;
    } catch (error) {
      debugPrint('AudioService warm-up skipped: $error');
    }
  }

  void play(Sfx sfx) {
    if (!enabled || !_ready || _pool.isEmpty) return;
    final player = _pool[_next];
    _next = (_next + 1) % _pool.length;
    unawaited(() async {
      try {
        await player.stop();
        await player.setVolume(volume);
        await player.play(AssetSource(sfx.asset));
      } catch (error) {
        debugPrint('AudioService play failed: $error');
      }
    }());
  }

  void tap() {
    play(Sfx.tap);
    buzz(HapticKind.selection);
  }

  void buzz(HapticKind kind) {
    if (!haptics) return;
    switch (kind) {
      case HapticKind.selection:
        HapticFeedback.selectionClick();
      case HapticKind.light:
        HapticFeedback.lightImpact();
      case HapticKind.medium:
        HapticFeedback.mediumImpact();
      case HapticKind.heavy:
        HapticFeedback.heavyImpact();
    }
  }

  Future<void> dispose() async {
    for (final player in _pool) {
      try {
        await player.dispose();
      } catch (_) {
        // Nothing useful to do while tearing down.
      }
    }
    _pool.clear();
    _ready = false;
  }
}

enum HapticKind { selection, light, medium, heavy }
