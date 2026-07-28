import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/palette.dart';
import '../../core/design/typography.dart';
import '../../core/router/routes.dart';
import '../../core/services/audio_service.dart';
import '../../data/catalog.dart';
import '../../data/sprites.dart';
import '../../game/logic/level_generator.dart';
import '../../game/model/level.dart';
import '../../game/render/board_art.dart';
import '../../state/app_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/indicators.dart';
import '../../widgets/surfaces.dart';

/// Level picker for one region.
///
/// Uses a quilted grid so the next level to play can occupy a larger tile,
/// which makes the "where was I" question answerable at a glance.
class LevelSelectScreen extends ConsumerWidget {
  const LevelSelectScreen({super.key, required this.region});

  final int region;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final audio = ref.watch(audioProvider);
    final info = Catalog.region(region);
    const perRegion = LevelGenerator.levelsPerRegion;
    final first = (region - 1) * perRegion;

    final nextId = ref.watch(nextLevelProvider);
    final stars = profile.starsInRegion(region, perRegion);

    return AppScaffold(
      title: info.name,
      subtitle: info.teaches,
      backdrop: Sprites.background(region),
      backdropOpacity: 0.28,
      backdropBlur: 5,
      padded: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.page),
            sliver: SliverToBoxAdapter(
              child: Panel(
                glow: info.accent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info.lore, style: AppText.bodyM),
                    const SizedBox(height: Insets.l),
                    Row(
                      children: [
                        Expanded(
                          child: MeterBar(
                            value: stars / (perRegion * 3),
                            color: info.accent,
                            height: 5,
                          ),
                        ),
                        const SizedBox(width: Insets.m),
                        Text(
                          '$stars / ${perRegion * 3} ★',
                          style: AppText.bodyS.copyWith(color: info.accent),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Insets.xl)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Insets.page,
              0,
              Insets.page,
              Insets.xxl,
            ),
            sliver: SliverAlignedGrid.count(
              crossAxisCount: 3,
              mainAxisSpacing: Insets.m,
              crossAxisSpacing: Insets.m,
              itemCount: perRegion,
              itemBuilder: (context, index) {
                final id = first + index;
                final level = LevelGenerator.byId(id);
                final unlocked = profile.isLevelUnlocked(id, perRegion);
                final earned = profile.stars[id] ?? 0;

                return _LevelTile(
                  level: level,
                  stars: earned,
                  unlocked: unlocked,
                  isNext: id == nextId,
                  best: profile.bestMoves[id],
                  accent: info.accent,
                  onTap: () {
                    if (!unlocked) {
                      audio.play(Sfx.error);
                      return;
                    }
                    audio.play(Sfx.levelStart);
                    context.push(Routes.gameOf(id));
                  },
                )
                    .animate()
                    .fadeIn(delay: (index * 28).ms, duration: 250.ms)
                    .scale(begin: const Offset(0.94, 0.94));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.stars,
    required this.unlocked,
    required this.isNext,
    required this.best,
    required this.accent,
    required this.onTap,
  });

  final LevelSpec level;
  final int stars;
  final bool unlocked;
  final bool isNext;
  final int? best;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = stars > 0;
    return Panel(
      onTap: onTap,
      radius: Corners.m,
      padding: const EdgeInsets.all(Insets.m),
      glow: isNext ? accent : null,
      borderColor: isNext
          ? accent.withValues(alpha: 0.55)
          : (done ? Palette.hairlineStrong : Palette.hairline),
      color: unlocked
          ? Palette.surface.withValues(alpha: 0.82)
          : Palette.surface.withValues(alpha: 0.45),
      child: Opacity(
        opacity: unlocked ? 1 : 0.45,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  '${level.indexInRegion}'.padLeft(2, '0'),
                  style: AppText.numeral.copyWith(
                    fontSize: 20,
                    color: done ? Palette.textPrimary : Palette.textSecondary,
                  ),
                ),
                const Spacer(),
                if (!unlocked)
                  const Icon(Icons.lock_rounded, size: 14, color: Palette.textMuted)
                else if (done)
                  Icon(Icons.check_circle_rounded, size: 14, color: accent),
              ],
            ),
            const SizedBox(height: Insets.s),
            SizedBox(
              height: 34,
              child: Row(
                children: [
                  _MiniPreview(level: level, accent: accent, dim: !unlocked),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('PAR ${level.parMoves}', style: AppText.overline),
                        if (best != null)
                          Text(
                            'BEST $best',
                            style: AppText.overline.copyWith(color: accent),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Insets.s),
            StarRow(stars: stars, size: 13),
          ],
        ),
      ),
    );
  }
}

/// Tiny thumbnail of the level's shape, drawn from its own route data.
class _MiniPreview extends StatelessWidget {
  const _MiniPreview({
    required this.level,
    required this.accent,
    required this.dim,
  });

  final LevelSpec level;
  final Color accent;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: CustomPaint(
        painter: _PreviewPainter(
          level: level,
          accent: dim ? Palette.textMuted : accent,
        ),
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  const _PreviewPainter({required this.level, required this.accent});

  final LevelSpec level;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / level.width;
    final dot = Paint()..color = Palette.textMuted.withValues(alpha: 0.20);
    final route = Paint()..color = accent.withValues(alpha: 0.85);

    for (var i = 0; i < level.cellCount; i++) {
      if (level.voids.contains(i)) continue;
      final rect = Rect.fromLTWH(
        level.xOf(i) * cell + cell * 0.22,
        level.yOf(i) * cell + cell * 0.22,
        cell * 0.56,
        cell * 0.56,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.16)),
        dot,
      );
    }
    for (final c in level.solution) {
      final rect = Rect.fromLTWH(
        level.xOf(c) * cell + cell * 0.2,
        level.yOf(c) * cell + cell * 0.2,
        cell * 0.6,
        cell * 0.6,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.18)),
        route,
      );
    }
    // Mark the goal so tiles differ from one another at a glance.
    canvas.drawCircle(
      Offset(
        level.xOf(level.exit) * cell + cell / 2,
        level.yOf(level.exit) * cell + cell / 2,
      ),
      cell * 0.22,
      Paint()..color = BoardArt.stageColor(TrailStage.metal),
    );
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter old) =>
      old.level != level || old.accent != accent;
}
