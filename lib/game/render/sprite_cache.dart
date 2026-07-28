import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Decoded sprite images, kept alive for the lifetime of the app.
///
/// The board is painted with a [CustomPainter], which needs `dart:ui` images
/// rather than widgets, so every sprite a level uses is decoded up front and
/// then looked up synchronously while painting.
class SpriteCache extends ChangeNotifier {
  SpriteCache._();

  static final SpriteCache instance = SpriteCache._();

  final Map<String, ui.Image> _images = {};
  final Map<String, Future<void>> _pending = {};

  ui.Image? operator [](String asset) => _images[asset];

  bool has(String asset) => _images.containsKey(asset);

  /// Decodes [assets] that are not cached yet.
  Future<void> load(Iterable<String> assets) async {
    final work = <Future<void>>[];
    for (final asset in assets.toSet()) {
      if (_images.containsKey(asset)) continue;
      work.add(_pending.putIfAbsent(asset, () => _decode(asset)));
    }
    if (work.isEmpty) return;
    await Future.wait(work);
    notifyListeners();
  }

  Future<void> _decode(String asset) async {
    try {
      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _images[asset] = frame.image;
    } catch (error) {
      debugPrint('SpriteCache could not decode $asset: $error');
    } finally {
      _pending.remove(asset);
    }
  }
}
