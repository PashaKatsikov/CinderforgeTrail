import 'package:flutter/material.dart';

import '../../data/models/settings.dart';
import '../logic/game_session.dart';
import 'board_painter.dart';
import 'iso.dart';
import 'sprite_cache.dart';

/// Interactive isometric board.
///
/// Owns the two animations the painter needs — a one-shot step animation and a
/// slow looping ambient value — and converts taps or swipes into moves.
class BoardView extends StatefulWidget {
  const BoardView({
    super.key,
    required this.session,
    required this.settings,
    required this.characterSprite,
    required this.routePreviewSteps,
    required this.onMove,
    required this.onRejected,
  });

  final GameSession session;
  final AppSettings settings;
  final int characterSprite;
  final int routePreviewSteps;
  final VoidCallback onMove;
  final VoidCallback onRejected;

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView>
    with TickerProviderStateMixin {
  late final AnimationController _step = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  int _lastTicket = 0;
  Offset? _dragStart;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSessionChanged);
    if (widget.settings.reduceMotion) _ambient.stop();
  }

  @override
  void didUpdateWidget(covariant BoardView old) {
    super.didUpdateWidget(old);
    if (old.session != widget.session) {
      old.session.removeListener(_onSessionChanged);
      widget.session.addListener(_onSessionChanged);
    }
    if (widget.settings.reduceMotion && _ambient.isAnimating) {
      _ambient.stop();
    } else if (!widget.settings.reduceMotion && !_ambient.isAnimating) {
      _ambient.repeat();
    }
  }

  void _onSessionChanged() {
    final ticket = widget.session.value.moveTicket;
    if (ticket != _lastTicket) {
      _lastTicket = ticket;
      _step.forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionChanged);
    _step.dispose();
    _ambient.dispose();
    super.dispose();
  }

  void _attempt(int cell) {
    if (widget.session.moveTo(cell)) {
      widget.onMove();
    } else {
      widget.onRejected();
      Future.delayed(const Duration(milliseconds: 420), () {
        if (mounted) widget.session.clearRejection();
      });
    }
  }

  void _attemptDirection(int dx, int dy) {
    final session = widget.session;
    final level = session.level;
    final player = session.value.game.player;
    final x = level.xOf(player) + dx;
    final y = level.yOf(player) + dy;
    if (!level.inBounds(x, y)) {
      widget.onRejected();
      return;
    }
    _attempt(level.cellAt(x, y));
  }

  bool get _tapEnabled => widget.settings.controls != ControlScheme.swipe;
  bool get _swipeEnabled => widget.settings.controls != ControlScheme.tapTile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final level = widget.session.level;
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final tileWidth = IsoProjection.fitTileWidth(
              size,
              level.width,
              level.height,
              headroom: size.height * 0.16,
            ) *
            widget.settings.boardScale;

        final board = IsoProjection.sizeFor(
          level.width,
          level.height,
          tileWidth,
        );
        final projection = IsoProjection(
          columns: level.width,
          rows: level.height,
          tileWidth: tileWidth,
          // Shift right so the leftmost tile lands at x = 0, then centre the
          // whole diamond and leave headroom for tall props.
          origin: Offset(
            (size.width - board.width) / 2 + level.height * tileWidth / 2,
            (size.height - board.height) / 2 + size.height * 0.05,
          ),
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: _tapEnabled
              ? (details) {
                  final hit = projection.cellAt(details.localPosition);
                  if (hit == null) return;
                  _attempt(level.cellAt(hit.column, hit.row));
                }
              : null,
          onPanStart: _swipeEnabled
              ? (details) => _dragStart = details.localPosition
              : null,
          onPanEnd: _swipeEnabled
              ? (details) {
                  final start = _dragStart;
                  _dragStart = null;
                  if (start == null) return;
                  final v = details.velocity.pixelsPerSecond;
                  if (v.distance < 120) return;
                  // Screen axes are rotated 45 degrees relative to the grid,
                  // so a swipe maps to whichever grid axis it leans toward.
                  final gridX = v.dx / 2 + v.dy;
                  final gridY = v.dy - v.dx / 2;
                  if (gridX.abs() > gridY.abs()) {
                    _attemptDirection(gridX > 0 ? 1 : -1, 0);
                  } else {
                    _attemptDirection(0, gridY > 0 ? 1 : -1);
                  }
                }
              : null,
          child: ValueListenableBuilder<SessionState>(
            valueListenable: widget.session,
            builder: (context, session, _) {
              return AnimatedBuilder(
                animation: Listenable.merge([_step, _ambient]),
                builder: (context, _) {
                  return CustomPaint(
                    size: size,
                    isComplex: true,
                    willChange: true,
                    painter: BoardPainter(
                      session: session,
                      projection: projection,
                      cache: SpriteCache.instance,
                      characterSprite: widget.characterSprite,
                      stepProgress: _step.value,
                      ambient: _ambient.value,
                      showTimers: widget.settings.showTrailTimers,
                      showGuides: widget.settings.showGridGuides,
                      previewRoute: widget.session
                          .previewRoute(widget.routePreviewSteps),
                      highlightCrystals: widget.routePreviewSteps >= 0,
                      reduceMotion: widget.settings.reduceMotion,
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
