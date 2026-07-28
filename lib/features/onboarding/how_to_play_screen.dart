import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/palette.dart';
import '../../core/design/typography.dart';
import '../../core/router/routes.dart';
import '../../core/services/audio_service.dart';
import '../../data/sprites.dart';
import '../../game/model/level.dart';
import '../../game/render/board_art.dart';
import '../../state/app_state.dart';
import '../../widgets/buttons.dart';
import '../../widgets/surfaces.dart';

class _Slide {
  const _Slide({
    required this.title,
    required this.body,
    required this.asset,
    required this.accent,
    required this.tip,
  });

  final String title;
  final String body;
  final String asset;
  final Color accent;
  final String tip;
}

/// First-run walkthrough, also reachable later from the menu.
///
/// Full-bleed slides with a single idea each; the reader should never have to
/// hold two rules in their head at once.
class HowToPlayScreen extends ConsumerStatefulWidget {
  const HowToPlayScreen({super.key, this.onboarding = false});

  /// When true, finishing the tour sends the player to the home screen and
  /// marks onboarding as seen.
  final bool onboarding;

  @override
  ConsumerState<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends ConsumerState<HowToPlayScreen> {
  final _controller = PageController();
  int _page = 0;

  late final List<_Slide> _slides = [
    _Slide(
      title: 'Leave a trail',
      body: 'Every step drops molten rock behind you. The trail is the puzzle: '
          'it is your only tool and your biggest obstacle.',
      asset: Sprites.trail(Sprites.trailStageStraight[0]),
      accent: Palette.magma,
      tip: 'Tap a neighbouring tile, or swipe, to step.',
    ),
    _Slide(
      title: 'Heat fades',
      body: 'Trail cools one stage at a time: magma, ember, molten metal, then '
          'cold obsidian. What you laid three moves ago is a different tool '
          'from what you laid just now.',
      asset: Sprites.trail(Sprites.trailStageStraight[2]),
      accent: Palette.metal,
      tip: 'The strip under the board counts what is still hot.',
    ),
    _Slide(
      title: 'Barriers react',
      body: 'Ice melts beside magma. Cinder growth burns beside embers. Gates '
          'open beside molten metal, and golems rise on cold obsidian.',
      asset: BoardArt.iceWall(0),
      accent: Palette.ice,
      tip: 'Barriers look at neighbours, never at the tile they stand on.',
    ),
    _Slide(
      title: 'Mind the ground',
      body: 'Ash steals heat fast, sand hoards it, and metal ore reheats a '
          'trail as you cross. The same route works differently on different '
          'ground.',
      asset: BoardArt.ground(Surface.ore),
      accent: Palette.gold,
      tip: 'Read the ground before committing to a loop.',
    ),
    _Slide(
      title: 'Reach the gate',
      body: 'Clear the exit before your moves run out. Finish at or under par '
          'and collect every shard for all three stars.',
      asset: BoardArt.exitPortal(),
      accent: Palette.ember,
      tip: 'Undo is free. Use it constantly.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    ref.read(audioProvider).play(Sfx.confirm);
    if (widget.onboarding) {
      ref.read(storageProvider).setOnboarded();
      context.go(Routes.home);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _slides.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          BackdropArt(
            asset: Sprites.background(_page + 1),
            opacity: 0.34,
            blur: 7,
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.all(Insets.m),
                    child: TextButton(
                      onPressed: _finish,
                      child: Text(
                        widget.onboarding ? 'Skip' : 'Close',
                        style: AppText.label.copyWith(
                          color: Palette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _slides.length,
                    onPageChanged: (i) {
                      setState(() => _page = i);
                      ref.read(audioProvider).tap();
                    },
                    itemBuilder: (context, index) =>
                        _SlideView(slide: _slides[index]),
                  ),
                ),
                SmoothPageIndicator(
                  controller: _controller,
                  count: _slides.length,
                  effect: const WormEffect(
                    dotHeight: 6,
                    dotWidth: 6,
                    spacing: 6,
                    activeDotColor: Palette.ember,
                    dotColor: Palette.hairlineStrong,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(Insets.page),
                  child: Row(
                    children: [
                      if (_page > 0)
                        Expanded(
                          child: GhostButton(
                            label: 'Back',
                            icon: Icons.arrow_back_rounded,
                            onPressed: () => _controller.previousPage(
                              duration: Motion.medium,
                              curve: Motion.curve,
                            ),
                          ),
                        ),
                      if (_page > 0) const SizedBox(width: Insets.m),
                      Expanded(
                        flex: 2,
                        child: EmberButton(
                          label: last
                              ? (widget.onboarding ? 'Start walking' : 'Done')
                              : 'Next',
                          icon: last
                              ? Icons.local_fire_department_rounded
                              : Icons.arrow_forward_rounded,
                          onPressed: last
                              ? _finish
                              : () => _controller.nextPage(
                                    duration: Motion.medium,
                                    curve: Motion.curve,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.page),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  slide.accent.withValues(alpha: 0.24),
                  Colors.transparent,
                ],
              ),
            ),
            padding: const EdgeInsets.all(Insets.xl),
            child: Image.asset(
              slide.asset,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                Icons.local_fire_department_rounded,
                size: 54,
                color: slide.accent,
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 380.ms)
              .scale(begin: const Offset(0.86, 0.86), curve: Motion.curve),
          const SizedBox(height: Insets.xl),
          Text(
            slide.title,
            style: AppText.hero.copyWith(fontSize: 26),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 90.ms),
          const SizedBox(height: Insets.m),
          Text(
            slide.body,
            style: AppText.bodyL,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 160.ms),
          const SizedBox(height: Insets.xl),
          Panel(
            radius: Corners.m,
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.l,
              vertical: Insets.m,
            ),
            borderColor: slide.accent.withValues(alpha: 0.3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tips_and_updates_rounded,
                    size: 15, color: slide.accent),
                const SizedBox(width: Insets.s),
                Flexible(child: Text(slide.tip, style: AppText.bodyS)),
              ],
            ),
          ).animate().fadeIn(delay: 240.ms),
        ],
      ),
    );
  }
}
