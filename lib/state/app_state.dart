import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/audio_service.dart';
import '../core/services/storage_service.dart';
import '../data/catalog.dart';
import '../data/daily_quests.dart';
import '../data/models/profile.dart';
import '../data/models/settings.dart';
import '../game/logic/level_generator.dart';
import '../game/model/level.dart';

/// Injected once at start-up from `main`.
final storageProvider = Provider<StorageService>(
  (ref) => throw UnimplementedError('storageProvider must be overridden'),
);

final audioProvider = Provider<AudioService>(
  (ref) => throw UnimplementedError('audioProvider must be overridden'),
);

final campaignProvider = Provider<List<LevelSpec>>(
  (ref) => LevelGenerator.campaign(),
);

/// Result of finishing a level, used to update progress in one place.
class RunResult {
  const RunResult({
    required this.levelId,
    required this.stars,
    required this.moves,
    required this.par,
    required this.crystals,
    required this.iceMelted,
    required this.growthBurned,
    required this.gatesPassed,
    required this.golemSteps,
    required this.forgesLit,
    required this.seconds,
  });

  final int levelId;
  final int stars;
  final int moves;
  final int par;
  final int crystals;
  final int iceMelted;
  final int growthBurned;
  final int gatesPassed;
  final int golemSteps;
  final int forgesLit;
  final int seconds;

  bool get atPar => moves <= par;
}

/// Rewards handed out for a completed run, surfaced on the results screen.
class RunRewards {
  const RunRewards({
    required this.embers,
    required this.xp,
    required this.relicSprite,
    required this.creatureSprite,
    required this.newAchievements,
    required this.improvedStars,
  });

  final int embers;
  final int xp;

  /// Relic revealed by this run, or null when it was already known.
  final int? relicSprite;
  final int? creatureSprite;
  final List<AchievementInfo> newAchievements;
  final bool improvedStars;
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._storage, this._audio) : super(_storage.loadSettings()) {
    _syncAudio();
  }

  final StorageService _storage;
  final AudioService _audio;

  void update(AppSettings next) {
    state = next;
    _syncAudio();
    _storage.saveSettings(next);
  }

  void _syncAudio() {
    _audio
      ..enabled = state.soundEnabled
      ..volume = state.soundVolume
      ..haptics = state.hapticsEnabled;
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(storageProvider), ref.watch(audioProvider));
});

class ProfileNotifier extends StateNotifier<PlayerProfile> {
  ProfileNotifier(this._storage) : super(_storage.loadProfile()) {
    _rollDailyIfNeeded();
    _touchStreak();
  }

  final StorageService _storage;

  void _persist(PlayerProfile next) {
    state = next;
    _storage.saveProfile(next);
  }

  void _rollDailyIfNeeded() {
    final today = DailyQuests.dayKey();
    if (state.questDay == today) return;
    _persist(state.copyWith(
      questDay: today,
      questProgress: [0, 0, 0],
      questClaimed: [false, false, false],
    ));
  }

