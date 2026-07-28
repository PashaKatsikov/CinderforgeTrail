import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Slices every multi-sprite sheet into individual trimmed PNGs.
///
/// The sheets are loose grids whose rows sometimes overlap vertically, so axis
/// projection cannot separate them. Instead each sheet is labelled into
/// connected blobs which are then clustered: blobs whose bounding boxes are
/// near each other belong to the same sprite (art plus its detached debris).

const alphaThreshold = 24;

class Sheet {
  const Sheet(
    this.file,
    this.outDir, {
    this.maxSide = 256,
    this.merge = 10,
    this.grid,
    this.rowBands,
    this.alpha = alphaThreshold,
    this.expectedCount,
  });

  /// Explicit `[yStart, yEnd]` row ranges, for sheets whose rows touch
  /// vertically but whose sprites are cleanly separated horizontally.
  final List<List<int>>? rowBands;
  final String file;
  final String outDir;
  final int maxSide;

  /// Opacity cut-off used when labelling. Sheets with wide, faint glow halos
  /// need a higher value or every sprite fuses into one blob.
  final int alpha;

  /// Bounding boxes closer than this (in px) are treated as one sprite.
  final int merge;

  /// `[cols, rows]` forces uniform cell slicing, for sheets whose rows touch
  /// and therefore cannot be separated by blob clustering.
  final List<int>? grid;
  final int? expectedCount;
}

const sheets = <Sheet>[
  Sheet('main_character_asset', 'character', maxSide: 320, expectedCount: 10),
  Sheet('different_sections_of_the_trail_asset', 'trail', expectedCount: 30),
  Sheet('Volcanic_Ground_Tiles_asset', 'ground', expectedCount: 10),
  Sheet('Volcanic_Obstacles_asset', 'obstacle', merge: 3, expectedCount: 15),
  Sheet('Frozen_Formations_asset', 'frozen', merge: 3, expectedCount: 18),
  Sheet('Volcanic_Crystals_asset', 'crystal', maxSide: 224, expectedCount: 10),
  Sheet('Ancient_Forge_Mechanisms_asset', 'mechanism', merge: 5,
      expectedCount: 18),
  Sheet('Ancient_Forge_Relics_asset', 'relic', maxSide: 224, merge: 5,
      expectedCount: 24),
  Sheet('Volcanic_Creatures_asset', 'creature', maxSide: 224,
      expectedCount: 15),
  Sheet('Volcanic_Nature_Elements_asset', 'nature', maxSide: 224, merge: 6,
      expectedCount: 24),
  Sheet('Volcanic_Trees_asset', 'tree', maxSide: 320, expectedCount: 8),
  Sheet('Bridges_and_Crossings_asset', 'bridge', maxSide: 288,
      grid: [5, 6], expectedCount: 30),
  Sheet('Temperature_Effects_asset', 'effect', expectedCount: 17),
  Sheet(
    'Lava_Flows_asset',
    'lava',
    rowBands: [
      [0, 250],
      [251, 396],
      [397, 671],
    ],
    expectedCount: 20,
  ),
  Sheet('Runes_and_Energy_Elements_asset', 'rune', maxSide: 192, merge: 4,
      expectedCount: 32),
];

class Box {
  Box(this.x0, this.y0, this.x1, this.y1, this.area);
  int x0, y0, x1, y1, area;

  int get w => x1 - x0 + 1;
  int get h => y1 - y0 + 1;
  int get maxSide => math.max(w, h);
  double get cx => (x0 + x1) / 2;
  double get cy => (y0 + y1) / 2;

  void absorb(Box o) {
    x0 = math.min(x0, o.x0);
    y0 = math.min(y0, o.y0);
    x1 = math.max(x1, o.x1);
    y1 = math.max(y1, o.y1);
    area += o.area;
  }

  /// Chebyshev-style gap between two boxes; 0 when they overlap.
  int gapTo(Box o) {
    final dx = math.max(0, math.max(x0 - o.x1, o.x0 - x1));
    final dy = math.max(0, math.max(y0 - o.y1, o.y0 - y1));
    return math.max(dx, dy);
  }
}

List<Box> _components(
  img.Image src,
  int alpha, {
  int? rx0,
  int? ry0,
  int? rx1,
  int? ry1,
}) {
  final w = src.width, h = src.height;
  final ax0 = rx0 ?? 0, ay0 = ry0 ?? 0;
  final ax1 = rx1 ?? w - 1, ay1 = ry1 ?? h - 1;
  final mask = List<bool>.filled(w * h, false);
  for (var y = ay0; y <= ay1; y++) {
    for (var x = ax0; x <= ax1; x++) {
      mask[y * w + x] = src.getPixel(x, y).a > alpha;
    }
  }
  final seen = List<bool>.filled(w * h, false);
  final boxes = <Box>[];
  final stack = <int>[];

  for (var start = 0; start < w * h; start++) {
    if (!mask[start] || seen[start]) continue;
    seen[start] = true;
    stack
      ..clear()
      ..add(start);
    var x0 = start % w, x1 = x0, y0 = start ~/ w, y1 = y0, area = 0;

    while (stack.isNotEmpty) {
      final p = stack.removeLast();
      final px = p % w, py = p ~/ w;
      area++;
      if (px < x0) x0 = px;
      if (px > x1) x1 = px;
      if (py < y0) y0 = py;
      if (py > y1) y1 = py;

      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          final nx = px + dx, ny = py + dy;
          if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
          final n = ny * w + nx;
          if (mask[n] && !seen[n]) {
            seen[n] = true;
            stack.add(n);
          }
        }
      }
    }
    boxes.add(Box(x0, y0, x1, y1, area));
  }
  return boxes;
}

