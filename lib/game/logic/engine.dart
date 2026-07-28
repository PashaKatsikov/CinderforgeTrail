import 'package:flutter/foundation.dart';

import '../model/level.dart';

/// Heat thresholds that separate the four cooling stages.
abstract final class Heat {
  static const magma = 19;
  static const ember = 13;
  static const metal = 7;
  static const gone = 0;

  /// Cold trails on obsidian slabs settle here instead of disappearing.
  static const frozenFloor = 1;

  static TrailStage? stageOf(int heat) {
    if (heat >= magma) return TrailStage.magma;
    if (heat >= ember) return TrailStage.ember;
    if (heat >= metal) return TrailStage.metal;
    if (heat > gone) return TrailStage.obsidian;
    return null;
  }

  /// 0..1 progress through the current stage, used for the cooling animation.
  static double stageProgress(int heat) {
    final stage = stageOf(heat);
    return switch (stage) {
      TrailStage.magma => ((heat - magma) / 6).clamp(0.0, 1.0),
      TrailStage.ember => (heat - ember) / (magma - ember),
      TrailStage.metal => (heat - metal) / (ember - metal),
      TrailStage.obsidian => (heat - 1) / (metal - 1),
      null => 0,
    };
  }
}

/// Why a level ended.
enum GameOutcome { playing, won, lostOutOfMoves, lostStuck }

/// A single, immutable snapshot of a run. Every move produces a new instance,
/// which is what makes undo a plain list of past states.
@immutable
class GameState {
  const GameState({
    required this.level,
    required this.player,
    required this.heat,
    required this.cleared,
    required this.litForges,
    required this.relics,
    required this.crystals,
    required this.moves,
    required this.outcome,
    required this.lastFrom,
  });

  factory GameState.initial(LevelSpec level) => GameState(
        level: level,
        player: level.start,
        heat: List<int>.filled(level.cellCount, 0),
        cleared: const <int>{},
        litForges: const <int>{},
        relics: const <int>{},
        crystals: const <int>{},
        moves: 0,
        outcome: GameOutcome.playing,
        lastFrom: null,
      );

  final LevelSpec level;
  final int player;

  /// Remaining heat per cell; 0 means no trail.
  final List<int> heat;

  /// Obstacles removed for good (melted ice, burnt growth, broken seals).
  final Set<int> cleared;
  final Set<int> litForges;
  final Set<int> relics;
  final Set<int> crystals;
  final int moves;
  final GameOutcome outcome;

  /// Where the player stepped from, for the walk animation.
  final int? lastFrom;

  bool get isOver => outcome != GameOutcome.playing;
  bool get hasAllRelics => relics.length >= level.relics.length;
  int get movesLeft => level.moveLimit - moves;

  /// Forges are the level's objective: the gate stays sealed until the last
  /// one has been lit.
  int get forgeCount => level.forgeStages.length;
  int get forgesLeft => forgeCount - litForges.length;
  bool get allForgesLit => litForges.length >= forgeCount;

  TrailStage? stageAt(int cell) => Heat.stageOf(heat[cell]);
}

/// Pure rules for the trail puzzle. Nothing here touches Flutter or storage,
/// which lets the generator replay levels through the exact same code path
/// that the player will.
abstract final class Engine {
  /// Whether [cell] can be occupied right now.
  static bool isOpen(GameState s, int cell) {
    final level = s.level;
    if (cell < 0 || cell >= level.cellCount) return false;
    if (level.voids.contains(cell)) return false;
    if (level.decor.containsKey(cell)) return false;

    // The gate is barred, not merely unrewarding, until every forge burns.
    // Making it impassable keeps the objective unambiguous on the board.
    if (cell == level.exit && !s.allForgesLit) return false;

    final obstacle = level.obstacles[cell];
    if (obstacle == null) return true;
    if (s.cleared.contains(cell)) return true;
    if (!obstacle.walkable) return false;

    // Temporary gates read the live heat of their neighbours.
    final stage = obstacle.stage;
    if (stage == null || obstacle.permanent) return false;
    return level.neighbours(cell).any((n) => s.stageAt(n) == stage);
  }

  static bool areAdjacent(LevelSpec level, int a, int b) {
    final dx = (level.xOf(a) - level.xOf(b)).abs();
    final dy = (level.yOf(a) - level.yOf(b)).abs();
    return dx + dy == 1;
  }

  static List<int> legalMoves(GameState s) =>
      s.level.neighbours(s.player).where((c) => isOpen(s, c)).toList();

