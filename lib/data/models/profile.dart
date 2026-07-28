import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Permanent upgrades bought in the Forge.
///
/// Every effect is deliberately meta-only (budgets, rewards, hints). Nothing
/// here changes cooling physics, so the routes the generator proved winnable
/// stay winnable no matter how upgraded a player is.
enum Upgrade {
  emberheart('Emberheart', 'Adds spare moves to every run.', 5, 120, 1.65),
  prospector('Prospector', 'Increases embers earned per level.', 5, 90, 1.6),
  scholar('Scholar', 'Increases experience earned per level.', 5, 90, 1.6),
  forgeSense('Forge Sense', 'Grants extra hints in every level.', 3, 200, 2.0),
  cartographer('Cartographer', 'Previews more of the ideal route.', 3, 260, 2.1),
  relicSense('Relic Sense', 'Marks crystals hidden along the trail.', 3, 150, 1.9);

  const Upgrade(this.label, this.description, this.maxRank, this.baseCost,
      this.costGrowth);

  final String label;
  final String description;
  final int maxRank;
  final int baseCost;
  final double costGrowth;

  int costAt(int rank) => (baseCost * _pow(costGrowth, rank)).round();

  static double _pow(double base, int exp) {
    var out = 1.0;
    for (var i = 0; i < exp; i++) {
      out *= base;
    }
    return out;
  }
}

/// Everything persisted about a player.
@immutable
class PlayerProfile {
  const PlayerProfile({
    this.stars = const {},
    this.bestMoves = const {},
    this.embers = 0,
    this.xp = 0,
    this.totalMoves = 0,
    this.totalRuns = 0,
    this.totalWins = 0,
    this.totalRestarts = 0,
    this.hintsUsed = 0,
    this.undosUsed = 0,
    this.playSeconds = 0,
    this.iceMelted = 0,
    this.growthBurned = 0,
    this.gatesPassed = 0,
    this.golemSteps = 0,
    this.forgesLit = 0,
    this.crystalsFound = 0,
    this.relicsFound = const {},
    this.creaturesFound = const {},
    this.selectedCharacter = 1,
    this.upgrades = const {},
    this.achievements = const {},
    this.questDay = '',
    this.questProgress = const [0, 0, 0],
    this.questClaimed = const [false, false, false],
    this.streakDays = 0,
    this.lastPlayedDay = '',
  });

  /// Stars earned per level id (1..3).
  final Map<int, int> stars;
  final Map<int, int> bestMoves;

  final int embers;
  final int xp;

  final int totalMoves;
  final int totalRuns;
  final int totalWins;
  final int totalRestarts;
  final int hintsUsed;
  final int undosUsed;
  final int playSeconds;

  final int iceMelted;
  final int growthBurned;
  final int gatesPassed;
  final int golemSteps;
  final int forgesLit;
  final int crystalsFound;

  /// Sprite indices of discovered relics and creatures.
  final Set<int> relicsFound;
  final Set<int> creaturesFound;

  final int selectedCharacter;
  final Map<String, int> upgrades;
  final Set<String> achievements;

  final String questDay;
  final List<int> questProgress;
  final List<bool> questClaimed;
  final int streakDays;
  final String lastPlayedDay;

  // ------------------------------------------------------------- derived

  int get levelsCompleted => stars.values.where((s) => s > 0).length;
  int get totalStars => stars.values.fold(0, (a, b) => a + b);
  int get rank => 1 + (xp ~/ 500);
  int get xpInRank => xp % 500;
  double get rankProgress => xpInRank / 500;

  static const rankTitles = <String>[
    'Cinder Novice',
    'Ash Walker',
    'Ember Scout',
    'Trailwright',
    'Journeyman',
    'Heat Reader',
    'Route Master',
    'Flamewarden',
    'Forge Adept',
    'Magma Sage',
    'Obsidian Elder',
    'Forge Master',
    'Cinderforge Legend',
  ];

  String get rankTitle =>
      rankTitles[(rank - 1).clamp(0, rankTitles.length - 1)];