/// Repeatedly fuses boxes that sit within [merge] px of each other.
List<Box> _cluster(List<Box> input, int merge) {
  final boxes = List<Box>.from(input);
  var changed = true;
  while (changed) {
    changed = false;
    outer:
    for (var i = 0; i < boxes.length; i++) {
      for (var j = i + 1; j < boxes.length; j++) {
        if (boxes[i].gapTo(boxes[j]) <= merge) {
          boxes[i].absorb(boxes[j]);
          boxes.removeAt(j);
          changed = true;
          break outer;
        }
      }
    }
  }
  return boxes;
}

/// Folds leftover specks into the nearest real sprite, or drops them.
List<Box> _absorbSpecks(List<Box> boxes) {
  if (boxes.length < 3) return boxes;
  final sides = boxes.map((b) => b.maxSide).toList()..sort();
  final median = sides[sides.length ~/ 2];
  final keep = <Box>[];
  final specks = <Box>[];
  for (final b in boxes) {
    (b.maxSide < median * 0.16 ? specks : keep).add(b);
  }
  if (keep.isEmpty) return boxes;
  for (final s in specks) {
    Box? best;
    var bestGap = 1 << 30;
    for (final k in keep) {
      final g = s.gapTo(k);
      if (g < bestGap) {
        bestGap = g;
        best = k;
      }
    }
    if (best != null && bestGap <= 14) best.absorb(s);
  }
  return keep;
}

/// Returns the box of the largest blob cluster inside a region, ignoring
/// fragments of neighbouring sprites that bleed across the region edge.
Box? _dominant(img.Image src, int x0, int y0, int x1, int y1, int mergeGap) {
  final parts = _cluster(
    _components(src, alphaThreshold, rx0: x0, ry0: y0, rx1: x1, ry1: y1),
    mergeGap,
  );
  if (parts.isEmpty) return null;
  parts.sort((a, b) => b.area.compareTo(a.area));
  final main = parts.first;
  if (main.area < 200) return null;
  // Only reclaim small detached details (posts, sparks, debris) that clearly
  // belong to the main piece; anything larger is a neighbouring sprite.
  for (final p in parts.skip(1)) {
    if (p.area < main.area * 0.15 && p.gapTo(main) <= 6) main.absorb(p);
  }
  return main;
}

/// Slices explicit horizontal bands by projecting alpha onto the x axis.
List<Box> _bandBoxes(img.Image src, List<List<int>> bands, int gap) {
  final out = <Box>[];
  for (final band in bands) {
    final y0 = band[0].clamp(0, src.height - 1);
    final y1 = band[1].clamp(0, src.height - 1);
    final occupied = List<bool>.filled(src.width, false);
    for (var x = 0; x < src.width; x++) {
      for (var y = y0; y <= y1; y++) {
        if (src.getPixel(x, y).a > alphaThreshold) {
          occupied[x] = true;
          break;
        }
      }
    }

    final segments = <List<int>>[];
    var start = -1;
    for (var x = 0; x < src.width; x++) {
      if (occupied[x]) {
        if (start < 0) start = x;
      } else if (start >= 0) {
        if (segments.isNotEmpty && start - segments.last[1] - 1 < gap) {
          segments.last[1] = x - 1;
        } else {
          segments.add([start, x - 1]);
        }
        start = -1;
      }
    }
    if (start >= 0) segments.add([start, src.width - 1]);

    for (final seg in segments.where((s) => s[1] - s[0] + 1 >= 20)) {
      final box = _dominant(src, seg[0], y0, seg[1], y1, gap);
      if (box != null) out.add(box);
    }
  }
  return out;
}

/// Splits a sheet into uniform cells, keeping the dominant blob in each.
List<Box> _gridBoxes(img.Image src, int cols, int rows, int mergeGap) {
  final cellW = src.width / cols;
  final cellH = src.height / rows;
  final out = <Box>[];
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      final box = _dominant(
        src,
        (c * cellW).round(),
        (r * cellH).round(),
        math.min(src.width - 1, ((c + 1) * cellW).round() - 1),
        math.min(src.height - 1, ((r + 1) * cellH).round() - 1),
        mergeGap,
      );
      if (box != null) out.add(box);
    }
  }
  return out;
}

