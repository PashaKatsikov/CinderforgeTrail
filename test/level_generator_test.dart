import 'package:flutter_test/flutter_test.dart';
import 'package:trailgame/game/logic/engine.dart';
import 'package:trailgame/game/logic/level_generator.dart';
import 'package:trailgame/game/model/level.dart';

void main() {
  test('every campaign level is solvable by its stored route', () {
    final levels = LevelGenerator.campaign();
    expect(levels.length, LevelGenerator.totalLevels);

    var fallbacks = 0;
    for (final level in levels) {
      expect(
        Engine.verify(level, level.solution),
        isTrue,
        reason: 'level ${level.id} (region ${level.region}) is unsolvable',
      );
      expect(level.solution.first, level.start);
      expect(level.solution.last, level.exit);
      expect(level.parMoves, level.solution.length - 1);
      if (level.obstacles.isEmpty && level.width == 5 && level.decor.isEmpty) {
        fallbacks++;
      }
    }
    expect(fallbacks, lessThan(6), reason: 'too many generator fallbacks');
  });

  test('every level is a forging job', () {
    for (final level in LevelGenerator.campaign()) {
      expect(
        level.forgeStages,
        isNotEmpty,
        reason: 'level ${level.id} has no forge to light',
      );
      for (final cell in level.forgeStages.keys) {
        expect(level.obstacles[cell], Obstacle.forge);
      }
      expect(
        level.forgeStages.length,
        lessThanOrEqualTo(4),
        reason: 'level ${level.id} asks for too many forges at once',
      );
    }
  });

  test('the gate stays barred until the last forge is lit', () {
    for (final level in LevelGenerator.campaign().take(24)) {
      var state = GameState.initial(level);
      expect(Engine.isOpen(state, level.exit), isFalse);

      for (var i = 1; i < level.solution.length - 1; i++) {
        state = Engine.move(state, level.solution[i])!;
        expect(
          Engine.isOpen(state, level.exit),
          state.allForgesLit,
          reason: 'level ${level.id} gate disagrees with its forges',
        );
      }
      expect(state.allForgesLit, isTrue);
    }
  });

  test('levels introduce mechanics progressively', () {
    final levels = LevelGenerator.campaign();
    for (final level in levels.where((l) => l.region == 1)) {
      expect(
        level.obstacles.values
            .every((o) => o == Obstacle.iceWall || o == Obstacle.forge),
        isTrue,
        reason: 'region 1 should only teach forges and ice',
      );
    }

    expect(
      levels.where((l) => l.region < 5).every(
            (l) => !l.obstacles.containsValue(Obstacle.runeGate),
          ),
      isTrue,
      reason: 'rune seals should wait until region 5',
    );
    expect(
      levels.where((l) => l.region >= 5).any(
            (l) => l.obstacles.containsValue(Obstacle.runeGate),
          ),
      isTrue,
      reason: 'rune seals should appear from region 5',
    );
    expect(
      levels.where((l) => l.region >= 6).map((l) => l.forgeStages.length).reduce(
            (a, b) => a > b ? a : b,
          ),
      greaterThan(
        levels
            .where((l) => l.region == 1)
            .map((l) => l.forgeStages.length)
            .reduce((a, b) => a > b ? a : b),
      ),
      reason: 'later regions should ask for more forges',
    );
  });

  test('a losing run is reported, not silently accepted', () {
    final level = LevelGenerator.byId(0);
    var state = GameState.initial(level);
    expect(state.outcome, GameOutcome.playing);
    // Walking the route wins.
    for (var i = 1; i < level.solution.length; i++) {
      state = Engine.move(state, level.solution[i])!;
    }
    expect(state.outcome, GameOutcome.won);
    expect(Engine.starsFor(state), 3);
  });

  test('generation stays fast enough to run at startup', () {
    final sw = Stopwatch()..start();
    LevelGenerator.build(8, 12);
    sw.stop();
    expect(sw.elapsedMilliseconds, lessThan(500));
  });
}
