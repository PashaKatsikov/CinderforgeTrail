import 'dart:math';

import '../model/level.dart';
import 'engine.dart';

/// Decorative prop families that can be scattered on non-route cells.
enum DecorGroup { tree, nature, crystal, rubble, frozen, lava, rune, relicProp }

/// Builds every level in the campaign.
///
/// Rather than generating a puzzle and then searching for a solution (the
/// search space of a cooling trail explodes), the generator works the other
/// way round: it walks a route first, replays the heat timeline along it, and
/// only then drops in obstacles whose unlock conditions that timeline already
/// satisfies. Every level therefore ships with a proven solution, which is
/// re-verified through the real engine before it is handed out.
abstract final class LevelGenerator {
  static const regionCount = 8;
  static const levelsPerRegion = 12;
  static const totalLevels = regionCount * levelsPerRegion;

  static List<LevelSpec>? _cache;

  /// The full campaign, generated once and reused.
  static List<LevelSpec> campaign() {
    return _cache ??= [
      for (var r = 1; r <= regionCount; r++)
        for (var n = 1; n <= levelsPerRegion; n++) build(r, n),
    ];
  }

  static LevelSpec byId(int id) =>
      campaign()[id.clamp(0, totalLevels - 1)];

  /// Deterministically builds one level, retrying seeds until the replay
  /// through [Engine.verify] succeeds.
  static LevelSpec build(int region, int indexInRegion) {
    final id = (region - 1) * levelsPerRegion + (indexInRegion - 1);
    for (var attempt = 0; attempt < 240; attempt++) {
      final spec = _attempt(region, indexInRegion, id, id * 977 + attempt * 31);
      if (spec != null && Engine.verify(spec, spec.solution)) return spec;
    }
    // Guaranteed-simple fallback: a bare corridor with no gated obstacles.
    return _fallback(region, indexInRegion, id);
  }

  // ---------------------------------------------------------------- config

  static int _sizeFor(int region, int index) {
    final base = 5 + (region - 1) ~/ 2;
    return (base + (index > 8 ? 1 : 0)).clamp(5, 9);
  }

  static int _routeLengthFor(int region, int index, int cells) {
    final wanted = 11 + region * 2 + index;
    return wanted.clamp(9, (cells * 0.62).floor());
  }

  static List<Surface> _surfacePool(int region) => [
        Surface.stone,
        if (region >= 2) Surface.basalt,
        if (region >= 3) Surface.sand,
        if (region >= 4) Surface.slab,
        if (region >= 5) Surface.ore,
        if (region >= 6) Surface.ash,
      ];

  static List<Obstacle> _obstaclePool(int region) => [
        Obstacle.iceWall,
        if (region >= 2) Obstacle.cinderVine,
        if (region >= 3) Obstacle.magnetGate,
        if (region >= 4) Obstacle.obsidianStep,
      ];

  /// Forges are the objective, so every level has at least one and later
  /// regions ask the player to keep several different stages alive at once.
  static int _forgeCountFor(int region, int index) =>
      (1 + (region - 1) ~/ 2 + (index > 8 ? 1 : 0)).clamp(1, 4);

  /// Rune seals only make sense once forges are familiar.
  static bool _sealsEnabled(int region) => region >= 5;

  // -------------------------------------------------------------- attempt

