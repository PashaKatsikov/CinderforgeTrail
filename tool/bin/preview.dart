import 'dart:io';

import 'package:image/image.dart' as img;

/// Converts every source sheet to a downscaled PNG so the sheets can be
/// inspected, and prints the true pixel dimensions of each sheet.
void main(List<String> args) {
  final srcDirs = [
    Directory('../assets/Cinderforge_Trail_gameplay_assets'),
    Directory('../assets/Cinderforge_Trail_additional_assets'),
  ];
  final out = Directory('preview')..createSync(recursive: true);

  for (final dir in srcDirs) {
    for (final f in dir.listSync().whereType<File>()) {
      final ext = f.path.split('.').last.toLowerCase();
      if (ext != 'webp' && ext != 'png') continue;
      final bytes = f.readAsBytesSync();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        stdout.writeln('FAILED ${f.path}');
        continue;
      }
      final name = f.uri.pathSegments.last.split('.').first;
      stdout.writeln('$name : ${decoded.width}x${decoded.height}');
      final maxSide = decoded.width > decoded.height
          ? decoded.width
          : decoded.height;
      final scale = maxSide > 900 ? 900 / maxSide : 1.0;
      final resized = scale < 1.0
          ? img.copyResize(
              decoded,
              width: (decoded.width * scale).round(),
              interpolation: img.Interpolation.average,
            )
          : decoded;
      File(
        '${out.path}/$name.png',
      ).writeAsBytesSync(img.encodePng(resized, level: 6));
    }
  }
}
