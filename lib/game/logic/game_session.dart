import 'package:flutter/foundation.dart';

import '../model/level.dart';
import 'engine.dart';

/// Counters gathered across one attempt, handed to the profile on a win.
@immutable
class RunTally {
  const RunTally({
    this.iceMelted = 0,
    this.growthBurned = 0,
    this.gatesPassed = 0,
    this.golemSteps = 0,
    this.forgesLit = 0,
  });

  final int iceMelted;
  final int growthBurned;
  final int gatesPassed;
  final int golemSteps;
  final int forgesLit;

  RunTally plus({
    int ice = 0,
    int growth = 0,
    int gates = 0,
    int golems = 0,
    int forges = 0,
  }) =>
      RunTally(
        iceMelted: iceMelted + ice,
        growthBurned: growthBurned + growth,
        gatesPassed: gatesPassed + gates,
        golemSteps: golemSteps + golems,
        forgesLit: forgesLit + forges,
      );
}

@immutable
class _Frame {
  const _Frame(this.state, this.onRoute, this.tally);
  final GameState state;
  final bool onRoute;
  final RunTally tally;
}

/// Everything mutable about the level currently being played.
@immutable
class SessionState {
  const SessionState({
    required this.game,
    required this.onRoute,
    required this.tally,
    required this.canUndo,
    required this.hintCell,
    required this.hintsLeft,
    required this.rejectedCell,
    required this.moveTicket,
  });

  final GameState game;

  /// True while every move so far has matched the authored route, which is
  /// what lets the hint system point at the next step.
  final bool onRoute;
  final RunTally tally;
  final bool canUndo;
  final int? hintCell;
  final int hintsLeft;

  /// Set briefly when an illegal tile was tapped, to drive a shake.
  final int? rejectedCell;

  /// Increments on every accepted move so the board can retrigger animations.
  final int moveTicket;

  LevelSpec get level => game.level;
}

/// Drives one attempt at a level: moves, undo, restart and hints.
class GameSession extends ValueNotifier<SessionState> {
  GameSession({
    required LevelSpec level,
    required int extraMoves,
    required int hints,
  })  : _level = level.withExtraMoves(extraMoves),
        _hintBudget = hints,
        super(
          SessionState(
            game: GameState.initial(level.withExtraMoves(extraMoves)),
            onRoute: true,
            tally: const RunTally(),
            canUndo: false,
            hintCell: null,
            hintsLeft: hints,
            rejectedCell: null,
            moveTicket: 0,
          ),
        ) {
    _startedAt = DateTime.now();
  }

  final LevelSpec _level;
  final int _hintBudget;
  final List<_Frame> _history = [];
  late DateTime _startedAt;

  LevelSpec get level => _level;
  int get elapsedSeconds => DateTime.now().difference(_startedAt).inSeconds;

  /// Attempts a step. Returns false when the tile was not a legal target.
  bool moveTo(int cell) {
    final current = value;
    if (current.game.isOver) return false;

    final next = Engine.move(current.game, cell);
    if (next == null) {
      value = _copy(current, rejectedCell: cell, clearHint: false);
      return false;
    }

    _history.add(_Frame(current.game, current.onRoute, current.tally));

    final solution = _level.solution;
    final stillOnRoute = current.onRoute &&
        next.moves < solution.length &&
        solution[next.moves] == cell;

    value = SessionState(
      game: next,
      onRoute: stillOnRoute,
      tally: _tallyDelta(current.game, next, current.tally),
      canUndo: true,
      hintCell: null,
      hintsLeft: current.hintsLeft,
      rejectedCell: null,
      moveTicket: current.moveTicket + 1,
    );
    return true;
  }

  /// Steps one cell in a cardinal direction, for swipe controls.
  bool moveDirection(int dx, int dy) {
    final game = value.game;
    final x = _level.xOf(game.player) + dx;
    final y = _level.yOf(game.player) + dy;
    if (!_level.inBounds(x, y)) return false;
    return moveTo(_level.cellAt(x, y));
  }

  bool undo() {
    if (_history.isEmpty) return false;
    final frame = _history.removeLast();
    value = SessionState(
      game: frame.state,
      onRoute: frame.onRoute,
      tally: frame.tally,
      canUndo: _history.isNotEmpty,
      hintCell: null,
      hintsLeft: value.hintsLeft,
      rejectedCell: null,
      moveTicket: value.moveTicket + 1,
    );
    return true;
  }

  void restart() {
    _history.clear();
    _startedAt = DateTime.now();
    value = SessionState(
      game: GameState.initial(_level),
      onRoute: true,
      tally: const RunTally(),
      canUndo: false,
      hintCell: null,
      hintsLeft: _hintBudget,
      rejectedCell: null,
      moveTicket: value.moveTicket + 1,
    );
  }

  /// Reveals the next step of the proven route.
  ///
  /// When the player has already left that route the session first rewinds to
  /// the last matching position, so a hint is always actionable.
  HintOutcome hint() {
    if (value.hintsLeft <= 0) return HintOutcome.exhausted;
    if (value.game.isOver) return HintOutcome.unavailable;

    var rewound = false;
    while (!value.onRoute && _history.isNotEmpty) {
      undo();
      rewound = true;
    }
    if (!value.onRoute) return HintOutcome.unavailable;

    final nextIndex = value.game.moves + 1;
    if (nextIndex >= _level.solution.length) return HintOutcome.unavailable;

    value = _copy(
      value,
      hintCell: _level.solution[nextIndex],
      hintsLeft: value.hintsLeft - 1,
    );
    return rewound ? HintOutcome.rewound : HintOutcome.shown;
  }

  /// The first few steps of the ideal route, granted by the Cartographer
  /// upgrade and shown as a faint ghost trail.
  List<int> previewRoute(int steps) {
    if (steps <= 0 || !value.onRoute) return const [];
    final from = value.game.moves + 1;
    final to = (from + steps).clamp(0, _level.solution.length);
    if (from >= to) return const [];
    return _level.solution.sublist(from, to);
  }

  void clearRejection() {
    if (value.rejectedCell == null) return;
    value = _copy(value, rejectedCell: null);
  }

  RunTally _tallyDelta(GameState before, GameState after, RunTally tally) {
    var ice = 0, growth = 0, gates = 0, golems = 0, forges = 0;

    for (final cell in after.cleared) {
      if (before.cleared.contains(cell)) continue;
      switch (_level.obstacles[cell]) {
        case Obstacle.iceWall:
          ice++;
        case Obstacle.cinderVine:
          growth++;
        default:
          break;
      }
    }
    forges = after.litForges.length - before.litForges.length;

    switch (_level.obstacles[after.player]) {
      case Obstacle.magnetGate:
        gates++;
      case Obstacle.obsidianStep:
        golems++;
      default:
        break;
    }

    return tally.plus(
      ice: ice,
      growth: growth,
      gates: gates,
      golems: golems,
      forges: forges < 0 ? 0 : forges,
    );
  }

  SessionState _copy(
    SessionState base, {
    int? hintCell,
    int? hintsLeft,
    int? rejectedCell,
    bool clearHint = true,
  }) =>
      SessionState(
        game: base.game,
        onRoute: base.onRoute,
        tally: base.tally,
        canUndo: base.canUndo,
        hintCell: hintCell ?? (clearHint ? null : base.hintCell),
        hintsLeft: hintsLeft ?? base.hintsLeft,
        rejectedCell: rejectedCell,
        moveTicket: base.moveTicket,
      );
}

enum HintOutcome { shown, rewound, exhausted, unavailable }
