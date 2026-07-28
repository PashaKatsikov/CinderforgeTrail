import 'dart:io';

import 'package:image/image.dart' as img;

/// Reports whether a sheet uses real transparency or a flat white backdrop,
/// which decides how the slicer separates sprites from the background.
void main() {
  final files = [
    '../assets/Cinderforge_Trail_gameplay_assets/main_character_asset.webp',
    '../assets/Cinderforge_Trail_gameplay_assets/different_sections_of_the_trail_asset.webp',
    '../assets/Cinderforge_Trail_gameplay_assets/Volcanic_Ground_Tiles_asset.webp',
  ];
  for (final p in files) {
    final im = img.decodeImage(File(p).readAsBytesSync())!;
    var transparent = 0;
    var nearWhite = 0;
    final total = im.width * im.height;
    for (final px in im) {
      if (px.a < 32) transparent++;
      if (px.a > 200 && px.r > 240 && px.g > 240 && px.b > 240) nearWhite++;
    }
    final corner = im.getPixel(2, 2);
    stdout.writeln(
      '${p.split('/').last}  channels=${im.numChannels} '
      'transparent=${(transparent / total * 100).toStringAsFixed(1)}% '
      'nearWhite=${(nearWhite / total * 100).toStringAsFixed(1)}% '
      'corner=(${corner.r},${corner.g},${corner.b},${corner.a})',
    );
  }
}