  static LevelSpec? _attempt(int region, int index, int id, int seed) {
    final rng = Random(seed);
    final size = _sizeFor(region, index);
    final width = size;
    final height = size;
    final cells = width * height;

    final route = _walk(rng, width, height, _routeLengthFor(region, index, cells));
    if (route == null) return null;

    final surfaces = _assignSurfaces(rng, cells, _surfacePool(region));
    final snapshots = _simulate(route, surfaces, width, height);

    final onRoute = <int>{...route};
    final visitCount = <int, int>{};
    for (final c in route) {
      visitCount[c] = (visitCount[c] ?? 0) + 1;
    }

    final obstacles = <int, Obstacle>{};
    final forgeStages = <int, TrailStage>{};
    final reserved = <int>{route.first, route.last};

    // --- forges: the objective, placed before anything competes for space --
    final litBy = _placeForges(
      rng: rng,
      wanted: _forgeCountFor(region, index),
      route: route,
      snapshots: snapshots,
      width: width,
      height: height,
      onRoute: onRoute,
      obstacles: obstacles,
      forgeStages: forgeStages,
    );
    // A level whose gate can never open is not a level.
    if (forgeStages.isEmpty) return null;

    // --- gated obstacles standing directly on the route -------------------
    final pool = _obstaclePool(region);
    final budget = (2 + region + index ~/ 3).clamp(2, 9);
    final candidates = [
      for (var i = 2; i < route.length - 1; i++)
        if (visitCount[route[i]] == 1 && !reserved.contains(route[i])) i,
    ]..shuffle(rng);

    for (final i in candidates) {
      if (obstacles.length >= budget) break;
      final cell = route[i];
      final options = pool
          .where((o) => _satisfies(o, cell, i, snapshots, width, height))
          .toList();
      if (options.isEmpty) continue;
      obstacles[cell] = options[rng.nextInt(options.length)];
    }

    // --- rune seals, opened by the forges above ---------------------------
    if (_sealsEnabled(region)) {
      _addRuneSeal(
        rng: rng,
        route: route,
        firstForgeLitAt: litBy,
        obstacles: obstacles,
        reserved: reserved,
      );
    }

    // --- pickups ----------------------------------------------------------
    final free = [
      for (var i = 1; i < route.length - 1; i++)
        if (!obstacles.containsKey(route[i]) &&
            visitCount[route[i]] == 1 &&
            !reserved.contains(route[i]))
          route[i],
    ]..shuffle(rng);

    final relicCount = (1 + region ~/ 3).clamp(1, 3);
    final relics = free.take(relicCount).toSet();
    final crystals =
        free.skip(relicCount).take(1 + rng.nextInt(3)).toSet();

    // --- scenery ----------------------------------------------------------
    final voids = <int>{};
    final decor = <int, List<int>>{};
    final decorGroups = _decorGroupsFor(region);
    for (var c = 0; c < cells; c++) {
      if (onRoute.contains(c) || obstacles.containsKey(c)) continue;
      final roll = rng.nextDouble();
      if (roll < 0.20) {
        voids.add(c);
      } else if (roll < 0.52) {
        final group = decorGroups[rng.nextInt(decorGroups.length)];
        decor[c] = [group.index, 1 + rng.nextInt(_decorSpriteCount(group))];
      }
    }

    final par = route.length - 1;
    return LevelSpec(
      id: id,
      region: region,
      indexInRegion: index,
      width: width,
      height: height,
      surfaces: surfaces,
      voids: voids,
      start: route.first,
      exit: route.last,
      obstacles: obstacles,
      forgeStages: forgeStages,
      relics: relics,
      crystals: crystals,
      decor: decor,
      parMoves: par,
      moveLimit: par + 6 + region,
      solution: route,
    );
  }

  // ------------------------------------------------------------------ walk

  /// Random self-avoiding walk; falls back to revisiting a cell only when it
  /// would otherwise dead-end.
  static List<int>? _walk(Random rng, int width, int height, int target) {
    final cells = width * height;
    for (var restart = 0; restart < 60; restart++) {
      final start = rng.nextInt(cells);
      final route = <int>[start];
      final visited = <int>{start};
      var current = start;
      var previous = -1;

      while (route.length <= target) {
        final options = _neighbours(current, width, height)
            .where((n) => n != previous)
            .toList();
        if (options.isEmpty) break;
        final fresh = options.where((n) => !visited.contains(n)).toList();
        final pick = fresh.isNotEmpty
            ? fresh[rng.nextInt(fresh.length)]
            : options[rng.nextInt(options.length)];
        previous = current;
        current = pick;
        visited.add(pick);
        route.add(pick);
      }

      // The exit must be reached exactly once, at the very end.
      while (route.length > 3 &&
          route.sublist(0, route.length - 1).contains(route.last)) {
        route.removeLast();
      }
      if (route.length >= target - 2 && route.length >= 9) {
        return route;
      }
    }
    return null;
  }

