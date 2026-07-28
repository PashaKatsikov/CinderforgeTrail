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
import '../../game/logic/level_generator.dart';
import '../../state/app_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/indicators.dart';

/// The trail map: one tall artwork card per region, stacked vertically.
///
/// Cards scale slightly with scroll position so the list reads as a journey
/// rather than a menu.
class RegionsScreen extends ConsumerStatefulWidget {
  const RegionsScreen({super.key});

  @override
  ConsumerState<RegionsScreen> createState() => _RegionsScreenState();
}

class _RegionsScreenState extends ConsumerState<RegionsScreen> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final audio = ref.watch(audioProvider);
    const perRegion = LevelGenerator.levelsPerRegion;

    return AppScaffold(
      title: 'Trail Map',
      subtitle: '${profile.levelsCompleted} of ${LevelGenerator.totalLevels} '
          'levels walked',
      padded: false,
      child: ListView.separated(
        controller: _controller,
        padding: const EdgeInsets.fromLTRB(
          Insets.page,
          0,
          Insets.page,
          Insets.xxl,
        ),
        itemCount: Catalog.regions.length,
        separatorBuilder: (_, _) => const SizedBox(height: Insets.l),
        itemBuilder: (context, index) {
          final region = Catalog.regions[index];
          final unlocked = profile.isRegionUnlocked(region.index, perRegion);
          final done = profile.completedInRegion(region.index, perRegion);
          final stars = profile.starsInRegion(region.index, perRegion);

          return _RegionCard(
            region: region,
            unlocked: unlocked,
            completed: done,
            total: perRegion,
            stars: stars,
            onTap: () {
              if (!unlocked) {
                audio.play(Sfx.error);
                _showLocked(context, region, perRegion);
                return;
              }
              audio.tap();
              context.push(Routes.levelsOf(region.index));
            },
          )
              .animate()
              .fadeIn(delay: (index * 60).ms, duration: 320.ms)
              .slideY(begin: 0.10, curve: Motion.curve);
        },
      ),
    );
  }

  void _showLocked(BuildContext context, RegionInfo region, int perRegion) {
    final needed = perRegion - 4;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Clear $needed levels in ${Catalog.region(region.index - 1).name} '
            'to open ${region.name}.',
          ),
        ),
      );
  }
}

class _RegionCard extends StatelessWidget {
  const _RegionCard({
    required this.region,
    required this.unlocked,
    required this.completed,
    required this.total,
    required this.stars,
    required this.onTap,
  });

  final RegionInfo region;
  final bool unlocked;
  final int completed;
  final int total;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = completed / total;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: Corners.l,
        child: SizedBox(
          height: 190,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                Sprites.background(region.index),
                fit: BoxFit.cover,
                alignment: Alignment.center,
                color: unlocked ? null : Palette.base.withValues(alpha: 0.72),
                colorBlendMode: unlocked ? null : BlendMode.srcATop,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: Palette.surface),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xF20B0A0F), Color(0x660B0A0F)],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: Corners.l,
                  border: Border.all(
                    color: unlocked
                        ? region.accent.withValues(alpha: 0.35)
                        : Palette.hairline,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(Insets.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Insets.s,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: region.accent.withValues(alpha: 0.18),
                            borderRadius: Corners.pill,
                            border: Border.all(
                              color: region.accent.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Text(
                            'REGION ${region.index}',
                            style: AppText.overline.copyWith(
                              color: region.accent,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (!unlocked)
                          const Icon(
                            Icons.lock_rounded,
                            size: 18,
                            color: Palette.textMuted,
                          )
                        else
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 15,
                                color: Palette.gold,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$stars/${total * 3}',
                                style: AppText.label.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(region.name, style: AppText.title),
                    const SizedBox(height: 2),
                    Text(
                      unlocked ? region.tagline : 'Sealed for now',
                      style: AppText.bodyM,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Insets.m),
                    Row(
                      children: [
                        Expanded(
                          child: MeterBar(
                            value: unlocked ? progress : 0,
                            color: region.accent,
                          ),
                        ),
                        const SizedBox(width: Insets.m),
                        Text(
                          '$completed/$total',
                          style: AppText.bodyS.copyWith(
                            color: Palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
