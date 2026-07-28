import 'package:flutter/material.dart';

import '../../core/design/palette.dart';
import '../../data/sprites.dart';
import '../logic/level_generator.dart';
import '../model/level.dart';

/// Chooses which sliced sprite represents each piece of level content.
///
/// Selection is deterministic (derived from the cell index) so a level looks
/// identical every time it is opened, without storing art in the level data.
abstract final class BoardArt {
  static String ground(Surface surface) => switch (surface) {
        Surface.stone => Sprites.ground(2),
        Surface.sand => Sprites.ground(7),
        Surface.basalt => Sprites.ground(10),
        Surface.ore => Sprites.ground(8),
        Surface.ash => Sprites.ground(3),
        Surface.slab => Sprites.ground(6),
      };

  static Color surfaceTint(Surface surface) => switch (surface) {
        Surface.stone => Palette.textMuted,
        Surface.sand => const Color(0xFFD8B27A),
        Surface.basalt => const Color(0xFF6B6478),
        Surface.ore => Palette.gold,
        Surface.ash => const Color(0xFF8A8290),
        Surface.slab => Palette.arcane,
      };

  /// Frozen formations double as the ice walls.
  static String iceWall(int cell) => Sprites.frozen(1 + cell % 7);

  /// Scrubby volcanic growth stands in for the burnable vines.
  static String cinderVine(int cell) => Sprites.nature(1 + cell % 9);

  static const magnetGateClosed = 'mechanism_11';
  static String magnetGate() => Sprites.mechanism(11);

  /// The golem itself is the platform that rises on cold obsidian.
  static String golemActive() => Sprites.creature(4);

  static String golemDormant(int cell) => Sprites.obstacle(6 + cell % 3);

  static String runeSeal() => Sprites.mechanism(8);

  static String forge(TrailStage stage) => switch (stage) {
        TrailStage.magma => Sprites.mechanism(5),
        TrailStage.ember => Sprites.mechanism(13),
        TrailStage.metal => Sprites.mechanism(16),
        TrailStage.obsidian => Sprites.mechanism(14),
      };

  static String exitPortal() => Sprites.mechanism(10);

  static String relic(int levelId) => Sprites.relic(1 + levelId % 25);

  static String crystal(int cell) => Sprites.crystal(1 + cell % 10);

  static String decor(List<int> entry) {
    final group = DecorGroup.values[entry[0].clamp(0, DecorGroup.values.length - 1)];
    final index = entry.length > 1 ? entry[1] : 1;
    return switch (group) {
      DecorGroup.tree => Sprites.tree(index),
      DecorGroup.nature => Sprites.nature(index),
      DecorGroup.crystal => Sprites.crystal(index),
      DecorGroup.rubble => Sprites.obstacle(index),
      DecorGroup.frozen => Sprites.frozen(index),
      DecorGroup.lava => Sprites.lava(index),
      DecorGroup.rune => Sprites.rune(index),
      DecorGroup.relicProp => Sprites.relic(index),
    };
  }

  /// Relative width of a prop compared with a tile.
  static double decorScale(List<int> entry) {
    final group = DecorGroup.values[entry[0].clamp(0, DecorGroup.values.length - 1)];
    return switch (group) {
      DecorGroup.tree => 1.15,
      DecorGroup.nature => 0.88,
      DecorGroup.crystal => 0.8,
      DecorGroup.rubble => 0.95,
      DecorGroup.frozen => 0.95,
      DecorGroup.lava => 1.0,
      DecorGroup.rune => 0.7,
      DecorGroup.relicProp => 0.62,
    };
  }

  static Color stageColor(TrailStage stage) => switch (stage) {
        TrailStage.magma => Palette.magma,
        TrailStage.ember => Palette.cinder,
        TrailStage.metal => Palette.metal,
        TrailStage.obsidian => Palette.obsidian,
      };

  /// Brighter inner colour that makes hot trail read as molten.
  static Color stageCore(TrailStage stage) => switch (stage) {
        TrailStage.magma => const Color(0xFFFFD48A),
        TrailStage.ember => const Color(0xFFFF8A45),
        TrailStage.metal => const Color(0xFFFFE9BE),
        TrailStage.obsidian => const Color(0xFF9AA1B8),
      };

  static IconData stageIcon(TrailStage stage) => switch (stage) {
        TrailStage.magma => Icons.local_fire_department_rounded,
        TrailStage.ember => Icons.whatshot_rounded,
        TrailStage.metal => Icons.bolt_rounded,
        TrailStage.obsidian => Icons.hexagon_rounded,
      };

  static IconData obstacleIcon(Obstacle obstacle) => switch (obstacle) {
        Obstacle.iceWall => Icons.ac_unit_rounded,
        Obstacle.cinderVine => Icons.grass_rounded,
        Obstacle.magnetGate => Icons.sensor_door_rounded,
        Obstacle.obsidianStep => Icons.view_in_ar_rounded,
        Obstacle.forge => Icons.local_fire_department_rounded,
        Obstacle.runeGate => Icons.lock_rounded,
      };

  /// Art shown for an obstacle in the codex and level briefings.
  static String obstaclePortrait(Obstacle obstacle) => switch (obstacle) {
        Obstacle.iceWall => Sprites.frozen(1),
        Obstacle.cinderVine => Sprites.nature(4),
        Obstacle.magnetGate => Sprites.mechanism(11),
        Obstacle.obsidianStep => Sprites.creature(4),
        Obstacle.forge => Sprites.mechanism(5),
        Obstacle.runeGate => Sprites.mechanism(8),
      };

  /// Every asset a level can possibly draw, for pre-decoding.
  static Set<String> assetsFor(LevelSpec level, int characterSprite) {
    final assets = <String>{
      Sprites.character(characterSprite),
      exitPortal(),
      relic(level.id),
      Sprites.background(level.region),
    };
    for (final surface in Surface.values) {
      assets.add(ground(surface));
    }
    level.obstacles.forEach((cell, obstacle) {
      switch (obstacle) {
        case Obstacle.iceWall:
          assets.add(iceWall(cell));
        case Obstacle.cinderVine:
          assets.add(cinderVine(cell));
        case Obstacle.magnetGate:
          assets.add(magnetGate());
        case Obstacle.obsidianStep:
          assets
            ..add(golemActive())
            ..add(golemDormant(cell));
        case Obstacle.runeGate:
          assets.add(runeSeal());
        case Obstacle.forge:
          assets.add(forge(level.forgeStages[cell] ?? TrailStage.magma));
      }
    });
    for (final cell in level.crystals) {
      assets.add(crystal(cell));
    }
    for (final entry in level.decor.values) {
      assets.add(decor(entry));
    }
    return assets;
  }
}
