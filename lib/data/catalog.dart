import 'package:flutter/material.dart';

import '../core/design/palette.dart';
import 'models/profile.dart';

/// One of the eight volcanic regions the campaign is split across.
@immutable
class RegionInfo {
  const RegionInfo({
    required this.index,
    required this.name,
    required this.tagline,
    required this.lore,
    required this.teaches,
    required this.accent,
  });

  final int index;
  final String name;
  final String tagline;
  final String lore;

  /// The one mechanic this region introduces.
  final String teaches;
  final Color accent;
}

@immutable
class RelicInfo {
  const RelicInfo(this.sprite, this.name, this.rarity, this.lore);
  final int sprite;
  final String name;
  final String rarity;
  final String lore;
}

@immutable
class CreatureInfo {
  const CreatureInfo(this.sprite, this.name, this.habitat, this.behaviour);
  final int sprite;
  final String name;
  final String habitat;
  final String behaviour;
}

@immutable
class WeatherInfo {
  const WeatherInfo(this.effectSprite, this.name, this.effect, this.detail);
  final int effectSprite;
  final String name;
  final String effect;
  final String detail;
}

@immutable
class CharacterInfo {
  const CharacterInfo(
    this.sprite,
    this.name,
    this.title,
    this.unlockAt,
    this.lore,
  );
  final int sprite;
  final String name;
  final String title;

  /// Levels that must be completed before this suit becomes wearable.
  final int unlockAt;
  final String lore;
}

@immutable
class AchievementInfo {
  const AchievementInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.target,
    required this.progress,
    required this.reward,
    required this.icon,
  });

  final String id;
  final String name;
  final String description;
  final int target;

  /// Reads the current value out of a profile.
  final int Function(PlayerProfile) progress;
  final int reward;
  final IconData icon;
}

abstract final class Catalog {
  static const regions = <RegionInfo>[
    RegionInfo(
      index: 1,
      name: 'Emberfall Basin',
      tagline: 'Where the first sparks fell',
      lore:
          'A shallow bowl of cooling lava, warm enough to walk and calm enough '
          'to learn. The basin remembers every step taken across it.',
      teaches: 'Frozen formations melt beside magma',
      accent: Palette.ember,
    ),
    RegionInfo(
      index: 2,
      name: 'Obsidian Flats',
      tagline: 'Glass fields under a red sky',
      lore:
          'Endless plates of volcanic glass, smooth as still water. Cinder '
          'growth clings to the seams and only fire keeps it back.',
      teaches: 'Cinder growth burns beside embers',
      accent: Palette.cinder,
    ),
    RegionInfo(
      index: 3,
      name: 'Ashen Wastes',
      tagline: 'A grey wind that eats the road',
      lore:
          'Ash swallows heat faster than anywhere else. Old machines still '
          'stand here, waiting for a current to run through them.',
      teaches: 'Magnetic gates open beside molten metal',
      accent: Palette.metal,
    ),
    RegionInfo(
      index: 4,
      name: 'Basalt Plateau',
      tagline: 'Columns older than memory',
      lore:
          'High stone terraces where the trail cools quickly. Something heavy '
          'rises from the cold glass when the last warmth leaves it.',
      teaches: 'Golem steps rise beside cold obsidian',
      accent: Palette.obsidian,
    ),
    RegionInfo(
      index: 5,
      name: 'Crystal Hollows',
      tagline: 'Light trapped in stone',
      lore:
          'Caverns lined with singing crystal. The first ancient forges appear '
          'here, sealed behind runes that only fire can break.',
      teaches: 'Ancient forges unseal rune gates',
      accent: Palette.ice,
    ),
    RegionInfo(
      index: 6,
      name: 'Volcanic Canyons',
      tagline: 'Narrow paths, long falls',
      lore:
          'Rivers of fire cut the ground into ribbons. Metal ore veins run '
          'through the walls and keep a trail burning far longer.',
      teaches: 'Ore superheats, ash devours',
      accent: Palette.magma,
    ),
    RegionInfo(
      index: 7,
      name: 'The Ancient Forge',
      tagline: 'The heart that shaped the world',
      lore:
          'A cathedral of machinery buried in the mountain. Every mechanism '
          'known to the trail is here, and all of them are watching.',
      teaches: 'Every mechanism, all at once',
      accent: Palette.gold,
    ),
    RegionInfo(
      index: 8,
      name: 'Frozen Crater',
      tagline: 'Where the fire finally lost',
      lore:
          'The summit caldera, choked with ice. Only the most precise route '
          'keeps enough heat alive to reach the far rim.',
      teaches: 'Precision under total cold',
      accent: Palette.arcane,
    ),
  ];

  static RegionInfo region(int index) =>
      regions[(index - 1).clamp(0, regions.length - 1)];

