import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/palette.dart';
import '../../core/design/typography.dart';
import '../../data/catalog.dart';
import '../../data/sprites.dart';
import '../../game/logic/engine.dart';
import '../../game/logic/level_generator.dart';
import '../../state/app_state.dart';
import '../../widgets/buttons.dart';
import '../../widgets/indicators.dart';
import '../../widgets/surfaces.dart';

enum ResultAction { retry, next, quit }

/// End-of-run summary. Celebrates a win with confetti and a staggered star
/// reveal, and explains plainly what went wrong on a loss.
class LevelResultScreen extends ConsumerStatefulWidget {
  const LevelResultScreen({
    super.key,
    required this.levelId,
    required this.outcome,
    required this.stars,
    required this.moves,
    required this.par,
    required this.crystals,
    required this.totalCrystals,
    required this.seconds,
    required this.rewards,
  });

  final int levelId;
  final GameOutcome outcome;
  final int stars;
  final int moves;
  final int par;
  final int crystals;
  final int totalCrystals;
  final int seconds;
  final RunRewards? rewards;

  @override
  ConsumerState<LevelResultScreen> createState() => _LevelResultScreenState();
}

class _LevelResultScreenState extends ConsumerState<LevelResultScreen> {
  late final ConfettiController _confetti = ConfettiController(
    duration: const Duration(milliseconds: 1200),
  );

  bool get _won => widget.outcome == GameOutcome.won;