  static bool canMoveTo(GameState s, int target) =>
      !s.isOver &&
      areAdjacent(s.level, s.player, target) &&
      isOpen(s, target);

  /// Applies one step and resolves every consequence of it.
  ///
  /// Returns `null` when the move is illegal so callers can play a rejection
  /// cue without having to re-check the rules themselves.
  static GameState? move(GameState s, int target) {
    if (!canMoveTo(s, target)) return null;
    final level = s.level;
    final from = s.player;

    // 1. Existing trails cool by the rate of the ground they sit on.
    final heat = List<int>.of(s.heat);
    for (var c = 0; c < heat.length; c++) {
      if (heat[c] <= 0) continue;
      final surface = level.surfaces[c];
      final next = heat[c] - surface.coolRate;
      heat[c] = surface.keepsColdTrail
          ? (next < Heat.frozenFloor ? Heat.frozenFloor : next)
          : (next < 0 ? 0 : next);
    }

    // 2. The vacated cell takes a fresh, full-heat trail.
    heat[from] = level.surfaces[from].initialHeat;

    // 3. Collect whatever sits on the destination.
    final relics = level.relics.contains(target)
        ? {...s.relics, target}
        : s.relics;
    final crystals = level.crystals.contains(target)
        ? {...s.crystals, target}
        : s.crystals;

    // 4. Resolve the environment against the new heat map.
    final cleared = <int>{...s.cleared};
    final lit = <int>{...s.litForges};
    var forgeJustLit = false;

    level.obstacles.forEach((cell, obstacle) {
      if (obstacle == Obstacle.forge) {
        if (lit.contains(cell)) return;
        final required = level.forgeStages[cell];
        if (required == null) return;
        final touched = level
            .neighbours(cell)
            .any((n) => Heat.stageOf(heat[n]) == required);
        if (touched) {
          lit.add(cell);
          forgeJustLit = true;
        }
        return;
      }
      if (!obstacle.permanent || obstacle == Obstacle.runeGate) return;
      if (cleared.contains(cell)) return;
      final stage = obstacle.stage;
      if (stage == null) return;
      if (level.neighbours(cell).any((n) => Heat.stageOf(heat[n]) == stage)) {
        cleared.add(cell);
      }
    });

    if (forgeJustLit || lit.isNotEmpty) {
      level.obstacles.forEach((cell, obstacle) {
        if (obstacle == Obstacle.runeGate) cleared.add(cell);
      });
    }

    final moves = s.moves + 1;
    var next = GameState(
      level: level,
      player: target,
      heat: heat,
      cleared: cleared,
      litForges: lit,
      relics: relics,
      crystals: crystals,
      moves: moves,
      outcome: GameOutcome.playing,
      lastFrom: from,
    );

    // 5. Decide whether the run ended. Reaching the gate is proof enough that
    //    the forges are lit, since [isOpen] would have blocked the step.
    if (target == level.exit) {
      return _withOutcome(next, GameOutcome.won);
    }
    if (moves >= level.moveLimit) {
      return _withOutcome(next, GameOutcome.lostOutOfMoves);
    }
    if (legalMoves(next).isEmpty) {
      return _withOutcome(next, GameOutcome.lostStuck);
    }
    return next;
  }

  static GameState _withOutcome(GameState s, GameOutcome outcome) => GameState(
        level: s.level,
        player: s.player,
        heat: s.heat,
        cleared: s.cleared,
        litForges: s.litForges,
        relics: s.relics,
        crystals: s.crystals,
        moves: s.moves,
        outcome: outcome,
        lastFrom: s.lastFrom,
      );

  /// Replays an authored route to prove it still wins. Used by the generator
  /// so a level can never ship in an unsolvable state.
  static bool verify(LevelSpec level, List<int> route) {
    var s = GameState.initial(level);
    for (var i = 1; i < route.length; i++) {
      final next = move(s, route[i]);
      if (next == null) return false;
      s = next;
      if (s.outcome == GameOutcome.won) return i == route.length - 1;
      if (s.isOver) return false;
    }
    return false;
  }

  /// Stars are awarded for finishing, for finishing tidily, and for finishing
  /// at par with every relic and crystal in hand.
  static int starsFor(GameState s) {
    if (s.outcome != GameOutcome.won) return 0;
    var stars = 1;
    if (s.moves <= s.level.parMoves + 3) stars++;
    if (s.moves <= s.level.parMoves &&
        s.crystals.length >= s.level.crystals.length &&
        s.relics.length >= s.level.relics.length) {
      stars++;
    }
    return stars;
  }
}
