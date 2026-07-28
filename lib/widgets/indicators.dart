import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/design/app_theme.dart';
import '../core/design/palette.dart';
import '../core/design/typography.dart';

/// Row of up to three stars showing the score earned on a level.
class StarRow extends StatelessWidget {
  const StarRow({
    super.key,
    required this.stars,
    this.size = 16,
    this.total = 3,
    this.spacing = 2,
  });

  final int stars;
  final double size;
  final int total;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++)
          Padding(
            padding: EdgeInsets.only(right: i == total - 1 ? 0 : spacing),
            child: Icon(
              i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: i < stars
                  ? Palette.gold
                  : Palette.textMuted.withValues(alpha: 0.45),
            ),
          ),
      ],
    );
  }
}

/// Slim labelled progress bar.
class MeterBar extends StatelessWidget {
  const MeterBar({
    super.key,
    required this.value,
    this.height = 6,
    this.color = Palette.ember,
    this.track,
    this.radius = 999,
  });

  final double value;
  final double height;
  final Color color;
  final Color? track;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        children: [
          Container(
            height: height,
            color: track ?? Palette.surfaceTop.withValues(alpha: 0.8),
          ),
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.75), color],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact metric block: a number, a caption, and an optional icon.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.accent = Palette.ember,
    this.compact = false,
  });

  final String value;
  final String label;
  final IconData? icon;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: compact ? 15 : 18, color: accent),
          const SizedBox(height: Insets.s),
        ],
        Text(
          value,
          style: (compact ? AppText.numeral : AppText.numeralL).copyWith(
            fontSize: compact ? 18 : 26,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(label.toUpperCase(), style: AppText.overline, maxLines: 2),
      ],
    );
  }
}

/// Circular progress ring with content in the middle.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.child,
    this.size = 64,
    this.stroke = 5,
    this.color = Palette.ember,
  });

  final double value;
  final Widget child;
  final double size;
  final double stroke;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          value: value.clamp(0.0, 1.0),
          stroke: stroke,
          color: color,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.stroke,
    required this.color,
  });

  final double value;
  final double stroke;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - stroke) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Palette.surfaceTop,
    );
    if (value <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: math.pi * 1.5,
          colors: [color.withValues(alpha: 0.35), color],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.color != color;
}

/// Number that rolls to its new value instead of snapping.
class AnimatedNumber extends StatelessWidget {
  const AnimatedNumber({
    super.key,
    required this.value,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 620),
  });

  final int value;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        '$prefix${v.round()}$suffix',
        style: style ?? AppText.numeral,
      ),
    );
  }
}

/// Coloured key/value row used across detail sheets.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: Palette.textMuted),
            const SizedBox(width: Insets.s),
          ],
          Expanded(child: Text(label, style: AppText.bodyM)),
          Text(
            value,
            style: AppText.label.copyWith(
              color: valueColor ?? Palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