  /// Extends the play streak when the app is opened on a new day.
  void _touchStreak() {
    final today = DailyQuests.dayKey();
    if (state.lastPlayedDay == today) return;
    final yesterday = DailyQuests.dayKey(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final streak = state.lastPlayedDay == yesterday ? state.streakDays + 1 : 1;
    _persist(state.copyWith(lastPlayedDay: today, streakDays: streak));
  }

  void registerRunStarted() =>
      _persist(state.copyWith(totalRuns: state.totalRuns + 1));

  void registerRestart() =>
      _persist(state.copyWith(totalRestarts: state.totalRestarts + 1));

  void registerHint() =>
      _persist(state.copyWith(hintsUsed: state.hintsUsed + 1));

  void registerUndo() =>
      _persist(state.copyWith(undosUsed: state.undosUsed + 1));

  void selectCharacter(int sprite) =>
      _persist(state.copyWith(selectedCharacter: sprite));

  bool buyUpgrade(Upgrade upgrade) {
    final rank = state.upgradeRank(upgrade);
    if (rank >= upgrade.maxRank) return false;
    final cost = upgrade.costAt(rank);
    if (state.embers < cost) return false;
    _persist(state.copyWith(
      embers: state.embers - cost,
      upgrades: {...state.upgrades, upgrade.name: rank + 1},
    ));
    return true;
  }

  /// Claims a finished daily quest and pays out its reward.
  bool claimQuest(int index) {
    final quests = DailyQuests.forDay(state.questDay);
    if (index < 0 || index >= quests.length) return false;
    if (state.questClaimed[index]) return false;
    if (state.questProgress[index] < quests[index].target) return false;
    final claimed = [...state.questClaimed]..[index] = true;
    _persist(state.copyWith(
      questClaimed: claimed,
      embers: state.embers + quests[index].reward,
    ));
    return true;
  }

  /// Applies a finished run: stars, currency, discoveries and quest progress.
  RunRewards completeRun(RunResult result) {
    _rollDailyIfNeeded();

    final previousStars = state.stars[result.levelId] ?? 0;
    final improved = result.stars > previousStars;
    final level = LevelGenerator.byId(result.levelId);

    final baseEmbers = 30 + result.stars * 18 + level.region * 6;
    final embers = (baseEmbers * state.emberMultiplier).round();
    final baseXp = 40 + result.stars * 25 + level.region * 10;
    final xp = (baseXp * state.xpMultiplier).round();

    final previousBest = state.bestMoves[result.levelId];
    final bestMoves = {
      ...state.bestMoves,
      result.levelId: previousBest == null
          ? result.moves
          : (result.moves < previousBest ? result.moves : previousBest),
    };

    // Each level reveals one relic; regions reveal creatures as they progress.
    final relicSprite = Catalog.relics[result.levelId % Catalog.relics.length].sprite;
    final newRelic = state.relicsFound.contains(relicSprite) ? null : relicSprite;
    final creatureSprite =
        Catalog.creatures[(result.levelId ~/ 7) % Catalog.creatures.length].sprite;
    final newCreature =
        state.creaturesFound.contains(creatureSprite) ? null : creatureSprite;

    var next = state.copyWith(
      stars: {
        ...state.stars,
        result.levelId: improved ? result.stars : previousStars,
      },
      bestMoves: bestMoves,
      embers: state.embers + embers,
      xp: state.xp + xp,
      totalMoves: state.totalMoves + result.moves,
      totalWins: state.totalWins + 1,
      playSeconds: state.playSeconds + result.seconds,
      iceMelted: state.iceMelted + result.iceMelted,
      growthBurned: state.growthBurned + result.growthBurned,
      gatesPassed: state.gatesPassed + result.gatesPassed,
      golemSteps: state.golemSteps + result.golemSteps,
      forgesLit: state.forgesLit + result.forgesLit,
      crystalsFound: state.crystalsFound + result.crystals,
      relicsFound: {...state.relicsFound, relicSprite},
      creaturesFound: {...state.creaturesFound, creatureSprite},
    );

    next = _advanceQuests(next, result);

    final unlocked = <AchievementInfo>[];
    for (final achievement in Catalog.achievements) {
      if (next.achievements.contains(achievement.id)) continue;
      if (achievement.progress(next) >= achievement.target) {
        unlocked.add(achievement);
      }
    }
    if (unlocked.isNotEmpty) {
      next = next.copyWith(
        achievements: {...next.achievements, ...unlocked.map((a) => a.id)},
        embers: next.embers + unlocked.fold(0, (sum, a) => sum + a.reward),
      );
    }

    _persist(next);

    return RunRewards(
      embers: embers,
      xp: xp,
      relicSprite: newRelic,
      creatureSprite: newCreature,
      newAchievements: unlocked,
      improvedStars: improved,
    );
  }

  PlayerProfile _advanceQuests(PlayerProfile profile, RunResult result) {
    final quests = DailyQuests.forDay(profile.questDay);
    final progress = [...profile.questProgress];
    for (var i = 0; i < quests.length && i < progress.length; i++) {
      progress[i] += switch (quests[i].metric) {
        QuestMetric.levelsCompleted => 1,
        QuestMetric.starsEarned => result.stars,
        QuestMetric.crystalsCollected => result.crystals,
        QuestMetric.iceMelted => result.iceMelted,
        QuestMetric.growthBurned => result.growthBurned,
        QuestMetric.gatesPassed => result.gatesPassed,
        QuestMetric.golemSteps => result.golemSteps,
        QuestMetric.forgesLit => result.forgesLit,
        QuestMetric.stepsTaken => result.moves,
        QuestMetric.flawlessRuns => result.atPar ? 1 : 0,
      };
    }
    return profile.copyWith(questProgress: progress);
  }

  void resetProgress() {
    _storage.resetProgress();
    state = const PlayerProfile();
    _rollDailyIfNeeded();
    _touchStreak();
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, PlayerProfile>((ref) {
  return ProfileNotifier(ref.watch(storageProvider));
});

/// The level the Continue button should open: the first unlocked level that
/// has not been cleared, falling back to the last one for completionists.
final nextLevelProvider = Provider<int>((ref) {
  final profile = ref.watch(profileProvider);
  const perRegion = LevelGenerator.levelsPerRegion;
  for (var id = 0; id < LevelGenerator.totalLevels; id++) {
    if ((profile.stars[id] ?? 0) > 0) continue;
    if (profile.isLevelUnlocked(id, perRegion)) return id;
  }
  return LevelGenerator.totalLevels - 1;
});

/// Today's quest roster paired with the player's progress on each.
final dailyQuestsProvider = Provider<List<({DailyQuest quest, int progress, bool claimed})>>(
  (ref) {
    final profile = ref.watch(profileProvider);
    final quests = DailyQuests.forDay(
      profile.questDay.isEmpty ? DailyQuests.dayKey() : profile.questDay,
    );
    return [
      for (var i = 0; i < quests.length; i++)
        (
          quest: quests[i],
          progress: i < profile.questProgress.length ? profile.questProgress[i] : 0,
          claimed: i < profile.questClaimed.length && profile.questClaimed[i],
        ),
    ];
  },
);