  @override
  void initState() {
    super.initState();
    if (_won && widget.stars >= 2) _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  String get _headline => switch (widget.outcome) {
        GameOutcome.won => widget.stars == 3 ? 'Perfect Route' : 'Trail Cleared',
        GameOutcome.lostOutOfMoves => 'Out of Moves',
        GameOutcome.lostStuck => 'Nowhere Left to Step',
        GameOutcome.playing => 'Run Ended',
      };

  String get _detail => switch (widget.outcome) {
        GameOutcome.won =>
          'You reached the far side in ${widget.moves} moves (par ${widget.par}).',
        GameOutcome.lostOutOfMoves =>
          'The trail ran cold before the exit. Try a tighter loop.',
        GameOutcome.lostStuck =>
          'Every neighbouring tile was sealed. Undo and let something cool first.',
        GameOutcome.playing => '',
      };

  @override
  Widget build(BuildContext context) {
    final level = LevelGenerator.byId(widget.levelId);
    final region = Catalog.region(level.region);
    final rewards = widget.rewards;
    final isLast = widget.levelId >= LevelGenerator.totalLevels - 1;

    return Scaffold(
      body: Stack(
        children: [
          BackdropArt(
            asset: Sprites.background(level.region),
            opacity: 0.30,
            blur: 8,
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirection: math.pi / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 14,
              maxBlastForce: 18,
              minBlastForce: 8,
              gravity: 0.25,
              colors: const [
                Palette.ember,
                Palette.gold,
                Palette.metal,
                Palette.magma,
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Insets.page),
              child: Column(
                children: [
                  const Spacer(),
                  Icon(
                    _won
                        ? Icons.local_fire_department_rounded
                        : Icons.ac_unit_rounded,
                    size: 42,
                    color: _won ? Palette.ember : Palette.ice,
                  ).animate().scale(
                        duration: 420.ms,
                        curve: Curves.easeOutBack,
                      ),
                  const SizedBox(height: Insets.l),
                  Text(
                    _headline,
                    style: AppText.hero.copyWith(fontSize: 28),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: Insets.s),
                  Text(
                    _detail,
                    style: AppText.bodyM,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 180.ms),
                  const SizedBox(height: Insets.xl),
                  if (_won) _Stars(stars: widget.stars),
                  const SizedBox(height: Insets.xl),
                  Panel(
                    glow: _won ? region.accent : null,
                    child: Column(
                      children: [
                        DetailRow(
                          label: 'Moves used',
                          value: '${widget.moves} / par ${widget.par}',
                          valueColor: widget.moves <= widget.par
                              ? Palette.success
                              : Palette.textPrimary,
                          icon: Icons.directions_walk_rounded,
                        ),
                        DetailRow(
                          label: 'Shards collected',
                          value: '${widget.crystals} / ${widget.totalCrystals}',
                          icon: Icons.hexagon_rounded,
                        ),
                        DetailRow(
                          label: 'Time on the trail',
                          value: _formatTime(widget.seconds),
                          icon: Icons.schedule_rounded,
                        ),
                        if (rewards != null) ...[
                          const SizedBox(height: Insets.s),
                          const FadedDivider(),
                          const SizedBox(height: Insets.s),
                          DetailRow(
                            label: 'Embers earned',
                            value: '+${rewards.embers}',
                            valueColor: Palette.ember,
                            icon: Icons.local_fire_department_rounded,
                          ),
                          DetailRow(
                            label: 'Experience',
                            value: '+${rewards.xp}',
                            valueColor: Palette.gold,
                            icon: Icons.trending_up_rounded,
                          ),
                        ],
                      ],
                    ),
                  ).animate().fadeIn(delay: 260.ms).slideY(begin: 0.08),
                  if (rewards != null && rewards.relicSprite != null) ...[
                    const SizedBox(height: Insets.m),
                    _Discovery(
                      title: 'Relic recovered',
                      name: Catalog.relics
                          .firstWhere((r) => r.sprite == rewards.relicSprite)
                          .name,
                      asset: Sprites.relic(rewards.relicSprite!),
                    ).animate().fadeIn(delay: 360.ms),
                  ],
                  if (rewards != null && rewards.newAchievements.isNotEmpty) ...[
                    const SizedBox(height: Insets.m),
                    for (final achievement in rewards.newAchievements.take(2))
                      Padding(
                        padding: const EdgeInsets.only(bottom: Insets.s),
                        child: _Discovery(
                          title: 'Achievement unlocked',
                          name: achievement.name,
                          icon: achievement.icon,
                        ),
                      ),
                  ],
                  const Spacer(),
                  if (_won && !isLast)
                    EmberButton(
                      label: 'Next level',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () =>
                          Navigator.pop(context, ResultAction.next),
                    )
                  else
                    EmberButton(
                      label: _won ? 'Back to the map' : 'Try again',
                      icon: _won
                          ? Icons.map_rounded
                          : Icons.refresh_rounded,
                      onPressed: () => Navigator.pop(
                        context,
                        _won ? ResultAction.quit : ResultAction.retry,
                      ),
                    ),
                  const SizedBox(height: Insets.m),
                  Row(
                    children: [
                      Expanded(
                        child: GhostButton(
                          label: _won ? 'Replay' : 'Give up',
                          icon: _won
                              ? Icons.refresh_rounded
                              : Icons.logout_rounded,
                          onPressed: () => Navigator.pop(
                            context,
                            _won ? ResultAction.retry : ResultAction.quit,
                          ),
                        ),
                      ),
                      const SizedBox(width: Insets.m),
                      Expanded(
                        child: GhostButton(
                          label: 'Trail map',
                          icon: Icons.map_rounded,
                          onPressed: () =>
                              Navigator.pop(context, ResultAction.quit),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
              size: i == 1 ? 52 : 42,
              color: i < stars
                  ? Palette.gold
                  : Palette.textMuted.withValues(alpha: 0.4),
            )
                .animate(delay: (240 + i * 160).ms)
                .scale(
                  begin: const Offset(0.2, 0.2),
                  duration: 380.ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn(),
          ),
      ],
    );
  }
}

class _Discovery extends StatelessWidget {
  const _Discovery({
    required this.title,
    required this.name,
    this.asset,
    this.icon,
  });

  final String title;
  final String name;
  final String? asset;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Panel(
      radius: Corners.m,
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.m,
        vertical: Insets.m,
      ),
      borderColor: Palette.gold.withValues(alpha: 0.35),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: asset != null
                ? Image.asset(asset!, fit: BoxFit.contain)
                : Icon(icon ?? Icons.star_rounded, color: Palette.gold),
          ),
          const SizedBox(width: Insets.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title.toUpperCase(), style: AppText.overline),
                Text(name, style: AppText.label),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
