import 'dart:io';

import 'package:image/image.dart' as img;

/// Builds the adaptive-icon foreground.
///
/// Android shows only the centre 72/108 of the foreground layer, so the source
/// art is upscaled to fill the whole canvas: the visible circle/squircle is
/// then covered edge to edge instead of sitting inside empty margins.
void main() {
  const size = 1024;
  final src = img.decodeImage(
    File('../assets/app/icon/icon.png').readAsBytesSync(),
  )!;

  final canvas = img.Image(width: size, height: size, numChannels: 4);
  final scale = size / (src.width < src.height ? src.width : src.height);
  final scaled = img.copyResize(
    src,
    width: (src.width * scale).round(),
    height: (src.height * scale).round(),
    interpolation: img.Interpolation.cubic,
  );
  img.compositeImage(
    canvas,
    scaled,
    dstX: (size - scaled.width) ~/ 2,
    dstY: (size - scaled.height) ~/ 2,
  );

  File('../assets/app/icon/icon_foreground.png')
      .writeAsBytesSync(img.encodePng(canvas, level: 6));
  stdout.writeln('icon_foreground.png written (${size}x$size)');
}