  static const relics = <RelicInfo>[
    RelicInfo(1, 'Heart of Magma', 'Legendary',
        'Still beating after ten thousand years beneath the crust.'),
    RelicInfo(2, 'Obsidian Shard', 'Common',
        'A splinter of cooled trail, sharp enough to cut light.'),
    RelicInfo(3, 'Heat Crystal', 'Rare',
        'Holds a full stage of warmth in a single closed hand.'),
    RelicInfo(4, 'Runic Stone', 'Rare',
        'The mark on its face changes when nobody is looking.'),
    RelicInfo(5, 'Fire Core', 'Epic',
        'Forge-smiths used these as the seed of a new mountain.'),
    RelicInfo(6, 'Ancient Seal', 'Epic',
        'Closed a door that has not been found again.'),
    RelicInfo(7, 'Living Coal', 'Legendary',
        'Refuses to cool. Refuses, in fact, most things.'),
    RelicInfo(8, 'Volcanic Catalyst', 'Rare',
        'Doubles a reaction it does not take part in.'),
    RelicInfo(9, 'Cinder Sigil', 'Common', 'Burnt into stone by a passing step.'),
    RelicInfo(10, 'Emberglass Lens', 'Rare',
        'Shows the heat of a trail laid a century ago.'),
    RelicInfo(11, 'Slagbound Charm', 'Common',
        'Cheap, ugly, and worn by every surviving traveller.'),
    RelicInfo(12, 'Forgewright Tablet', 'Epic',
        'Instructions for a machine nobody has managed to build.'),
    RelicInfo(13, 'Pyre Spindle', 'Rare',
        'Spins slowly whenever a forge is lit nearby.'),
    RelicInfo(14, 'Molten Crown', 'Legendary',
        'Worn once, by someone who did not survive the coronation.'),
    RelicInfo(15, 'Ashen Compass', 'Rare',
        'Points to the coldest place within a day of walking.'),
    RelicInfo(16, 'Basalt Key', 'Common',
        'Fits every rune gate badly and none of them well.'),
    RelicInfo(17, 'Ember Ovum', 'Epic', 'Something inside is still moving.'),
    RelicInfo(18, 'Glasswrought Eye', 'Rare',
        'Blinks when a trail behind you reaches obsidian.'),
    RelicInfo(19, 'Scoria Bead', 'Common',
        'One of a set. The rest are somewhere under the plateau.'),
    RelicInfo(20, 'Furnace Seed', 'Epic',
        'Plant it in warm ground and step well back.'),
    RelicInfo(21, 'Caldera Tear', 'Legendary',
        'The mountain wept exactly once. This is all that is left.'),
    RelicInfo(22, 'Smoulder Knot', 'Common',
        'Rope woven from cooled trail fibre. Surprisingly strong.'),
    RelicInfo(23, 'Vent Whistle', 'Rare',
        'Sounds a note only the lava insects answer.'),
    RelicInfo(24, 'Pumice Idol', 'Common',
        'Floats. Nobody knows why anyone carved it.'),
    RelicInfo(25, 'Cinderforge Mark', 'Legendary',
        'Proof that you walked the whole trail and came back.'),
  ];

  static const creatures = <CreatureInfo>[
    CreatureInfo(1, 'Lava Tick', 'Emberfall Basin',
        'Trails warm coals and occasionally uncovers a hidden seam.'),
    CreatureInfo(2, 'Cinder Moth', 'Obsidian Flats',
        'Drawn to the exact moment a trail turns from magma to ember.'),
    CreatureInfo(3, 'Flame Wisp', 'Ashen Wastes',
        'Avoids the hottest ground and patrols cooled routes instead.'),
    CreatureInfo(4, 'Basalt Golem', 'Basalt Plateau',
        'Rises only on fully cooled obsidian, then stands as a platform.'),
    CreatureInfo(5, 'Magma Crawler', 'Volcanic Canyons',
        'Eight legs, no interest in anything below molten metal.'),
    CreatureInfo(6, 'Ashback Beetle', 'Ashen Wastes',
        'Its shell is old cooled trail, shed and regrown each season.'),
    CreatureInfo(7, 'Emberling Newt', 'Emberfall Basin',
        'Sleeps in warm cracks and wakes when a route runs past.'),
    CreatureInfo(8, 'Slag Slime', 'Obsidian Flats',
        'Reheats whatever it sits on, which is rarely convenient.'),
    CreatureInfo(9, 'Smoke Spirit', 'Crystal Hollows',
        'Appears where a trail died and remembers where it went.'),
    CreatureInfo(10, 'Crag Salamander', 'Basalt Plateau',
        'Basks on ore veins and refuses to move for anyone.'),
    CreatureInfo(11, 'Pyre Hound', 'The Ancient Forge',
        'Guards lit forges. Loses interest the moment they cool.'),
    CreatureInfo(12, 'Cinder Boar', 'Volcanic Canyons',
        'Charges across ash fields, scattering routes behind it.'),
    CreatureInfo(13, 'Ember Toad', 'Crystal Hollows',
        'Swallows crystals whole and glows for a week afterwards.'),
    CreatureInfo(14, 'Molten Ram', 'The Ancient Forge',
        'Headbutts rune gates. Has never once succeeded.'),
    CreatureInfo(15, 'Caldera Titan', 'Frozen Crater',
        'The last thing still warm at the summit.'),
  ];