  int upgradeRank(Upgrade u) => upgrades[u.name] ?? 0;

  int get bonusMoves => upgradeRank(Upgrade.emberheart) * 2;
  int get bonusHints => 1 + upgradeRank(Upgrade.forgeSense);
  int get routePreview => upgradeRank(Upgrade.cartographer) * 2;
  bool get revealsCrystals => upgradeRank(Upgrade.relicSense) > 0;
  double get emberMultiplier => 1 + upgradeRank(Upgrade.prospector) * 0.15;
  double get xpMultiplier => 1 + upgradeRank(Upgrade.scholar) * 0.15;

  double get winRate => totalRuns == 0 ? 0 : totalWins / totalRuns;

  int starsInRegion(int region, int levelsPerRegion) {
    var total = 0;
    for (var i = 0; i < levelsPerRegion; i++) {
      total += stars[(region - 1) * levelsPerRegion + i] ?? 0;
    }
    return total;
  }

  int completedInRegion(int region, int levelsPerRegion) {
    var total = 0;
    for (var i = 0; i < levelsPerRegion; i++) {
      if ((stars[(region - 1) * levelsPerRegion + i] ?? 0) > 0) total++;
    }
    return total;
  }

  /// A region unlocks once the previous one is mostly cleared.
  bool isRegionUnlocked(int region, int levelsPerRegion) =>
      region <= 1 ||
      completedInRegion(region - 1, levelsPerRegion) >= levelsPerRegion - 4;

  bool isLevelUnlocked(int levelId, int levelsPerRegion) {
    final region = levelId ~/ levelsPerRegion + 1;
    if (!isRegionUnlocked(region, levelsPerRegion)) return false;
    final indexInRegion = levelId % levelsPerRegion;
    if (indexInRegion == 0) return true;
    return (stars[levelId - 1] ?? 0) > 0;
  }

  PlayerProfile copyWith({
    Map<int, int>? stars,
    Map<int, int>? bestMoves,
    int? embers,
    int? xp,
    int? totalMoves,
    int? totalRuns,
    int? totalWins,
    int? totalRestarts,
    int? hintsUsed,
    int? undosUsed,
    int? playSeconds,
    int? iceMelted,
    int? growthBurned,
    int? gatesPassed,
    int? golemSteps,
    int? forgesLit,
    int? crystalsFound,
    Set<int>? relicsFound,
    Set<int>? creaturesFound,
    int? selectedCharacter,
    Map<String, int>? upgrades,
    Set<String>? achievements,
    String? questDay,
    List<int>? questProgress,
    List<bool>? questClaimed,
    int? streakDays,
    String? lastPlayedDay,
  }) {
    return PlayerProfile(
      stars: stars ?? this.stars,
      bestMoves: bestMoves ?? this.bestMoves,
      embers: embers ?? this.embers,
      xp: xp ?? this.xp,
      totalMoves: totalMoves ?? this.totalMoves,
      totalRuns: totalRuns ?? this.totalRuns,
      totalWins: totalWins ?? this.totalWins,
      totalRestarts: totalRestarts ?? this.totalRestarts,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      undosUsed: undosUsed ?? this.undosUsed,
      playSeconds: playSeconds ?? this.playSeconds,
      iceMelted: iceMelted ?? this.iceMelted,
      growthBurned: growthBurned ?? this.growthBurned,
      gatesPassed: gatesPassed ?? this.gatesPassed,
      golemSteps: golemSteps ?? this.golemSteps,
      forgesLit: forgesLit ?? this.forgesLit,
      crystalsFound: crystalsFound ?? this.crystalsFound,
      relicsFound: relicsFound ?? this.relicsFound,
      creaturesFound: creaturesFound ?? this.creaturesFound,
      selectedCharacter: selectedCharacter ?? this.selectedCharacter,
      upgrades: upgrades ?? this.upgrades,
      achievements: achievements ?? this.achievements,
      questDay: questDay ?? this.questDay,
      questProgress: questProgress ?? this.questProgress,
      questClaimed: questClaimed ?? this.questClaimed,
      streakDays: streakDays ?? this.streakDays,
      lastPlayedDay: lastPlayedDay ?? this.lastPlayedDay,
    );
  }

