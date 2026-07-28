import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/design/palette.dart';
import '../../core/design/typography.dart';
import '../../data/sprites.dart';
import '../logic/engine.dart';
import '../logic/game_session.dart';
import '../model/level.dart';
import 'board_art.dart';
import 'iso.dart';
import 'sprite_cache.dart';

/// Paints the isometric board: ground, cooling trail, props and the walker.
///
/// Everything is drawn back to front by grid depth so props overlap correctly.
/// The trail itself is drawn as vector shapes in grid space under the
/// projection transform, which keeps its glow crisp at any tile size and lets
/// it recolour smoothly as heat drains away.
class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.session,
    required this.projection,
    required this.cache,
    required this.characterSprite,
    required this.stepProgress,
    required this.ambient,
    required this.showTimers,
    required this.showGuides,
    required this.previewRoute,
    required this.highlightCrystals,
    required this.reduceMotion,
  }) : super(repaint: cache);

  final SessionState session;
  final IsoProjection projection;
  final SpriteCache cache;
  final int characterSprite;

  /// 0..1 through the current step animation.
  final double stepProgress;

  /// 0..1 looping value driving glow and float.
  final double ambient;

  final bool showTimers;
  final bool showGuides;
  final List<int> previewRoute;
  final bool highlightCrystals;
  final bool reduceMotion;

  static final Map<String, TextPainter> _labelCache = {};

  LevelSpec get level => session.level;
  GameState get game => session.game;

  double get _tw => projection.tileWidth;
  double get _th => projection.tileHeight;

  double get _pulse =>
      reduceMotion ? 0.5 : 0.5 + 0.5 * math.sin(ambient * math.pi * 2);

  @override
  void paint(Canvas canvas, Size size) {
    final ordered = List<int>.generate(level.cellCount, (i) => i)
      ..sort((a, b) => IsoProjection.depthCompare(
            level.xOf(a),
            level.yOf(a),
            level.xOf(b),
            level.yOf(b),
          ));

    _paintGround(canvas, ordered);
    _paintTrailGlow(canvas);
    _paintTrail(canvas, ordered);
    _paintMarkers(canvas);
    _paintProps(canvas, ordered);
  }

  // ------------------------------------------------------------- ground

  void _paintGround(Canvas canvas, List<int> ordered) {
    final voidPaint = Paint()..color = const Color(0xFF08070C);
    final voidRim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x33FF6B2C);

    for (final cell in ordered) {
      final center = _center(cell);
      if (level.voids.contains(cell)) {
        final diamond = _diamond(center, 0.96);
        canvas
          ..drawPath(diamond, voidPaint)
          ..drawPath(diamond, voidRim);
        continue;
      }

      final image = cache[BoardArt.ground(level.surfaces[cell])];
      if (image != null) {
        _drawGroundTile(canvas, image, center);
      } else {
        canvas.drawPath(
          _diamond(center, 0.96),
          Paint()..color = Palette.surfaceHigh,
        );
      }

      if (showGuides) {
        canvas.drawPath(
          _diamond(center, 0.94),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = const Color(0x0EFFFFFF),
        );
      }
    }
  }

  void _drawGroundTile(Canvas canvas, ui.Image image, Offset center) {
    final height = _tw * image.height / image.width;
    final dst = Rect.fromLTWH(
      center.dx - _tw / 2,
      center.dy - _th / 2,
      _tw,
      height,
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  // -------------------------------------------------------------- trail

  /// One blurred pass beneath the trail so hot sections bleed light onto the
  /// ground instead of looking like flat decals.
  void _paintTrailGlow(Canvas canvas) {
    final hot = Path();
    final warm = Path();
    var hasHot = false, hasWarm = false;

    for (var cell = 0; cell < level.cellCount; cell++) {
      final stage = game.stageAt(cell);
      if (stage == null || stage == TrailStage.obsidian) continue;
      final path = _trailCellPath(cell);
      if (stage == TrailStage.metal) {
        warm.addPath(path, Offset.zero);
        hasWarm = true;
      } else {
        hot.addPath(path, Offset.zero);
        hasHot = true;
      }
    }
    if (!hasHot && !hasWarm) return;

    final blur = _tw * 0.20;
    canvas
      ..save()
      ..transform(projection.canvasTransform.storage);
    if (hasHot) {
      canvas.drawPath(
        hot,
        Paint()
          ..color = Palette.magma.withValues(alpha: 0.30 + 0.16 * _pulse)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur / _tw * 2),
      );
    }
    if (hasWarm) {
      canvas.drawPath(
        warm,
        Paint()
          ..color = Palette.metal.withValues(alpha: 0.22 + 0.12 * _pulse)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur / _tw * 1.6),
      );
    }
    canvas.restore();
  }

  void _paintTrail(Canvas canvas, List<int> ordered) {
    canvas
      ..save()
      ..transform(projection.canvasTransform.storage);

    for (final cell in ordered) {
      final heat = game.heat[cell];
      final stage = Heat.stageOf(heat);
      if (stage == null) continue;

      final progress = Heat.stageProgress(heat);
      final path = _trailCellPath(cell);
      final base = BoardArt.stageColor(stage);
      final core = BoardArt.stageCore(stage);

      canvas.drawPath(path, Paint()..color = base);
      canvas.drawPath(
        _trailCellPath(cell, scale: 0.55),
        Paint()
          ..color = Color.lerp(base, core, 0.35 + 0.65 * progress)!
              .withValues(alpha: stage == TrailStage.obsidian ? 0.55 : 0.9),
      );
    }
    canvas.restore();

    if (showTimers) _paintTrailTimers(canvas, ordered);
  }

  /// Rounded blob at the cell centre plus half-links to trailed neighbours,
  /// expressed in grid units so the projection transform shapes it.
  Path _trailCellPath(int cell, {double scale = 1}) {
    final x = level.xOf(cell).toDouble();
    final y = level.yOf(cell).toDouble();
    final path = Path();
    final r = 0.30 * scale;
    final w = 0.22 * scale;

    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(x + 0.5 - r, y + 0.5 - r, x + 0.5 + r, y + 0.5 + r),
        Radius.circular(0.13 * scale),
      ),
    );

    void link(int nx, int ny, Rect rect) {
      if (nx < 0 || ny < 0 || nx >= level.width || ny >= level.height) return;
      final neighbour = level.cellAt(nx, ny);
      final connected = game.heat[neighbour] > 0 || game.player == neighbour;
      if (connected) path.addRect(rect);
    }

    final cx = x + 0.5, cy = y + 0.5;
    link(x.toInt() + 1, y.toInt(),
        Rect.fromLTRB(cx, cy - w, cx + 0.52, cy + w));
    link(x.toInt() - 1, y.toInt(),
        Rect.fromLTRB(cx - 0.52, cy - w, cx, cy + w));
    link(x.toInt(), y.toInt() + 1,
        Rect.fromLTRB(cx - w, cy, cx + w, cy + 0.52));
    link(x.toInt(), y.toInt() - 1,
        Rect.fromLTRB(cx - w, cy - 0.52, cx + w, cy));

    return path;
  }

  /// Moves remaining before this section drops into its next stage.
  void _paintTrailTimers(Canvas canvas, List<int> ordered) {
    for (final cell in ordered) {
      final heat = game.heat[cell];
      final stage = Heat.stageOf(heat);
      if (stage == null || cell == game.player) continue;

      final rate = level.surfaces[cell].coolRate;
      if (rate <= 0) continue;
      final threshold = switch (stage) {
        TrailStage.magma => Heat.magma,
        TrailStage.ember => Heat.ember,
        TrailStage.metal => Heat.metal,
        TrailStage.obsidian => 1,
      };
      if (level.surfaces[cell].keepsColdTrail && stage == TrailStage.obsidian) {
        continue;
      }
      final steps = ((heat - threshold) / rate).floor() + 1;
      if (steps <= 0 || steps > 9) continue;

      final label = _label(
        '$steps',
        stage == TrailStage.obsidian ? Palette.textPrimary : Palette.void0,
      );
      final center = _center(cell);
      label.paint(
        canvas,
        center - Offset(label.width / 2, label.height / 2),
      );
    }
  }

  TextPainter _label(String text, Color color) {
    final key = '$text|${color.toARGB32()}|${_tw.round()}';
    return _labelCache.putIfAbsent(key, () {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: math.max(9, _tw * 0.19),
            fontWeight: FontWeight.w800,
            color: color,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      return painter;
    });
  }

  // ------------------------------------------------------------ markers

  void _paintMarkers(Canvas canvas) {
    // Ghost of the ideal route granted by the Cartographer upgrade.
    for (var i = 0; i < previewRoute.length; i++) {
      final fade = 0.30 * (1 - i / (previewRoute.length + 1));
      canvas.drawPath(
        _diamond(_center(previewRoute[i]), 0.52),
        Paint()..color = Palette.gold.withValues(alpha: fade),
      );
    }

    if (!game.isOver) {
      for (final cell in Engine.legalMoves(game)) {
        final center = _center(cell);
        canvas.drawPath(
          _diamond(center, 0.30 + 0.05 * _pulse),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = Palette.gold.withValues(alpha: 0.34 + 0.20 * _pulse),
        );
      }
    }

    final hint = session.hintCell;
    if (hint != null) {
      final center = _center(hint);
      for (final scale in [0.9, 0.66 + 0.2 * _pulse]) {
        canvas.drawPath(
          _diamond(center, scale),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..color = Palette.gold.withValues(alpha: 0.85 - 0.3 * _pulse),
        );
      }
    }

    final rejected = session.rejectedCell;
    if (rejected != null) {
      canvas.drawPath(
        _diamond(_center(rejected), 0.9),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = Palette.danger.withValues(alpha: 0.8),
      );
    }
  }

  // -------------------------------------------------------------- props

  void _paintProps(Canvas canvas, List<int> ordered) {
    for (final cell in ordered) {
      if (cell == level.exit) _drawExit(canvas, cell);
      if (level.relics.contains(cell) && !game.relics.contains(cell)) {
        _drawPickup(canvas, cell, BoardArt.relic(level.id), 0.62, Palette.gold);
      }
      if (level.crystals.contains(cell) && !game.crystals.contains(cell)) {
        _drawPickup(
          canvas,
          cell,
          BoardArt.crystal(cell),
          0.52,
          highlightCrystals ? Palette.ice : null,
        );
      }

      final decor = level.decor[cell];
      if (decor != null) {
        _drawProp(
          canvas,
          cell,
          BoardArt.decor(decor),
          BoardArt.decorScale(decor),
        );
      }

      final obstacle = level.obstacles[cell];
      if (obstacle != null) _drawObstacle(canvas, cell, obstacle);

      if (cell == game.player) _drawPlayer(canvas);
    }
  }

  void _drawObstacle(Canvas canvas, int cell, Obstacle obstacle) {
    final cleared = game.cleared.contains(cell);
    switch (obstacle) {
      case Obstacle.iceWall:
        if (cleared) {
          _drawResidue(canvas, cell, Palette.ice);
        } else {
          _drawProp(canvas, cell, BoardArt.iceWall(cell), 0.98);
        }
      case Obstacle.cinderVine:
        if (cleared) {
          _drawResidue(canvas, cell, Palette.cinder);
        } else {
          _drawProp(canvas, cell, BoardArt.cinderVine(cell), 0.9);
        }
      case Obstacle.magnetGate:
        final open = Engine.isOpen(game, cell);
        _drawProp(
          canvas,
          cell,
          BoardArt.magnetGate(),
          0.92,
          opacity: open ? 0.22 : 1,
        );
        if (open) _drawEnergyRing(canvas, cell, Palette.metal);
      case Obstacle.obsidianStep:
        final active = Engine.isOpen(game, cell);
        if (active) {
          _drawProp(canvas, cell, BoardArt.golemActive(), 0.78);
        } else {
          _drawProp(canvas, cell, BoardArt.golemDormant(cell), 0.9);
        }
      case Obstacle.runeGate:
        if (cleared) {
          _drawEnergyRing(canvas, cell, Palette.arcane);
        } else {
          _drawProp(canvas, cell, BoardArt.runeSeal(), 0.95);
        }
      case Obstacle.forge:
        final stage = level.forgeStages[cell] ?? TrailStage.magma;
        final lit = game.litForges.contains(cell);
        // An unlit forge is drawn cold and ringed in the stage it is waiting
        // for, so the board itself states the level's objective.
        _drawProp(canvas, cell, BoardArt.forge(stage), 1.02,
            opacity: lit ? 1 : 0.72);
        _drawEnergyRing(
          canvas,
          cell,
          BoardArt.stageColor(stage),
          strength: lit ? 1 : 0.45,
        );
        if (!lit) _drawStageCall(canvas, cell, stage);
    }
  }

  void _drawExit(Canvas canvas, int cell) {
    final open = game.allForgesLit;
    final color = open ? Palette.success : Palette.textMuted;
    _drawEnergyRing(canvas, cell, color, strength: open ? 1 : 0.4);
    _drawProp(
      canvas,
      cell,
      BoardArt.exitPortal(),
      0.95,
      opacity: open ? 1 : 0.65,
    );
  }

  /// Small icon on an unlit forge that shows which heat stage it is waiting for.
  void _drawStageCall(Canvas canvas, int cell, TrailStage stage) {
    final color = BoardArt.stageColor(stage);
    final center = _center(cell);
    // Tiny badge: filled diamond with the stage number.
    const badgeR = 0.22;
    final bCenter = Offset(center.dx + _tw * 0.28, center.dy - _th * 0.30);
    canvas.drawPath(
      _diamond(bCenter, badgeR),
      Paint()..color = const Color(0xCC07060A),
    );
    canvas.drawPath(
      _diamond(bCenter, badgeR),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = color.withValues(alpha: 0.85),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: '${stage.index + 1}',
        style: TextStyle(
          color: color,
          fontSize: _th * 0.28,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      bCenter.translate(-tp.width / 2, -tp.height / 2),
    );
  }

  void _drawResidue(Canvas canvas, int cell, Color color) {
    canvas.drawPath(
      _diamond(_center(cell), 0.55),
      Paint()..color = color.withValues(alpha: 0.10),
    );
  }

  void _drawEnergyRing(
    Canvas canvas,
    int cell,
    Color color, {
    double strength = 1,
  }) {
    final center = _center(cell);
    canvas.drawPath(
      _diamond(center, 0.78 + 0.08 * _pulse),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: (0.25 + 0.35 * _pulse) * strength),
    );
    canvas.drawPath(
      _diamond(center, 0.5),
      Paint()
        ..color = color.withValues(alpha: 0.16 * strength)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  void _drawPickup(
    Canvas canvas,
    int cell,
    String asset,
    double scale,
    Color? halo,
  ) {
    final bob = reduceMotion
        ? 0.0
        : math.sin((ambient + cell * 0.13) * math.pi * 2) * _th * 0.10;
    if (halo != null) {
      canvas.drawPath(
        _diamond(_center(cell), 0.62),
        Paint()
          ..color = halo.withValues(alpha: 0.18 + 0.12 * _pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    _drawProp(canvas, cell, asset, scale, lift: -bob - _th * 0.25);
  }

  void _drawProp(
    Canvas canvas,
    int cell,
    String asset,
    double scale, {
    double opacity = 1,
    double lift = 0,
  }) {
    final image = cache[asset];
    if (image == null) return;
    final center = _center(cell);
    final width = _tw * scale;
    final height = width * image.height / image.width;
    final bottom = center.dy + _th * 0.55 + lift;
    final dst = Rect.fromLTWH(center.dx - width / 2, bottom - height, width, height);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dst,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..color = Colors.white.withValues(alpha: opacity),
    );
  }

  void _drawPlayer(Canvas canvas) {
    final from = game.lastFrom;
    final target = _center(game.player);
    var position = target;
    var hop = 0.0;

    if (from != null && stepProgress < 1) {
      final start = _center(from);
      position = Offset.lerp(start, target, Curves.easeOutCubic
          .transform(stepProgress.clamp(0, 1)))!;
      hop = math.sin(stepProgress.clamp(0, 1) * math.pi) * _th * 0.35;
    }

    // Contact shadow keeps the walker anchored to the tile.
    canvas.drawOval(
      Rect.fromCenter(
        center: position.translate(0, _th * 0.18),
        width: _tw * 0.42,
        height: _th * 0.34,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    final image = cache[Sprites.character(characterSprite)];
    if (image == null) return;
    final width = _tw * 0.66;
    final height = width * image.height / image.width;
    final bottom = position.dy + _th * 0.28 - hop;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(position.dx - width / 2, bottom - height, width, height),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  // ------------------------------------------------------------ helpers

  Offset _center(int cell) =>
      projection.centerOf(level.xOf(cell), level.yOf(cell));

  /// Tile-shaped diamond centred on [center], sized as a fraction of a tile.
  Path _diamond(Offset center, double scale) {
    final hw = _tw / 2 * scale;
    final hh = _th / 2 * scale;
    return Path()
      ..moveTo(center.dx, center.dy - hh)
      ..lineTo(center.dx + hw, center.dy)
      ..lineTo(center.dx, center.dy + hh)
      ..lineTo(center.dx - hw, center.dy)
      ..close();
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) =>
      old.session != session ||
      old.projection != projection ||
      old.stepProgress != stepProgress ||
      old.ambient != ambient ||
      old.characterSprite != characterSprite ||
      old.showTimers != showTimers ||
      old.showGuides != showGuides ||
      old.previewRoute != previewRoute;
}
