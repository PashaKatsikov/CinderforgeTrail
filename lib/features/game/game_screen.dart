import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/palette.dart';
import '../../core/design/typography.dart';
import '../../core/router/routes.dart';
import '../../core/services/audio_service.dart';
import '../../data/catalog.dart';
import '../../data/sprites.dart';
import '../../game/logic/engine.dart';
import '../../game/logic/game_session.dart';
import '../../game/logic/level_generator.dart';
import '../../game/render/board_art.dart';
import '../../game/render/board_view.dart';
import '../../game/render/sprite_cache.dart';
import '../../state/app_state.dart';
import '../../widgets/buttons.dart';
import '../../widgets/surfaces.dart';
import 'game_hud.dart';
import 'level_result_screen.dart';
import 'pause_sheet.dart';

/// The playable screen: HUD on top, board in the middle, tools underneath.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.levelId});

  final int levelId;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  GameSession? _session;
  bool _ready = false;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  @override
  void dispose() {
    _session?.removeListener(_onSessionChanged);
    _session?.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    final profile = ref.read(profileProvider);
    final level = LevelGenerator.byId(widget.levelId);

    await SpriteCache.instance.load(
      BoardArt.assetsFor(level, profile.selectedCharacter),
    );
    if (!mounted) return;

    final session = GameSession(
      level: level,
      extraMoves: profile.bonusMoves,
      hints: profile.bonusHints,
    )..addListener(_onSessionChanged);

    ref.read(profileProvider.notifier).registerRunStarted();

    setState(() {
      _session = session;
      _ready = true;
    });
  }

  void _onSessionChanged() {
    final session = _session;
    if (session == null || _resolved) return;
    final game = session.value.game;
    if (!game.isOver) return;
    _resolved = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _finish(session));
  }

  Future<void> _finish(GameSession session) async {
    if (!mounted) return;
    final game = session.value.game;
    final audio = ref.read(audioProvider);
    final won = game.outcome == GameOutcome.won;
    audio.play(won ? Sfx.levelComplete : Sfx.levelFailed);
    audio.buzz(won ? HapticKind.heavy : HapticKind.medium);

    RunRewards? rewards;
    final stars = Engine.starsFor(game);
    if (won) {
      rewards = ref.read(profileProvider.notifier).completeRun(
            RunResult(
              levelId: widget.levelId,
              stars: stars,
              moves: game.moves,
              par: session.level.parMoves,
              crystals: game.crystals.length,
              iceMelted: session.value.tally.iceMelted,
              growthBurned: session.value.tally.growthBurned,
              gatesPassed: session.value.tally.gatesPassed,
              golemSteps: session.value.tally.golemSteps,
              forgesLit: session.value.tally.forgesLit,
              seconds: session.elapsedSeconds,
            ),
          );
    }

    if (!mounted) return;
    final action = await Navigator.of(context).push<ResultAction>(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 340),
        pageBuilder: (_, _, _) => LevelResultScreen(
          levelId: widget.levelId,
          outcome: game.outcome,
          stars: stars,
          moves: game.moves,
          par: session.level.parMoves,
          crystals: game.crystals.length,
          totalCrystals: session.level.crystals.length,
          seconds: session.elapsedSeconds,
          rewards: rewards,
        ),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );

    if (!mounted) return;
    switch (action) {
      case ResultAction.retry:
        _resolved = false;
        session.restart();
        ref.read(profileProvider.notifier).registerRestart();
      case ResultAction.next:
        final next = widget.levelId + 1;
        if (next < LevelGenerator.totalLevels) {
          context.pushReplacement(Routes.gameOf(next));
        } else {
          context.pop();
        }
      case ResultAction.quit:
      case null:
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(Routes.home);
        }
    }
  }

  void _restart() {
    _resolved = false;
    _session?.restart();
    ref.read(profileProvider.notifier).registerRestart();
    ref.read(audioProvider).play(Sfx.cancel);
  }

  void _undo() {
    if (_session?.undo() ?? false) {
      ref.read(profileProvider.notifier).registerUndo();
      ref.read(audioProvider).play(Sfx.menuClose);
    }
  }

  void _hint() {
    final session = _session;
    if (session == null) return;
    final audio = ref.read(audioProvider);
    switch (session.hint()) {
      case HintOutcome.shown:
        audio.play(Sfx.notify);
        ref.read(profileProvider.notifier).registerHint();
      case HintOutcome.rewound:
        audio.play(Sfx.menuClose);
        ref.read(profileProvider.notifier).registerHint();
        _toast('Rewound to the last point on the ideal route.');
      case HintOutcome.exhausted:
        audio.play(Sfx.error);
        _toast('No hints left. Upgrade Forge Sense to carry more.');
      case HintOutcome.unavailable:
        audio.play(Sfx.error);
        _toast('No hint available here.');
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pause() async {
    final session = _session;
    if (session == null) return;
    ref.read(audioProvider).play(Sfx.menuOpen);
    final action = await showPauseSheet(context);
    if (!mounted || action == null) return;
    switch (action) {
      case PauseAction.restart:
        _restart();
      case PauseAction.quit:
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(Routes.home);
        }
      case PauseAction.resume:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = LevelGenerator.byId(widget.levelId);
    final info = Catalog.region(level.region);
    final settings = ref.watch(settingsProvider);
    final profile = ref.watch(profileProvider);
    final session = _session;

    return PopScope(
      canPop: true,
      child: Scaffold(
        body: Stack(
          children: [
            BackdropArt(
              asset: Sprites.background(level.region),
              opacity: 0.34,
              blur: 6,
            ),
            SafeArea(
              child: !_ready || session == null
                  ? const _BoardLoading()
                  : ValueListenableBuilder<SessionState>(
                      valueListenable: session,
                      builder: (context, state, _) {
                        return Column(
                          children: [
                            _TopBar(
                              title: 'Level ${level.indexInRegion}',
                              subtitle: info.name,
                              accent: info.accent,
                              onBack: () => context.canPop()
                                  ? context.pop()
                                  : context.go(Routes.home),
                              onPause: _pause,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Insets.page,
                              ),
                              child: ObjectiveBar(
                                game: state.game,
                                accent: info.accent,
                              ),
                            ),
                            Expanded(
                              child: BoardView(
                                session: session,
                                settings: settings,
                                characterSprite: profile.selectedCharacter,
                                routePreviewSteps: profile.routePreview,
                                onMove: () {
                                  final audio = ref.read(audioProvider);
                                  audio.play(Sfx.tap);
                                  audio.buzz(HapticKind.light);
                                },
                                onRejected: () {
                                  final audio = ref.read(audioProvider);
                                  audio.play(Sfx.error);
                                  audio.buzz(HapticKind.medium);
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Insets.page,
                              ),
                              child: StageTimeline(game: state.game),
                            ),
                            _Toolbar(
                              canUndo: state.canUndo,
                              hintsLeft: state.hintsLeft,
                              onUndo: _undo,
                              onRestart: _restart,
                              onHint: _hint,
                              onCodex: () => context.push(Routes.codex),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onBack,
    required this.onPause,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onBack;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Insets.page - 4,
        Insets.s,
        Insets.page - 4,
        Insets.m,
      ),
      child: Row(
        children: [
          IconPill(icon: Icons.arrow_back_rounded, onPressed: onBack, size: 40),
          const SizedBox(width: Insets.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppText.section),
                Text(
                  subtitle.toUpperCase(),
                  style: AppText.overline.copyWith(color: accent),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconPill(
            icon: Icons.pause_rounded,
            onPressed: onPause,
            size: 40,
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.canUndo,
    required this.hintsLeft,
    required this.onUndo,
    required this.onRestart,
    required this.onHint,
    required this.onCodex,
  });

  final bool canUndo;
  final int hintsLeft;
  final VoidCallback onUndo;
  final VoidCallback onRestart;
  final VoidCallback onHint;
  final VoidCallback onCodex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Insets.page,
        Insets.m,
        Insets.page,
        Insets.m,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Tool(
            icon: Icons.undo_rounded,
            label: 'Undo',
            onTap: canUndo ? onUndo : null,
          ),
          _Tool(
            icon: Icons.refresh_rounded,
            label: 'Restart',
            onTap: onRestart,
          ),
          _Tool(
            icon: Icons.lightbulb_rounded,
            label: 'Hint',
            tone: Palette.gold,
            badge: '$hintsLeft',
            onTap: hintsLeft > 0 ? onHint : null,
          ),
          _Tool(
            icon: Icons.menu_book_rounded,
            label: 'Codex',
            onTap: onCodex,
          ),
        ],
      ),
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tone = Palette.textPrimary,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color tone;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconPill(
          icon: icon,
          onPressed: onTap,
          tone: tone,
          badge: badge,
          filled: tone != Palette.textPrimary,
        ),
        const SizedBox(height: 5),
        Text(label.toUpperCase(), style: AppText.overline),
      ],
    );
  }
}

class _BoardLoading extends StatelessWidget {
  const _BoardLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: Insets.l),
          Text('Heating the ground', style: AppText.bodyM),
        ],
      ).animate().fadeIn(),
    );
  }
}