  // ------------------------------------------------------- serialisation

  Map<String, dynamic> toJson() => {
        'stars': stars.map((k, v) => MapEntry('$k', v)),
        'bestMoves': bestMoves.map((k, v) => MapEntry('$k', v)),
        'embers': embers,
        'xp': xp,
        'totalMoves': totalMoves,
        'totalRuns': totalRuns,
        'totalWins': totalWins,
        'totalRestarts': totalRestarts,
        'hintsUsed': hintsUsed,
        'undosUsed': undosUsed,
        'playSeconds': playSeconds,
        'iceMelted': iceMelted,
        'growthBurned': growthBurned,
        'gatesPassed': gatesPassed,
        'golemSteps': golemSteps,
        'forgesLit': forgesLit,
        'crystalsFound': crystalsFound,
        'relicsFound': relicsFound.toList(),
        'creaturesFound': creaturesFound.toList(),
        'selectedCharacter': selectedCharacter,
        'upgrades': upgrades,
        'achievements': achievements.toList(),
        'questDay': questDay,
        'questProgress': questProgress,
        'questClaimed': questClaimed,
        'streakDays': streakDays,
        'lastPlayedDay': lastPlayedDay,
      };

  static PlayerProfile fromJson(Map<String, dynamic> json) {
    Map<int, int> intMap(Object? raw) {
      if (raw is! Map) return {};
      return {
        for (final e in raw.entries)
          if (int.tryParse('${e.key}') != null)
            int.parse('${e.key}'): (e.value as num).toInt(),
      };
    }

    Set<int> intSet(Object? raw) =>
        raw is List ? raw.map((e) => (e as num).toInt()).toSet() : {};

    return PlayerProfile(
      stars: intMap(json['stars']),
      bestMoves: intMap(json['bestMoves']),
      embers: (json['embers'] as num?)?.toInt() ?? 0,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      totalMoves: (json['totalMoves'] as num?)?.toInt() ?? 0,
      totalRuns: (json['totalRuns'] as num?)?.toInt() ?? 0,
      totalWins: (json['totalWins'] as num?)?.toInt() ?? 0,
      totalRestarts: (json['totalRestarts'] as num?)?.toInt() ?? 0,
      hintsUsed: (json['hintsUsed'] as num?)?.toInt() ?? 0,
      undosUsed: (json['undosUsed'] as num?)?.toInt() ?? 0,
      playSeconds: (json['playSeconds'] as num?)?.toInt() ?? 0,
      iceMelted: (json['iceMelted'] as num?)?.toInt() ?? 0,
      growthBurned: (json['growthBurned'] as num?)?.toInt() ?? 0,
      gatesPassed: (json['gatesPassed'] as num?)?.toInt() ?? 0,
      golemSteps: (json['golemSteps'] as num?)?.toInt() ?? 0,
      forgesLit: (json['forgesLit'] as num?)?.toInt() ?? 0,
      crystalsFound: (json['crystalsFound'] as num?)?.toInt() ?? 0,
      relicsFound: intSet(json['relicsFound']),
      creaturesFound: intSet(json['creaturesFound']),
      selectedCharacter: (json['selectedCharacter'] as num?)?.toInt() ?? 1,
      upgrades: (json['upgrades'] as Map?)?.map(
            (k, v) => MapEntry('$k', (v as num).toInt()),
          ) ??
          {},
      achievements:
          (json['achievements'] as List?)?.map((e) => '$e').toSet() ?? {},
      questDay: '${json['questDay'] ?? ''}',
      questProgress: (json['questProgress'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [0, 0, 0],
      questClaimed:
          (json['questClaimed'] as List?)?.map((e) => e == true).toList() ??
              [false, false, false],
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
      lastPlayedDay: '${json['lastPlayedDay'] ?? ''}',
    );
  }

  String encode() => jsonEncode(toJson());

  static PlayerProfile decode(String raw) {
    try {
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const PlayerProfile();
    }
  }
}