  static const weather = <WeatherInfo>[
    WeatherInfo(8, 'Ash Rain', 'Cools trails faster',
        'Fine grey fall that pulls heat out of everything it lands on.'),
    WeatherInfo(6, 'Lava Rain', 'Reheats existing trails',
        'Bright droplets that give a dying route one more stage of life.'),
    WeatherInfo(10, 'Fire Wind', 'Carries heat sideways',
        'Warmth bleeds from one trail into the ground beside it.'),
    WeatherInfo(3, 'Eruption', 'Rewrites part of the map',
        'New flows open, old paths vanish, rare ground is exposed.'),
    WeatherInfo(11, 'Smoke Veil', 'Hides distant ground',
        'Only the tiles near your route stay readable.'),
    WeatherInfo(17, 'Emberstorm', 'Everything burns longer',
        'The rarest weather on the trail, and the most generous.'),
  ];

  static const characters = <CharacterInfo>[
    CharacterInfo(1, 'Kade', 'Trailwalker', 0,
        'Walked out of the basin on the first warm day and never went home.'),
    CharacterInfo(2, 'Vorn', 'Emberplate', 4,
        'Wears forge plate salvaged from a machine that is still angry.'),
    CharacterInfo(3, 'Sable', 'Nightforge', 10,
        'Works only after dark, when the trail glow is easiest to read.'),
    CharacterInfo(4, 'Pyra', 'Sunmantle', 18,
        'Claims the mountain speaks. Nobody has proved her wrong yet.'),
    CharacterInfo(5, 'Grimm', 'Ashwarden', 26,
        'Kept the ash roads open for thirty seasons, alone.'),
    CharacterInfo(6, 'Frost', 'Glacierborn', 36,
        'Born in the crater ice and drawn downhill toward the heat.'),
    CharacterInfo(7, 'Aurel', 'Goldsmith', 48,
        'Melts relics down, studies the slag, then regrets it.'),
    CharacterInfo(8, 'Dun', 'Ironpilgrim', 60,
        'Has crossed every region twice and speaks about none of it.'),
    CharacterInfo(9, 'Rhys', 'Magmaheart', 74,
        'Survived a full eruption by standing perfectly still.'),
    CharacterInfo(10, 'Kyrn', 'Deepglass', 88,
        'Came up from below. Nobody asks what is down there.'),
  ];

