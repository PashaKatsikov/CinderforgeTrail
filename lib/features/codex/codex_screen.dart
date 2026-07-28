import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/palette.dart';
import '../../core/design/typography.dart';
import '../../data/sprites.dart';
import '../../game/model/level.dart';
import '../../game/render/board_art.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/surfaces.dart';

/// Reference material for every rule in the game, split into three tabs.
///
/// Tabs are used here and nowhere else: the content is three parallel lists
/// of the same shape, which is exactly the case tabs are good at.
class CodexScreen extends StatelessWidget {
  const CodexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: AppScaffold(
        title: 'Codex',
        subtitle: 'Every rule of the trail',
        padded: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.page),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: Corners.m,
                  color: Palette.surface.withValues(alpha: 0.7),
                  border: Border.all(color: Palette.hairline),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: Corners.s,
                    gradient: Palette.emberGradient,
                  ),
                  labelStyle: AppText.label.copyWith(fontSize: 12),
                  unselectedLabelStyle: AppText.bodyS,
                  labelColor: Palette.void0,
                  unselectedLabelColor: Palette.textSecondary,
                  tabs: const [
                    Tab(height: 34, text: 'Heat'),
                    Tab(height: 34, text: 'Ground'),
                    Tab(height: 34, text: 'Barriers'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Insets.l),
            const Expanded(
              child: TabBarView(
                children: [_StagesTab(), _SurfacesTab(), _ObstaclesTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StagesTab extends StatelessWidget {
  const _StagesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Insets.page,
        0,
        Insets.page,
        Insets.xxl,
      ),
      children: [
        Panel(
          color: Palette.surface.withValues(alpha: 0.6),
          child: Text(
            'Every step you take leaves trail behind you. It starts molten and '
            'loses one stage of heat as you keep walking, so the order of your '
            'route decides which barriers open.',
            style: AppText.bodyM,
          ),
        ),
        const SizedBox(height: Insets.l),
        for (var i = 0; i < TrailStage.values.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: Insets.m),
            child: _Entry(
              asset: Sprites.trail(Sprites.trailStageStraight[i]),
              accent: BoardArt.stageColor(TrailStage.values[i]),
              title: TrailStage.values[i].label,
              body: TrailStage.values[i].description,
              tag: 'STAGE ${i + 1}',
            ).animate().fadeIn(delay: (i * 60).ms).slideX(begin: 0.05),
          ),
      ],
    );
  }
}

class _SurfacesTab extends StatelessWidget {
  const _SurfacesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Insets.page,
        0,
        Insets.page,
        Insets.xxl,
      ),
      children: [
        Panel(
          color: Palette.surface.withValues(alpha: 0.6),
          child: Text(
            'The ground under a trail decides how fast it cools. Sand keeps a '
            'route alive; ash eats it within a couple of moves.',
            style: AppText.bodyM,
          ),
        ),
        const SizedBox(height: Insets.l),
        for (var i = 0; i < Surface.values.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: Insets.m),
            child: _Entry(
              asset: BoardArt.ground(Surface.values[i]),
              accent: BoardArt.surfaceTint(Surface.values[i]),
              title: Surface.values[i].label,
              body: Surface.values[i].description,
              tag: '-${Surface.values[i].coolRate} HEAT / MOVE',
            ).animate().fadeIn(delay: (i * 60).ms).slideX(begin: 0.05),
          ),
      ],
    );
  }
}

class _ObstaclesTab extends StatelessWidget {
  const _ObstaclesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Insets.page,
        0,
        Insets.page,
        Insets.xxl,
      ),
      children: [
        Panel(
          color: Palette.surface.withValues(alpha: 0.6),
          child: Text(
            'Barriers react to the trail beside them, never to the trail they '
            'stand on. Some clear permanently; others only hold while the right '
            'heat is next to them.',
            style: AppText.bodyM,
          ),
        ),
        const SizedBox(height: Insets.l),
        for (var i = 0; i < Obstacle.values.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: Insets.m),
            child: _Entry(
              asset: _assetFor(Obstacle.values[i]),
              accent: Obstacle.values[i].stage == null
                  ? Palette.gold
                  : BoardArt.stageColor(Obstacle.values[i].stage!),
              title: Obstacle.values[i].label,
              body: Obstacle.values[i].description,
              tag: Obstacle.values[i].permanent ? 'PERMANENT' : 'WHILE HOT',
            ).animate().fadeIn(delay: (i * 60).ms).slideX(begin: 0.05),
          ),
      ],
    );
  }

  static String _assetFor(Obstacle obstacle) => switch (obstacle) {
        Obstacle.iceWall => BoardArt.iceWall(0),
        Obstacle.cinderVine => BoardArt.cinderVine(0),
        Obstacle.magnetGate => BoardArt.magnetGate(),
        Obstacle.obsidianStep => BoardArt.golemActive(),
        Obstacle.forge => BoardArt.forge(TrailStage.magma),
        Obstacle.runeGate => BoardArt.runeSeal(),
      };
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.asset,
    required this.accent,
    required this.title,
    required this.body,
    required this.tag,
  });

  final String asset;
  final Color accent;
  final String title;
  final String body;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Panel(
      radius: Corners.m,
      padding: const EdgeInsets.all(Insets.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: Corners.s,
              color: Palette.void0.withValues(alpha: 0.35),
              border: Border.all(color: accent.withValues(alpha: 0.24)),
            ),
            padding: const EdgeInsets.all(4),
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  Icon(Icons.help_outline_rounded, color: accent, size: 18),
            ),
          ),
          const SizedBox(width: Insets.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: AppText.label)),
                    Text(
                      tag,
                      style: AppText.overline.copyWith(
                        color: accent,
                        fontSize: 8.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(body, style: AppText.bodyS),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
