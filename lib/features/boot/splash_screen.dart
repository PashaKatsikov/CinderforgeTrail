import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/palette.dart';
import '../../core/design/typography.dart';
import '../../core/router/routes.dart';
import '../../data/sprites.dart';
import '../../game/logic/level_generator.dart';
import '../../game/render/board_art.dart';
import '../../game/render/sprite_cache.dart';
import '../../state/app_state.dart';
import 'loading_bar.dart';

/// Boot screen shown while the game warms up.
///
/// The bar starts empty and advances one checkpoint per real start-up task, so
/// the percentage always reflects work that actually finished. A hard deadline
/// guarantees the screen never stalls: whatever is still pending is finished
/// lazily and the bar always closes on a full 100%.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _deadline = Duration(seconds: 8);
  static const _minimumVisible = Duration(milliseconds: 2400);

  /// Checkpoints reached after each start-up task. The last one stops short of
  /// full so the final jump to 100% only ever happens on the way out.
  static const _checkpoints = [0.14, 0.31, 0.48, 0.64, 0.79, 0.91];

  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  bool _outOfTime = false;
  bool _leaving = false;
  Timer? _deadlineTimer;
  late final DateTime _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    // The splash itself may be shown either way up; the game locks to
    // portrait once boot finishes.
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _deadlineTimer = Timer(_deadline, () => _outOfTime = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  @override
  void dispose() {
    _deadlineTimer?.cancel();
    _progress.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    final tasks = <Future<void> Function()>[
      _warmAudio,
      _precacheSplashArt,
      _buildCampaign,
      _precacheRegionArt,
      _decodeCoreSprites,
      _decodeFirstLevelSprites,
    ];

    for (var i = 0; i < tasks.length; i++) {
      if (!mounted) return;
      if (!_outOfTime) {
        try {
          await tasks[i]();
        } catch (error) {
          debugPrint('Start-up task $i failed: $error');
        }
      }
      if (!mounted) return;
      await _animateTo(_checkpoints[i], const Duration(milliseconds: 460));
    }

    // Hold the splash briefly so a fast device does not flash past it.
    final elapsed = DateTime.now().difference(_startedAt);
    if (elapsed < _minimumVisible) {
      await Future<void>.delayed(_minimumVisible - elapsed);
    }
    if (!mounted) return;

    await _animateTo(1, const Duration(milliseconds: 540));
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    _leave();
  }

  Future<void> _animateTo(double target, Duration duration) async {
    if (!mounted) return;
    try {
      await _progress.animateTo(
        target,
        duration: duration,
        curve: Curves.easeOutCubic,
      );
    } on TickerCanceled {
      // The screen went away mid-animation; nothing else to do.
    }
  }

  void _leave() {
    if (_leaving) return;
    _leaving = true;
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    final storage = ref.read(storageProvider);
    context.go(storage.hasOnboarded ? Routes.home : Routes.onboarding);
  }

  // --------------------------------------------------------- boot tasks

  Future<void> _warmAudio() => ref.read(audioProvider).warmUp();

  Future<void> _precacheSplashArt() async {
    await Future.wait([
      precacheImage(const AssetImage(Sprites.loadingPortrait), context),
      precacheImage(const AssetImage(Sprites.loadingLandscape), context),
      precacheImage(const AssetImage(Sprites.logo), context),
    ]);
  }

  Future<void> _buildCampaign() async {
    ref.read(campaignProvider);
    await Future<void>.delayed(const Duration(milliseconds: 60));
  }

  Future<void> _precacheRegionArt() async {
    if (!mounted) return;
    await Future.wait([
      for (var region = 1; region <= LevelGenerator.regionCount; region++)
        precacheImage(AssetImage(Sprites.background(region)), context),
    ]);
  }

  Future<void> _decodeCoreSprites() async {
    await SpriteCache.instance.load([
      for (var i = 1; i <= Sprites.characterCount; i++) Sprites.character(i),
      for (var i = 1; i <= Sprites.groundCount; i++) Sprites.ground(i),
    ]);
  }

  Future<void> _decodeFirstLevelSprites() async {
    final profile = ref.read(profileProvider);
    final level = LevelGenerator.byId(0);
    await SpriteCache.instance.load(
      BoardArt.assetsFor(level, profile.selectedCharacter),
    );
  }

  // ------------------------------------------------------------- layout

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.base,
      body: OrientationBuilder(
        builder: (context, orientation) {
          final portrait = orientation == Orientation.portrait;
          final size = MediaQuery.sizeOf(context);

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                portrait
                    ? Sprites.loadingPortrait
                    : Sprites.loadingLandscape,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: Palette.base),
              ),
              // Darken the foot of the artwork so the bar stays readable.
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC07060A)],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: portrait ? size.height * 0.085 : size.height * 0.07,
                  ),
                  child: _ProgressBlock(
                    progress: _progress,
                    // Landscape gets a noticeably shorter bar so it does not
                    // stretch across the whole width of the artwork.
                    barWidth: portrait
                        ? size.width * 0.72
                        : size.width * 0.36,
                    barHeight: portrait ? 14 : 10,
                    fontSize: portrait ? 15 : 12.5,
                    percentSize: portrait ? 26 : 20,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Wordmark above, bar in the middle, percentage below — always centred.
class _ProgressBlock extends StatelessWidget {
  const _ProgressBlock({
    required this.progress,
    required this.barWidth,
    required this.barHeight,
    required this.fontSize,
    required this.percentSize,
  });

  final Animation<double> progress;
  final double barWidth;
  final double barHeight;
  final double fontSize;
  final double percentSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        LoadingWordmark(fontSize: fontSize),
        SizedBox(height: barHeight),
        AnimatedBuilder(
          animation: progress,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ForgeProgressBar(
                value: progress.value,
                width: barWidth,
                height: barHeight,
              ),
              SizedBox(height: barHeight * 0.85),
              Text(
                '${(progress.value * 100).round()}%',
                style: AppText.numeral.copyWith(
                  fontSize: percentSize,
                  color: Palette.gold,
                  shadows: const [
                    Shadow(color: Color(0xCC000000), blurRadius: 10),
                    Shadow(color: Color(0x88FF6B2C), blurRadius: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