  static final achievements = <AchievementInfo>[
    AchievementInfo(
      id: 'first_steps',
      name: 'First Steps',
      description: 'Complete your first level.',
      target: 1,
      progress: (p) => p.levelsCompleted,
      reward: 40,
      icon: Icons.flag_rounded,
    ),
    AchievementInfo(
      id: 'ten_levels',
      name: 'Getting Warm',
      description: 'Complete 10 levels.',
      target: 10,
      progress: (p) => p.levelsCompleted,
      reward: 80,
      icon: Icons.local_fire_department_rounded,
    ),
    AchievementInfo(
      id: 'forty_levels',
      name: 'Seasoned Walker',
      description: 'Complete 40 levels.',
      target: 40,
      progress: (p) => p.levelsCompleted,
      reward: 200,
      icon: Icons.hiking_rounded,
    ),
    AchievementInfo(
      id: 'all_levels',
      name: 'Trail Complete',
      description: 'Complete all 96 levels.',
      target: 96,
      progress: (p) => p.levelsCompleted,
      reward: 900,
      icon: Icons.emoji_events_rounded,
    ),
    AchievementInfo(
      id: 'stars_50',
      name: 'Constellation',
      description: 'Earn 50 stars.',
      target: 50,
      progress: (p) => p.totalStars,
      reward: 120,
      icon: Icons.star_rounded,
    ),
    AchievementInfo(
      id: 'stars_150',
      name: 'Skyful',
      description: 'Earn 150 stars.',
      target: 150,
      progress: (p) => p.totalStars,
      reward: 300,
      icon: Icons.auto_awesome_rounded,
    ),
    AchievementInfo(
      id: 'stars_all',
      name: 'Perfect Route',
      description: 'Earn all 288 stars.',
      target: 288,
      progress: (p) => p.totalStars,
      reward: 1200,
      icon: Icons.workspace_premium_rounded,
    ),
    AchievementInfo(
      id: 'ice_25',
      name: 'Thaw',
      description: 'Melt 25 frozen formations.',
      target: 25,
      progress: (p) => p.iceMelted,
      reward: 90,
      icon: Icons.ac_unit_rounded,
    ),
    AchievementInfo(
      id: 'ice_150',
      name: 'Meltwater',
      description: 'Melt 150 frozen formations.',
      target: 150,
      progress: (p) => p.iceMelted,
      reward: 260,
      icon: Icons.water_drop_rounded,
    ),
    AchievementInfo(
      id: 'growth_60',
      name: 'Clearance',
      description: 'Burn away 60 cinder growths.',
      target: 60,
      progress: (p) => p.growthBurned,
      reward: 140,
      icon: Icons.grass_rounded,
    ),
    AchievementInfo(
      id: 'gates_40',
      name: 'Conductor',
      description: 'Pass 40 magnetic gates.',
      target: 40,
      progress: (p) => p.gatesPassed,
      reward: 140,
      icon: Icons.bolt_rounded,
    ),
    AchievementInfo(
      id: 'golem_30',
      name: 'Stone Company',
      description: 'Cross 30 golem steps.',
      target: 30,
      progress: (p) => p.golemSteps,
      reward: 140,
      icon: Icons.view_in_ar_rounded,
    ),
    AchievementInfo(
      id: 'forges_25',
      name: 'Firekeeper',
      description: 'Light 25 ancient forges.',
      target: 25,
      progress: (p) => p.forgesLit,
      reward: 180,
      icon: Icons.whatshot_rounded,
    ),
    AchievementInfo(
      id: 'relics_10',
      name: 'Collector',
      description: 'Discover 10 relics.',
      target: 10,
      progress: (p) => p.relicsFound.length,
      reward: 150,
      icon: Icons.diamond_rounded,
    ),
    AchievementInfo(
      id: 'relics_all',
      name: 'Curator',
      description: 'Discover all 25 relics.',
      target: 25,
      progress: (p) => p.relicsFound.length,
      reward: 500,
      icon: Icons.inventory_2_rounded,
    ),
    AchievementInfo(
      id: 'creatures_all',
      name: 'Naturalist',
      description: 'Record all 15 creatures.',
      target: 15,
      progress: (p) => p.creaturesFound.length,
      reward: 400,
      icon: Icons.pets_rounded,
    ),
    AchievementInfo(
      id: 'crystals_100',
      name: 'Prospector',
      description: 'Collect 100 crystals.',
      target: 100,
      progress: (p) => p.crystalsFound,
      reward: 200,
      icon: Icons.hexagon_rounded,
    ),
    AchievementInfo(
      id: 'moves_2000',
      name: 'Long Walk',
      description: 'Take 2,000 steps in total.',
      target: 2000,
      progress: (p) => p.totalMoves,
      reward: 160,
      icon: Icons.directions_walk_rounded,
    ),
    AchievementInfo(
      id: 'rank_5',
      name: 'Journeyman',
      description: 'Reach rank 5.',
      target: 5,
      progress: (p) => p.rank,
      reward: 200,
      icon: Icons.military_tech_rounded,
    ),
    AchievementInfo(
      id: 'rank_12',
      name: 'Forge Master',
      description: 'Reach rank 12.',
      target: 12,
      progress: (p) => p.rank,
      reward: 600,
      icon: Icons.shield_moon_rounded,
    ),
    AchievementInfo(
      id: 'streak_7',
      name: 'Steady Flame',
      description: 'Play 7 days in a row.',
      target: 7,
      progress: (p) => p.streakDays,
      reward: 250,
      icon: Icons.calendar_month_rounded,
    ),
    AchievementInfo(
      id: 'no_hints_20',
      name: 'Self Taught',
      description: 'Complete 20 levels with 5 or fewer hints used overall.',
      target: 20,
      progress: (p) => p.hintsUsed <= 5 ? p.levelsCompleted : 0,
      reward: 320,
      icon: Icons.psychology_rounded,
    ),
    AchievementInfo(
      id: 'region_4',
      name: 'Highlander',
      description: 'Clear every level in the Basalt Plateau.',
      target: 12,
      progress: (p) => p.completedInRegion(4, 12),
      reward: 300,
      icon: Icons.terrain_rounded,
    ),
    AchievementInfo(
      id: 'region_8',
      name: 'Summit',
      description: 'Clear every level in the Frozen Crater.',
      target: 12,
      progress: (p) => p.completedInRegion(8, 12),
      reward: 700,
      icon: Icons.landscape_rounded,
    ),
  ];
}