  static List<int> _neighbours(int cell, int width, int height) {
    final x = cell % width, y = cell ~/ width;
    return [
      if (x > 0) cell - 1,
      if (x < width - 1) cell + 1,
      if (y > 0) cell - width,
      if (y < height - 1) cell + width,
    ];
  }

  static List<Surface> _assignSurfaces(
    Random rng,
    int cells,
    List<Surface> pool,
  ) {
    // Weighted so plain stone dominates and exotic ground stays a highlight.
    const weights = {
      Surface.stone: 44,
      Surface.basalt: 20,
      Surface.sand: 15,
      Surface.slab: 8,
      Surface.ore: 8,
      Surface.ash: 5,
    };
    final bag = <Surface>[
      for (final s in pool) ...List.filled(weights[s] ?? 10, s),
    ];
    return List<Surface>.generate(cells, (_) => bag[rng.nextInt(bag.length)]);
  }

  /// Heat map after each move of the route, ignoring obstacles (they never
  /// influence cooling, which is what makes this pre-computation valid).
  static List<List<int>> _simulate(
    List<int> route,
    List<Surface> surfaces,
    int width,
    int height,
  ) {
    final snapshots = <List<int>>[List<int>.filled(surfaces.length, 0)];
    for (var t = 1; t < route.length; t++) {
      final heat = List<int>.of(snapshots[t - 1]);
      for (var c = 0; c < heat.length; c++) {
        if (heat[c] <= 0) continue;
        final surface = surfaces[c];
        final next = heat[c] - surface.coolRate;
        heat[c] = surface.keepsColdTrail
            ? (next < Heat.frozenFloor ? Heat.frozenFloor : next)
            : (next < 0 ? 0 : next);
      }
      heat[route[t - 1]] = surfaces[route[t - 1]].initialHeat;
      snapshots.add(heat);
    }
    return snapshots;
  }

  /// Can [obstacle] sit on [cell], given the player enters it on move [step]?
  static bool _satisfies(
    Obstacle obstacle,
    int cell,
    int step,
    List<List<int>> snapshots,
    int width,
    int height,
  ) {
    final stage = obstacle.stage;
    if (stage == null) return false;
    final around = _neighbours(cell, width, height);

    if (obstacle.permanent) {
      // Cleared for good at the end of any earlier move.
      for (var t = 1; t <= step - 1; t++) {
        for (final n in around) {
          if (Heat.stageOf(snapshots[t][n]) == stage) return true;
        }
      }
      return false;
    }

    // Held open only by the heat present the instant the player steps in.
    final at = snapshots[step - 1];
    return around.any((n) => Heat.stageOf(at[n]) == stage);
  }

  /// Places up to [wanted] forges beside the route and returns the move on
  /// which the earliest of them catches.
  ///
  /// A forge is only accepted if the authored route lights it strictly before
  /// the final step, because the gate is barred until the last forge burns and
  /// the player must therefore be able to walk into it on that final move.
  static int _placeForges({
    required Random rng,
    required int wanted,
    required List<int> route,
    required List<List<int>> snapshots,
    required int width,
    required int height,
    required Set<int> onRoute,
    required Map<int, Obstacle> obstacles,
    required Map<int, TrailStage> forgeStages,
  }) {
    final deadline = route.length - 2;
    if (deadline < 1) return 0;

    final spots = <int>[
      for (var c = 0; c < width * height; c++)
        if (!onRoute.contains(c) &&
            !obstacles.containsKey(c) &&
            _neighbours(c, width, height).any(onRoute.contains))
          c,
    ]..shuffle(rng);

    var earliest = deadline;
    for (final cell in spots) {
      if (forgeStages.length >= wanted) break;
      // Keep forges apart so one lucky stretch of trail cannot light them all.
      if (forgeStages.keys.any((f) => _withinOneStep(f, cell, width, height))) {
        continue;
      }

      final around = _neighbours(cell, width, height);
      final lightsAt = <TrailStage, int>{};
      for (var t = 1; t <= deadline; t++) {
        for (final n in around) {
          final stage = Heat.stageOf(snapshots[t][n]);
          if (stage != null) lightsAt.putIfAbsent(stage, () => t);
        }
      }
      if (lightsAt.isEmpty) continue;

      final stages = lightsAt.keys.toList();
      final stage = stages[rng.nextInt(stages.length)];
      obstacles[cell] = Obstacle.forge;
      forgeStages[cell] = stage;
      final at = lightsAt[stage]!;
      if (at < earliest) earliest = at;
    }
    return earliest;
  }

