import 'dart:math';

import 'package:flutter/material.dart';

/// Counters a quest can track. Each maps to one event raised during play.
enum QuestMetric {
  levelsCompleted('levels completed'),
  starsEarned('stars earned'),
  crystalsCollected('crystals collected'),
  iceMelted('formations melted'),
  growthBurned('growths burned'),
  gatesPassed('gates passed'),
  golemSteps('golem steps taken'),
  forgesLit('forges lit'),
  stepsTaken('steps taken'),
  flawlessRuns('levels cleared at par');

  const QuestMetric(this.noun);
  final String noun;

  IconData get icon => switch (this) {
        QuestMetric.levelsCompleted => Icons.flag_rounded,
        QuestMetric.starsEarned => Icons.star_rounded,
        QuestMetric.crystalsCollected => Icons.hexagon_rounded,
        QuestMetric.iceMelted => Icons.ac_unit_rounded,
        QuestMetric.growthBurned => Icons.grass_rounded,
        QuestMetric.gatesPassed => Icons.bolt_rounded,
        QuestMetric.golemSteps => Icons.view_in_ar_rounded,
        QuestMetric.forgesLit => Icons.whatshot_rounded,
        QuestMetric.stepsTaken => Icons.directions_walk_rounded,
        QuestMetric.flawlessRuns => Icons.verified_rounded,
      };
}

@immutable
class DailyQuest {
  const DailyQuest({
    required this.title,
    required this.metric,
    required this.target,
    required this.reward,
  });

  final String title;
  final QuestMetric metric;
  final int target;
  final int reward;

  String get description => 'Reach $target ${metric.noun} today.';

  IconData get icon => metric.icon;
}

/// Deterministic daily quest roster.
///
/// The set is derived from the calendar date, so it is stable across restarts
/// and needs no server to hand out.
abstract final class DailyQuests {
  static const _pool = <DailyQuest>[
    DailyQuest(
        title: 'Keep Walking',
        metric: QuestMetric.levelsCompleted,
        target: 3,
        reward: 60),
    DailyQuest(
        title: 'Long Haul',
        metric: QuestMetric.levelsCompleted,
        target: 5,
        reward: 110),
    DailyQuest(
        title: 'Bright Sky',
        metric: QuestMetric.starsEarned,
        target: 6,
        reward: 90),
    DailyQuest(
        title: 'Rock Hound',
        metric: QuestMetric.crystalsCollected,
        target: 8,
        reward: 80),
    DailyQuest(
        title: 'Big Thaw',
        metric: QuestMetric.iceMelted,
        target: 10,
        reward: 85),
    DailyQuest(
        title: 'Slash and Burn',
        metric: QuestMetric.growthBurned,
        target: 8,
        reward: 85),
    DailyQuest(
        title: 'Live Current',
        metric: QuestMetric.gatesPassed,
        target: 6,
        reward: 95),
    DailyQuest(
        title: 'Standing Stones',
        metric: QuestMetric.golemSteps,
        target: 6,
        reward: 95),
    DailyQuest(
        title: 'Light the Dark',
        metric: QuestMetric.forgesLit,
        target: 4,
        reward: 120),
    DailyQuest(
        title: 'Pathfinder',
        metric: QuestMetric.stepsTaken,
        target: 120,
        reward: 70),
    DailyQuest(
        title: 'Clean Lines',
        metric: QuestMetric.flawlessRuns,
        target: 2,
        reward: 140),
  ];

  static String dayKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  /// Three distinct quests for the given day.
  static List<DailyQuest> forDay(String key) {
    final seed = key.codeUnits.fold<int>(7, (a, b) => a * 31 + b);
    final rng = Random(seed);
    final indices = List<int>.generate(_pool.length, (i) => i)..shuffle(rng);
    return indices.take(3).map((i) => _pool[i]).toList();
  }
}
