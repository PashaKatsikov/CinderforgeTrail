import 'dart:io';
import 'dart:ui' as ui;

import 'package:trailgame/core/design/app_theme.dart';
import 'package:trailgame/core/services/audio_service.dart';
import 'package:trailgame/core/services/storage_service.dart';
import 'package:trailgame/data/models/profile.dart';
import 'package:trailgame/features/about/about_screen.dart';
import 'package:trailgame/features/achievements/achievements_screen.dart';
import 'package:trailgame/features/characters/characters_screen.dart';
import 'package:trailgame/features/codex/codex_screen.dart';
import 'package:trailgame/features/collection/bestiary_screen.dart';
import 'package:trailgame/features/collection/relics_screen.dart';
import 'package:trailgame/features/forge/forge_screen.dart';
import 'package:trailgame/features/home/home_screen.dart';
import 'package:trailgame/features/levels/level_select_screen.dart';
import 'package:trailgame/features/onboarding/how_to_play_screen.dart';
import 'package:trailgame/features/profile/profile_screen.dart';
import 'package:trailgame/features/quests/quests_screen.dart';
import 'package:trailgame/features/records/records_screen.dart';
import 'package:trailgame/features/regions/regions_screen.dart';
import 'package:trailgame/features/settings/settings_screen.dart';
import 'package:trailgame/features/statistics/statistics_screen.dart';
import 'package:trailgame/features/weather/weather_screen.dart';
import 'package:trailgame/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Renders every menu screen at phone size and writes a PNG for each.
///
/// The point is not pixel comparison but catching layout overflows, missing
/// assets and null crashes across the whole app in one run. Screenshots land in
/// `build/screens/` for eyeballing.
void main() {
  const size = Size(390, 844);
  final outputDir = Directory('build/screens');

  late StorageService storage;
  late AudioService audio;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
    outputDir.createSync(recursive: true);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    storage = await StorageService.open();
    audio = AudioService()..enabled = false;
    await storage.saveProfile(_seededProfile);
  });

  Future<void> render(
    WidgetTester tester,
    String name,
    Widget screen, {
    Duration settle = const Duration(milliseconds: 900),
  }) async {
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageProvider.overrideWithValue(storage),
          audioProvider.overrideWithValue(audio),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(),
          home: RepaintBoundary(key: const ValueKey('shot'), child: screen),
        ),
      ),
    );

    // Entrance animations are staggered; pump past all of them so the capture
    // shows the settled screen rather than a half-faded one.
    await tester.pump();
    for (var i = 0; i < 12; i++) {
      await tester.pump(settle ~/ 12);
    }

    await _capture(tester, '${outputDir.path}/$name.png');
    expect(tester.takeException(), isNull, reason: '$name threw while building');
  }

  testWidgets('home', (t) => render(t, '01_home', const HomeScreen()));
  testWidgets('regions', (t) => render(t, '02_regions', const RegionsScreen()));
  testWidgets(
    'levels',
    (t) => render(t, '03_levels', const LevelSelectScreen(region: 1)),
  );
  testWidgets('quests', (t) => render(t, '04_quests', const QuestsScreen()));
  testWidgets('forge', (t) => render(t, '05_forge', const ForgeScreen()));
  testWidgets(
    'achievements',
    (t) => render(t, '06_achievements', const AchievementsScreen()),
  );
  testWidgets(
    'statistics',
    (t) => render(t, '07_statistics', const StatisticsScreen()),
  );
  testWidgets('relics', (t) => render(t, '08_relics', const RelicsScreen()));
  testWidgets(
    'bestiary',
    (t) => render(t, '09_bestiary', const BestiaryScreen()),
  );
  testWidgets(
    'characters',
    (t) => render(t, '10_characters', const CharactersScreen()),
  );
  testWidgets('codex', (t) => render(t, '11_codex', const CodexScreen()));
  testWidgets('profile', (t) => render(t, '12_profile', const ProfileScreen()));
  testWidgets('records', (t) => render(t, '13_records', const RecordsScreen()));
  testWidgets('weather', (t) => render(t, '14_weather', const WeatherScreen()));
  testWidgets(
    'settings',
    (t) => render(t, '15_settings', const SettingsScreen()),
  );
  testWidgets('about', (t) => render(t, '16_about', const AboutScreen()));
  testWidgets(
    'how to play',
    (t) => render(t, '17_how_to_play', const HowToPlayScreen()),
  );
}

/// A profile with enough progress that collection screens are not all empty.
final _seededProfile = PlayerProfile(
  stars: {for (var i = 0; i < 18; i++) i: (i % 3) + 1},
  bestMoves: {for (var i = 0; i < 18; i++) i: 14 + i % 5},
  embers: 640,
  xp: 2400,
  relicsFound: const {1, 2, 3, 5, 8, 13},
  creaturesFound: const {1, 2, 3},
  achievements: const {'first_steps', 'ten_levels', 'stars_50'},
  totalRuns: 32,
  totalWins: 18,
  totalMoves: 540,
  crystalsFound: 46,
  iceMelted: 31,
  growthBurned: 22,
  gatesPassed: 17,
  golemSteps: 9,
  forgesLit: 6,
  playSeconds: 5400,
  streakDays: 4,
  upgrades: const {'emberheart': 2, 'prospector': 1},
);

Future<void> _capture(WidgetTester tester, String path) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('shot')),
  );
  final image = await boundary.toImage(pixelRatio: 2);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
  image.dispose();
}

Future<void> _loadFonts() async {
  const families = {
    'Cinzel': [
      'assets/app/fonts/Cinzel-Regular.ttf',
      'assets/app/fonts/Cinzel-SemiBold.ttf',
      'assets/app/fonts/Cinzel-Bold.ttf',
      'assets/app/fonts/Cinzel-Black.ttf',
    ],
    'Manrope': [
      'assets/app/fonts/Manrope-Regular.ttf',
      'assets/app/fonts/Manrope-Medium.ttf',
      'assets/app/fonts/Manrope-SemiBold.ttf',
      'assets/app/fonts/Manrope-Bold.ttf',
      'assets/app/fonts/Manrope-ExtraBold.ttf',
    ],
  };
  for (final entry in families.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      loader.addFont(
        rootBundle.load(path).then((d) => ByteData.sublistView(d.buffer.asUint8List())),
      );
    }
    await loader.load();
  }
}
