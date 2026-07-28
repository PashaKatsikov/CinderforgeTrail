import 'package:flutter/foundation.dart';

/// The four stages a trail passes through as it cools.
///
/// Every temperature-gated obstacle in the game is keyed to exactly one stage,
/// which is what turns a route into a timing puzzle.
enum TrailStage {
  magma('Magma', 'Molten rock. Melts ice and lights fire forges.'),
  ember('Ember', 'Smouldering coals. Burns cinder growth away.'),
  metal('Molten Metal', 'Conducts energy. Powers magnetic gates.'),
  obsidian('Obsidian', 'Cold, solid glass. Raises golem steps.');

  const TrailStage(this.label, this.description);
  final String label;
  final String description;
}

/// Ground materials, which decide how quickly a trail on them cools.
enum Surface {
  stone('Basalt Plate', 'Cools at a steady, predictable rate.', 2, 24),
  sand('Volcanic Sand', 'Holds heat for much longer than stone.', 1, 24),
  basalt('Cracked Basalt', 'Sheds heat quickly.', 3, 24),
  ore('Metal Ore', 'Superheats any trail laid across it.', 2, 34),
  ash('Ash Field', 'Devours a trail almost as fast as it forms.', 5, 24),
  slab('Obsidian Slab', 'A trail here never fades away completely.', 2, 24);

  const Surface(this.label, this.description, this.coolRate, this.initialHeat);

  final String label;
  final String description;

  /// Heat lost per player move.
  final int coolRate;

  /// Heat given to a freshly laid trail.
  final int initialHeat;

  /// Obsidian slabs keep a permanent cold trail once one has been laid.
  bool get keepsColdTrail => this == Surface.slab;
}

/// Things that occupy a cell and block or gate movement.
enum Obstacle {
  iceWall(
    'Frozen Formation',
    'Melts for good once magma runs beside it.',
    TrailStage.magma,
    permanent: true,
  ),
  cinderVine(
    'Cinder Growth',
    'Burns away for good beside smouldering embers.',
    TrailStage.ember,
    permanent: true,
  ),
  magnetGate(
    'Magnetic Gate',
    'Stays open only while molten metal lies next to it.',
    TrailStage.metal,
    permanent: false,
  ),
  obsidianStep(
    'Golem Step',
    'A golem rises only while cold obsidian lies next to it.',
    TrailStage.obsidian,
    permanent: false,
  ),
  forge(
    'Ancient Forge',
    'Lights when its own stage touches it, unsealing every rune gate.',
    null,
    permanent: false,
    walkable: false,
  ),
  runeGate(
    'Rune Seal',
    'Held shut until an ancient forge is lit.',
    null,
    permanent: true,
  );

  const Obstacle(
    this.label,
    this.description,
    this.stage, {
    required this.permanent,
    this.walkable = true,
  });

  final String label;
  final String description;

  /// The cooling stage that clears or opens this obstacle, when fixed.
  final TrailStage? stage;

  /// Whether clearing it is irreversible.
  final bool permanent;

  /// Forges are scenery: they can never be stepped on.
  final bool walkable;
}

/// A fully authored, immutable puzzle.
@immutable
class LevelSpec {
  const LevelSpec({
    required this.id,
    required this.region,
    required this.indexInRegion,
    required this.width,
    required this.height,
    required this.surfaces,
    required this.voids,
    required this.start,
    required this.exit,
    required this.obstacles,
    required this.forgeStages,
    required this.relics,
    required this.crystals,
    required this.decor,
    required this.parMoves,
    required this.moveLimit,
    required this.solution,
  });

  final int id;
  final int region;
  final int indexInRegion;
  final int width;
  final int height;

  /// Surface material per cell, row-major.
  final List<Surface> surfaces;

  /// Cells that are open chasm and can never be entered.
  final Set<int> voids;

  final int start;
  final int exit;

  final Map<int, Obstacle> obstacles;

  /// Required stage per forge cell.
  final Map<int, TrailStage> forgeStages;

  final Set<int> relics;
  final Set<int> crystals;

  /// Purely decorative props keyed by cell: `[group, spriteIndex]`.
  final Map<int, List<int>> decor;

  final int parMoves;
  final int moveLimit;

  /// The route the generator proved to be winnable; drives the hint system.
  final List<int> solution;

  int get cellCount => width * height;

  int cellAt(int x, int y) => y * width + x;
  int xOf(int cell) => cell % width;
  int yOf(int cell) => cell ~/ width;

  bool inBounds(int x, int y) =>
      x >= 0 && y >= 0 && x < width && y < height;

  /// Orthogonal neighbours of [cell] that lie on the board.
  List<int> neighbours(int cell) {
    final x = xOf(cell), y = yOf(cell);
    return [
      if (x > 0) cell - 1,
      if (x < width - 1) cell + 1,
      if (y > 0) cell - width,
      if (y < height - 1) cell + width,
    ];
  }

  String get title => 'Level $indexInRegion';

  /// Returns a copy with a looser move budget, used to apply the Emberheart
  /// upgrade without touching any of the level's puzzle content.
  LevelSpec withExtraMoves(int extra) => extra <= 0
      ? this
      : LevelSpec(
          id: id,
          region: region,
          indexInRegion: indexInRegion,
          width: width,
          height: height,
          surfaces: surfaces,
          voids: voids,
          start: start,
          exit: exit,
          obstacles: obstacles,
          forgeStages: forgeStages,
          relics: relics,
          crystals: crystals,
          decor: decor,
          parMoves: parMoves,
          moveLimit: moveLimit + extra,
          solution: solution,
        );
}
