import 'package:flutter/material.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/palette.dart';
import '../../core/design/typography.dart';
import '../../data/sprites.dart';
import '../../game/logic/engine.dart';
import '../../game/model/level.dart';
import '../../game/render/board_art.dart';
import '../../widgets/indicators.dart';
import '../../widgets/surfaces.dart';

/// Objective counters shown above the board.
class ObjectiveBar extends StatelessWidget {
  const ObjectiveBar({
    super.key,
    required this.game,
    required this.accent,
  });

  final GameState game;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final level = game.level;
    final movesLeft = game.movesLeft;
    final pressure = movesLeft <= 3
        ? Palette.danger
        : (movesLeft <= 6 ? Palette.gold : accent);

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: _Pill(
            icon: Icons.directions_walk_rounded,
            label: 'MOVES',
            value: '${game.moves}/${level.moveLimit}',
            accent: pressure,
            meter: 1 - (game.moves / level.moveLimit).clamp(0.0, 1.0),
          ),
        ),
        const SizedBox(width: Insets.s),
        Expanded(
          flex: 4,
          child: _Pill(
            icon: Icons.diamond_rounded,
            label: 'RELICS',
            value: '${game.relics.length}/${level.relics.length}',
            accent: game.hasAllRelics ? Palette.success : Palette.arcane,
          ),
        ),
        const SizedBox(width: Insets.s),
        Expanded(
          flex: 4,
          child: _Pill(
            icon: Icons.hexagon_rounded,
            label: 'SHARDS',
            value: '${game.crystals.length}/${level.crystals.length}',
            accent: Palette.ice,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.meter,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final double? meter;

  @override
  Widget build(BuildContext context) {
    return Panel(
      radius: Corners.m,
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.m,
        vertical: Insets.s + 2,
      ),
      color: Palette.surface.withValues(alpha: 0.86),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: accent),
              const SizedBox(width: 5),
              Expanded(child: Text(label, style: AppText.overline)),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppText.numeral.copyWith(fontSize: 16, color: accent),
          ),
          if (meter != null) ...[
            const SizedBox(height: 6),
            MeterBar(value: meter!, color: accent, height: 3),
          ],
        ],
      ),
    );
  }
}

/// Live readout of how much trail currently sits in each cooling stage.
///
/// This is the puzzle's clock, so it gets a permanent place under the board
/// rather than being hidden behind a tooltip.
class StageTimeline extends StatelessWidget {
  const StageTimeline({super.key, required this.game});

  final GameState game;

  @override
  Widget build(BuildContext context) {
    final counts = <TrailStage, int>{for (final s in TrailStage.values) s: 0};
    for (var cell = 0; cell < game.level.cellCount; cell++) {
      final stage = game.stageAt(cell);
      if (stage != null) counts[stage] = counts[stage]! + 1;
    }

    return Panel(
      radius: Corners.m,
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.m,
        vertical: Insets.s + 2,
      ),
      color: Palette.surface.withValues(alpha: 0.86),
      child: Row(
        children: [
          for (var i = 0; i < TrailStage.values.length; i++) ...[
            Expanded(
              child: _StageChip(
                stage: TrailStage.values[i],
                count: counts[TrailStage.values[i]]!,
              ),
            ),
            if (i != TrailStage.values.length - 1)
              Container(width: 1, height: 26, color: Palette.hairline),
          ],
        ],
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({required this.stage, required this.count});

  final TrailStage stage;
  final int count;

  @override
  Widget build(BuildContext context) {
    final color = BoardArt.stageColor(stage);
    final active = count > 0;
    return Opacity(
      opacity: active ? 1 : 0.42,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            Sprites.trail(Sprites.trailStageStraight[stage.index]),
            width: 26,
            height: 26,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                Icon(BoardArt.stageIcon(stage), size: 14, color: color),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: AppText.numeral.copyWith(fontSize: 14, color: color),
              ),
              Text(
                stage.label.split(' ').last.toUpperCase(),
                style: AppText.overline.copyWith(fontSize: 8, letterSpacing: 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