  static bool _withinOneStep(int a, int b, int width, int height) {
    final dx = (a % width - b % width).abs();
    final dy = (a ~/ width - b ~/ width).abs();
    return dx <= 1 && dy <= 1;
  }

  /// Drops a rune seal on the route, after the point where the first forge
  /// catches, so the seal reads as a consequence of the forging.
  static void _addRuneSeal({
    required Random rng,
    required List<int> route,
    required int firstForgeLitAt,
    required Map<int, Obstacle> obstacles,
    required Set<int> reserved,
  }) {
    final options = [
      for (var i = firstForgeLitAt + 1; i < route.length - 1; i++)
        if (!obstacles.containsKey(route[i]) && !reserved.contains(route[i]))
          route[i],
    ];
    if (options.isEmpty) return;
    obstacles[options[rng.nextInt(options.length)]] = Obstacle.runeGate;
  }

  static List<DecorGroup> _decorGroupsFor(int region) => switch (region) {
        1 => [DecorGroup.rubble, DecorGroup.nature, DecorGroup.lava],
        2 => [DecorGroup.rubble, DecorGroup.tree, DecorGroup.rune],
        3 => [DecorGroup.nature, DecorGroup.rubble, DecorGroup.lava],
        4 => [DecorGroup.rubble, DecorGroup.rune, DecorGroup.tree],
        5 => [DecorGroup.crystal, DecorGroup.nature, DecorGroup.rune],
        6 => [DecorGroup.lava, DecorGroup.rubble, DecorGroup.tree],
        7 => [DecorGroup.rune, DecorGroup.crystal, DecorGroup.relicProp],
        _ => [DecorGroup.frozen, DecorGroup.crystal, DecorGroup.rubble],
      };

  static int _decorSpriteCount(DecorGroup group) => switch (group) {
        DecorGroup.tree => 8,
        DecorGroup.nature => 23,
        DecorGroup.crystal => 10,
        DecorGroup.rubble => 14,
        DecorGroup.frozen => 18,
        DecorGroup.lava => 12,
        DecorGroup.rune => 34,
        DecorGroup.relicProp => 25,
      };

  // -------------------------------------------------------------- fallback

  /// A plain snaking corridor. Always solvable because it has no gates at all.
  static LevelSpec _fallback(int region, int index, int id) {
    const width = 5, height = 5;
    final route = <int>[];
    for (var y = 0; y < height; y++) {
      final xs = y.isEven
          ? List.generate(width, (i) => i)
          : List.generate(width, (i) => width - 1 - i);
      for (final x in xs) {
        route.add(y * width + x);
      }
    }
    return LevelSpec(
      id: id,
      region: region,
      indexInRegion: index,
      width: width,
      height: height,
      surfaces: List.filled(width * height, Surface.stone),
      voids: const {},
      start: route.first,
      exit: route.last,
      obstacles: const {},
      forgeStages: const {},
      relics: {route[8]},
      crystals: {route[4], route[16]},
      decor: const {},
      parMoves: route.length - 1,
      moveLimit: route.length + 8,
      solution: route,
    );
  }
}
