/// Paths to every sprite sliced out of the source sheets.
///
/// The slicer writes `<category>/<category>_NN.png` in reading order, so the
/// helpers below just rebuild those names. Indices are 1-based to match the
/// numbered contact sheets used while authoring.
abstract final class Sprites {
  static const _root = 'assets/app/sprites';

  static String _path(String group, int index) =>
      '$_root/$group/${group}_${index.toString().padLeft(2, '0')}.png';

  static const characterCount = 10;
  static const trailCount = 30;
  static const groundCount = 10;
  static const obstacleCount = 14;
  static const frozenCount = 18;
  static const crystalCount = 10;
  static const mechanismCount = 18;
  static const relicCount = 25;
  static const creatureCount = 15;
  static const natureCount = 23;
  static const treeCount = 8;
  static const bridgeCount = 30;
  static const effectCount = 17;
  static const lavaCount = 12;
  static const runeCount = 34;

  static String character(int i) => _path('character', _wrap(i, characterCount));
  static String trail(int i) => _path('trail', _wrap(i, trailCount));
  static String ground(int i) => _path('ground', _wrap(i, groundCount));
  static String obstacle(int i) => _path('obstacle', _wrap(i, obstacleCount));
  static String frozen(int i) => _path('frozen', _wrap(i, frozenCount));
  static String crystal(int i) => _path('crystal', _wrap(i, crystalCount));
  static String mechanism(int i) => _path('mechanism', _wrap(i, mechanismCount));
  static String relic(int i) => _path('relic', _wrap(i, relicCount));
  static String creature(int i) => _path('creature', _wrap(i, creatureCount));
  static String nature(int i) => _path('nature', _wrap(i, natureCount));
  static String tree(int i) => _path('tree', _wrap(i, treeCount));
  static String bridge(int i) => _path('bridge', _wrap(i, bridgeCount));
  static String effect(int i) => _path('effect', _wrap(i, effectCount));
  static String lava(int i) => _path('lava', _wrap(i, lavaCount));
  static String rune(int i) => _path('rune', _wrap(i, runeCount));

  static int _wrap(int i, int count) => ((i - 1) % count + count) % count + 1;

  // Single-image art.
  static const logo = 'assets/app/ui/logo.webp';
  static const loadingPortrait = 'assets/app/ui/loading_portrait.webp';
  static const loadingLandscape = 'assets/app/ui/loading_landscape.webp';
  static const icon = 'assets/app/icon/icon.png';

  static String background(int region) =>
      'assets/app/bg/location_${_wrap(region, 8)}.webp';

  /// Straight trail pieces, coolest to hottest, used by the codex and HUD.
  ///
  /// Row 1 of the trail sheet is a single shape rendered at six temperatures;
  /// these four columns line up with the game's four cooling stages.
  static const trailStageStraight = [1, 2, 4, 5];
  static const trailStageCurve = [7, 8, 10, 11];
  static const trailStageCap = [19, 20, 22, 23];
}
