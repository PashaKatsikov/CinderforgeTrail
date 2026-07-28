import 'package:flutter_test/flutter_test.dart';
import 'package:trailgame/game/logic/level_generator.dart';
import 'package:trailgame/game/model/level.dart';

void main() {
  test('campaign shape report', () {
    final levels = LevelGenerator.campaign();
    final byRegion = <int, List<LevelSpec>>{};
    for (final l in levels) {
      byRegion.putIfAbsent(l.region, () => []).add(l);
    }

    // ignore: avoid_print
    print('region | size | route | obstacles | kinds');
    for (final r in byRegion.keys.toList()..sort()) {
      final list = byRegion[r]!;
      final avgRoute =
          list.map((l) => l.parMoves).reduce((a, b) => a + b) / list.length;
      final avgObs = list
              .map((l) => l.obstacles.length)
              .reduce((a, b) => a + b) /
          list.length;
      final kinds = <Obstacle>{for (final l in list) ...l.obstacles.values};
      // ignore: avoid_print
      print(
        '$r      | ${list.first.width}x${list.first.height} '
        '| ${avgRoute.toStringAsFixed(1)} '
        '| ${avgObs.toStringAsFixed(1)} '
        '| ${kinds.map((k) => k.name).join(",")}',
      );
    }

    final noObstacles = levels.where((l) => l.obstacles.isEmpty).length;
    // ignore: avoid_print
    print('levels with zero obstacles: $noObstacles / ${levels.length}');
    expect(noObstacles, lessThan(10));
  });
}