/// Orders sprites in reading order by grouping their vertical centres.
List<Box> _readingOrder(List<Box> boxes) {
  final sorted = List<Box>.from(boxes)..sort((a, b) => a.cy.compareTo(b.cy));
  final heights = boxes.map((b) => b.h).toList()..sort();
  final medianH = heights[heights.length ~/ 2];
  final rows = <List<Box>>[];
  for (final b in sorted) {
    if (rows.isNotEmpty && (b.cy - rows.last.first.cy).abs() < medianH * 0.7) {
      rows.last.add(b);
    } else {
      rows.add([b]);
    }
  }
  return [
    for (final row in rows) ...(row..sort((a, b) => a.cx.compareTo(b.cx))),
  ];
}

void main() {
  const srcRoot = '../assets/Cinderforge_Trail_gameplay_assets';
  final outRoot = Directory('../assets/app/sprites');
  final contactRoot = Directory('contact')..createSync(recursive: true);
  final manifest = StringBuffer();

  for (final sheet in sheets) {
    final src = img.decodeImage(
      File('$srcRoot/${sheet.file}.webp').readAsBytesSync(),
    )!;

    final grid = sheet.grid;
    final bands = sheet.rowBands;
    final List<Box> boxes;
    if (grid != null) {
      boxes = _gridBoxes(src, grid[0], grid[1], sheet.merge);
    } else if (bands != null) {
      boxes = _bandBoxes(src, bands, sheet.merge);
    } else {
      boxes = _readingOrder(
        _absorbSpecks(_cluster(_components(src, sheet.alpha), sheet.merge)),
      );
    }

    final dir = Directory('${outRoot.path}/${sheet.outDir}')
      ..createSync(recursive: true);
    for (final f in dir.listSync()) {
      f.deleteSync();
    }

    final pieces = <img.Image>[];
    for (final b in boxes) {
      // A raised alpha cut-off shrinks the blob past its glow, so pad wider.
      final pad = sheet.alpha > 64 ? 12 : 2;
      final x0 = math.max(0, b.x0 - pad);
      final y0 = math.max(0, b.y0 - pad);
      final x1 = math.min(src.width - 1, b.x1 + pad);
      final y1 = math.min(src.height - 1, b.y1 + pad);
      pieces.add(
        img.copyCrop(
          src,
          x: x0,
          y: y0,
          width: x1 - x0 + 1,
          height: y1 - y0 + 1,
        ),
      );
    }

    for (var i = 0; i < pieces.length; i++) {
      var piece = pieces[i];
      final maxSide = math.max(piece.width, piece.height);
      if (maxSide > sheet.maxSide) {
        final scale = sheet.maxSide / maxSide;
        piece = img.copyResize(
          piece,
          width: math.max(1, (piece.width * scale).round()),
          height: math.max(1, (piece.height * scale).round()),
          interpolation: img.Interpolation.cubic,
        );
      }
      final name = '${sheet.outDir}_${(i + 1).toString().padLeft(2, '0')}';
      File(
        '${dir.path}/$name.png',
      ).writeAsBytesSync(img.encodePng(piece, level: 9));
    }

    final flag = sheet.expectedCount != null &&
            sheet.expectedCount != pieces.length
        ? '   <-- expected ${sheet.expectedCount}'
        : '';
    manifest.writeln('${sheet.outDir}: ${pieces.length}');
    stdout.writeln('${sheet.outDir}: ${pieces.length} sprites$flag');
    _writeContactSheet(contactRoot, sheet.outDir, pieces);
  }

  File('../assets/app/sprites/_manifest.txt')
      .writeAsStringSync(manifest.toString());
}

/// Builds a numbered contact sheet so each sliced index can be identified.
void _writeContactSheet(Directory out, String name, List<img.Image> pieces) {
  const cell = 150;
  final cols = pieces.length <= 12 ? 6 : 8;
  final rows = (pieces.length / cols).ceil();
  final canvas = img.Image(
    width: cols * cell,
    height: math.max(1, rows) * cell,
    numChannels: 4,
  );
  img.fill(canvas, color: img.ColorRgba8(28, 28, 34, 255));

  for (var i = 0; i < pieces.length; i++) {
    final cx = (i % cols) * cell;
    final cy = (i ~/ cols) * cell;
    var p = pieces[i];
    final scale = (cell - 26) / math.max(p.width, p.height);
    p = img.copyResize(
      p,
      width: (p.width * scale).round().clamp(1, cell),
      height: (p.height * scale).round().clamp(1, cell),
      interpolation: img.Interpolation.average,
    );
    img.compositeImage(
      canvas,
      p,
      dstX: cx + (cell - p.width) ~/ 2,
      dstY: cy + 22 + (cell - 26 - p.height) ~/ 2,
    );
    img.drawString(
      canvas,
      '${i + 1}',
      font: img.arial14,
      x: cx + 6,
      y: cy + 4,
      color: img.ColorRgba8(255, 210, 120, 255),
    );
  }
  File('${out.path}/$name.png')
      .writeAsBytesSync(img.encodePng(canvas, level: 6));
}
