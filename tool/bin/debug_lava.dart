import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final src = img.decodeImage(
    File('../assets/Cinderforge_Trail_gameplay_assets/Lava_Flows_asset.webp')
        .readAsBytesSync(),
  )!;

  for (final t in [24, 80, 140, 200, 240]) {
    var opaque = 0;
    for (final p in src) {
      if (p.a > t) opaque++;
    }
    stdout.writeln(
      'alpha>$t : ${(opaque / (src.width * src.height) * 100).toStringAsFixed(1)}%',
    );
  }

  // Sample a horizontal scanline through the middle of the top row of pieces
  // to see whether the gutters are genuinely empty.
  for (final y in [70, 180, 300, 450]) {
    final runs = <String>[];
    var run = 0;
    var solid = src.getPixel(0, y).a > 24;
    for (var x = 0; x < src.width; x++) {
      final s = src.getPixel(x, y).a > 24;
      if (s == solid) {
        run++;
      } else {
        runs.add('${solid ? "#" : "."}$run');
        solid = s;
        run = 1;
      }
    }
    runs.add('${solid ? "#" : "."}$run');
    stdout.writeln('y=$y  ${runs.join(" ")}');
  }
}
