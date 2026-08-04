import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/palette.dart';
import '../../core/design/typography.dart';
import '../../core/router/routes.dart';
import '../../data/sprites.dart';
import '../../emberlink/core/ember_config.dart';
import '../../emberlink/ember_gate.dart';
import '../../emberlink/infra/reach_probe.dart';
import '../../emberlink/models/trail_destination.dart';
import '../../emberlink/pages/portal_view.dart';
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

  /// Gray-flow bar shape: rise to the dwell stop, hold ~2s so a slow backend
  /// reads as "working" (not frozen), rise again, then park near full until
  /// the routing decision resolves. The jump to 100% happens on the way out.
  static const double _grayDwellStop = 0.63;
  static const double _grayParkStop = 0.95;
  static const Duration _grayDwell = Duration(seconds: 2);

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
    // Organic-only builds (no gray creds) keep the original behaviour.
    if (!EmberConfig.grayReady) {
      await _runGameBoot(animate: true);
      _leaveGame();
      return;
    }

    // Gray flow: run the routing decision while the loading bar advances.
    final services = ref.read(emberServicesProvider);
    final decision = services.coordinator.decide();

    // Cut the paced bar short the instant we know we're offline so nowifi shows
    // at once instead of parking at 95% for the probe timeout.
    final offlineCut = Completer<void>();
    void cutOffline() {
      if (!offlineCut.isCompleted) offlineCut.complete();
    }

    // (a) The routing decision itself resolved to offline (isOffline() true, or
    //     the canReach() probe failed).
    TrailDestination? decided;
    unawaited(
      decision.then((d) {
        decided = d;
        if (d is OfflineTrail) cutOffline();
      }).catchError((_) {}),
    );

    // (b) The OS reports every interface down. checkConnectivity() can read
    //     stale for a beat at cold start (returns wifi while the interface is
    //     actually gone), so this stream is what makes a truly offline launch
    //     surface nowifi promptly. A SUSTAINED all-down is required — a brief
    //     `none` blip while Wi-Fi re-associates on Retry is ignored, which is
    //     what used to bounce a recovered launch straight back to nowifi.
    Timer? downTimer;
    final connSub = const ReachProbe().changes.listen((states) {
      if (ReachProbe.allDown(states)) {
        downTimer ??= Timer(const Duration(milliseconds: 650), cutOffline);
      } else {
        downTimer?.cancel();
        downTimer = null;
      }
    });
    void stopWatching() {
      downTimer?.cancel();
      unawaited(connSub.cancel());
    }

    // Runs one paced step (an animation or the dwell) but returns early the
    // moment the offline cut fires. Returns true when it was cut short.
    Future<bool> pace(Future<void> Function() step) async {
      await Future.any<void>([step(), offlineCut.future]);
      return offlineCut.isCompleted;
    }

    var cut = await pace(
      () => _animateTo(_grayDwellStop, const Duration(milliseconds: 1050)),
    );
    if (!mounted) {
      stopWatching();
      return;
    }
    if (!cut) cut = await pace(() => Future<void>.delayed(_grayDwell));
    if (!cut) {
      cut = await pace(
        () => _animateTo(_grayParkStop, const Duration(milliseconds: 1050)),
      );
    }
    if (!cut) {
      // Parked at 95% — wait for the decision (or a late offline cut).
      await Future.any<void>([
        decision.then((_) {}).catchError((_) {}),
        offlineCut.future,
      ]);
    }
    stopWatching();
    if (!mounted) return;

    // _route handles every outcome, including nowifi (its own warm-art +
    // minimum-visible floor). `decided` is null only when a sustained all-down
    // cut the bar before the (still-running) decision produced anything — that
    // is an outage, so route offline without waiting for the probe timeout.
    await _route(decided ?? const OfflineTrail());
  }

  Future<void> _route(TrailDestination destination) async {
    switch (destination) {
      case PortalTrail(:final url, :final coldStart):
        await _animateTo(1, const Duration(milliseconds: 420));
        if (!mounted) return;
        context.go(Routes.portal, extra: PortalArgs(url, coldStart: coldStart));
      case InviteThenPortalTrail(:final url):
        if (!mounted) return;
        context.go(Routes.notify, extra: url);
      case OfflineTrail():
        // Warm the artwork first so the hand-over does not paint a black frame
        // (lessons §25), then a short floor so the splash is actually seen.
        if (!mounted) return;
        await _warmOfflineArt();
        final elapsed = DateTime.now().difference(_startedAt);
        const floor = Duration(milliseconds: EmberConfig.offlineFloorMs);
        if (elapsed < floor) {
          await Future<void>.delayed(floor - elapsed);
        }
        if (!mounted) return;
        context.go(Routes.offline);
      case NativeTrail():
        // Organic / reviewer path: warm the game, then hand over. The bar is
        // already near full, so run tasks silently and only close on 100%.
        await _runGameBoot(animate: false);
        _leaveGame();
    }
  }

  Future<void> _warmOfflineArt() async {
    const dir = 'assets/Cinderforge_Trail_additional_assets';
    try {
      await Future.wait([
        precacheImage(const AssetImage('$dir/Vertical_Nowifi_Screen.webp'), context),
        precacheImage(const AssetImage('$dir/Horizontal_Nowifi_Screen.webp'), context),
      ]);
    } catch (_) {/* a decode failure must not block the hand-over */}
  }

  Future<void> _runGameBoot({required bool animate}) async {
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
          assert(() {
            debugPrint('Start-up task $i failed: $error');
            return true;
          }());
        }
      }
      if (!mounted) return;
      if (animate) {
        await _animateTo(_checkpoints[i], const Duration(milliseconds: 460));
      }
    }

    // Hold the splash briefly so a fast device does not flash past it.
    final elapsed = DateTime.now().difference(_startedAt);
    if (elapsed < _minimumVisible) {
      await Future<void>.delayed(_minimumVisible - elapsed);
    }
    if (!mounted) return;

    await _animateTo(1, const Duration(milliseconds: 540));
    await Future<void>.delayed(const Duration(milliseconds: 420));
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

  void _leaveGame() {
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
