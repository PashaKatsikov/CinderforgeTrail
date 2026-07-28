import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/palette.dart';
import '../../core/design/typography.dart';
import '../../data/catalog.dart';
import '../../data/sprites.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/surfaces.dart';

/// Almanac of trail weather, built as an accordion.
///
/// Only one entry is open at a time, which keeps the page short and makes the
/// list feel like flipping through a field guide.
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  int _open = 0;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Sky Almanac',
      subtitle: 'What the mountain throws at a route',
      child: ListView(
        padding: const EdgeInsets.only(bottom: Insets.xxl),
        children: [
          Panel(
            color: Palette.surface.withValues(alpha: 0.6),
            child: Row(
              children: [
                const Icon(Icons.cloud_rounded,
                    size: 18, color: Palette.textSecondary),
                const SizedBox(width: Insets.m),
                Expanded(
                  child: Text(
                    'Weather changes how fast a trail cools. Later regions run '
                    'their own conditions, so read the sky before you plan.',
                    style: AppText.bodyS,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.l),
          for (var i = 0; i < Catalog.weather.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.m),
              child: _WeatherTile(
                info: Catalog.weather[i],
                expanded: _open == i,
                accent: _accents[i % _accents.length],
                onTap: () => setState(() => _open = _open == i ? -1 : i),
              ).animate().fadeIn(delay: (i * 55).ms).slideY(begin: 0.05),
            ),
        ],
      ),
    );
  }

  static const _accents = [
    Palette.textSecondary,
    Palette.magma,
    Palette.ember,
    Palette.danger,
    Palette.obsidian,
    Palette.gold,
  ];
}

class _WeatherTile extends StatelessWidget {
  const _WeatherTile({
    required this.info,
    required this.expanded,
    required this.accent,
    required this.onTap,
  });

  final WeatherInfo info;
  final bool expanded;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Panel(
      onTap: onTap,
      radius: Corners.m,
      padding: const EdgeInsets.all(Insets.l),
      borderColor: expanded ? accent.withValues(alpha: 0.4) : Palette.hairline,
      child: AnimatedSize(
        duration: Motion.fast,
        curve: Motion.curve,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 34,
                  height: 34,
                  child: Image.asset(
                    Sprites.effect(info.effectSprite),
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        Icon(Icons.air_rounded, color: accent, size: 18),
                  ),
                ),
                const SizedBox(width: Insets.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(info.name, style: AppText.label),
                      Text(
                        info.effect.toUpperCase(),
                        style:
                            AppText.overline.copyWith(color: accent, fontSize: 9),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: Motion.fast,
                  child: const Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: Palette.textMuted,
                  ),
                ),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: Insets.m),
              const FadedDivider(),
              const SizedBox(height: Insets.m),
              Text(info.detail, style: AppText.bodyM),
            ],
          ],
        ),
      ),
    );
  }
}
