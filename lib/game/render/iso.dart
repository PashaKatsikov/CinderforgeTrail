import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Isometric projection for a rectangular grid.
///
/// Grid space runs `x` to the lower right and `y` to the lower left. The whole
/// projection is a plain 2x2 linear map, which means the same maths can be
/// handed to the canvas as a transform for shape drawing and inverted for
/// hit testing.
@immutable
class IsoProjection {
  const IsoProjection({
    required this.columns,
    required this.rows,
    required this.tileWidth,
    required this.origin,
  });

  final int columns;
  final int rows;

  /// Width of a single tile's top face; the height is always half of it.
  final double tileWidth;

  /// Screen-space position of grid coordinate (0, 0).
  final Offset origin;

  double get tileHeight => tileWidth / 2;

  static Size sizeFor(int columns, int rows, double tileWidth) => Size(
        (columns + rows) * tileWidth / 2,
        (columns + rows) * tileWidth / 4,
      );

  Size get boardSize => sizeFor(columns, rows, tileWidth);

  /// Largest tile width that fits [available], leaving [headroom] pixels for
  /// props that stand above their tile.
  static double fitTileWidth(
    Size available,
    int columns,
    int rows, {
    double headroom = 0,
    double maxTileWidth = 108,
  }) {
    final span = columns + rows;
    if (span <= 0) return maxTileWidth;
    final byWidth = 2 * available.width / span;
    final byHeight = 4 * math.max(0, available.height - headroom) / span;
    return math.min(math.min(byWidth, byHeight), maxTileWidth);
  }

  /// Projects a grid point (fractional coordinates allowed) to the screen.
  Offset project(double x, double y) => Offset(
        (x - y) * tileWidth / 2 + origin.dx,
        (x + y) * tileHeight + origin.dy,
      );

  /// Screen position of the centre of the tile's top face.
  Offset centerOf(int column, int row) =>
      project(column + 0.5, row + 0.5);

  /// Grid cell under a screen point, or null when outside the board.
  ({int column, int row})? cellAt(Offset point) {
    final dx = (point.dx - origin.dx) / tileWidth;
    final dy = (point.dy - origin.dy) / tileHeight;
    final gx = (dx + dy).floor();
    final gy = (dy - dx).floor();
    if (gx < 0 || gy < 0 || gx >= columns || gy >= rows) return null;
    return (column: gx, row: gy);
  }

  /// Canvas transform that turns grid coordinates into screen coordinates,
  /// so shapes can be described in tile units and land correctly skewed.
  Matrix4 get canvasTransform => Matrix4.identity()
    ..setEntry(0, 0, tileWidth / 2)
    ..setEntry(0, 1, -tileWidth / 2)
    ..setEntry(0, 3, origin.dx)
    ..setEntry(1, 0, tileHeight)
    ..setEntry(1, 1, tileHeight)
    ..setEntry(1, 3, origin.dy);

  /// Draw order for the painter's algorithm: far tiles first.
  static int depthCompare(int aColumn, int aRow, int bColumn, int bRow) {
    final byDepth = (aColumn + aRow).compareTo(bColumn + bRow);
    return byDepth != 0 ? byDepth : aColumn.compareTo(bColumn);
  }
}
