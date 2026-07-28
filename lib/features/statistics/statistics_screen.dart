import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/palette.dart';
import '../../core/design/typography.dart';
import '../../data/catalog.dart';
import '../../data/models/profile.dart';
import '../../game/logic/level_generator.dart';
import '../../state/app_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/indicators.dart';
import '../../widgets/surfaces.dart';

/// Data-led screen: charts first, raw numbers second.
///
/// It is the only place in the app that leans on charts, which keeps it
/// visually distinct from the card and list screens around it.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    const perRegion = LevelGenerator.levelsPerRegion;

    return AppScaffold(
      title: 'Statistics',
      subtitle: 'Everything the trail remembers',
      child: ListView(
        padding: const EdgeInsets.only(bottom: Insets.xxl),
        children: [
          _Headline(profile: profile),
          const SizedBox(height: Insets.xl),
          const SectionHeader(label: 'Stars by region'),
          Panel(
            padding: const EdgeInsets.fromLTRB(
              Insets.m,
              Insets.xl,
              Insets.l,
              Insets.m,
            ),
            child: SizedBox(
              height: 168,
              child: _RegionBars(profile: profile, perRegion: perRegion),
            ),
          ).animate().fadeIn(delay: 80.ms),
          const SizedBox(height: Insets.xl),
          const SectionHeader(label: 'Mechanisms used'),
          Panel(
            padding: const EdgeInsets.all(Insets.l),
            child: SizedBox(
              height: 180,
              child: _MechanismRadar(profile: profile),
            ),
          ).animate().fadeIn(delay: 140.ms),
          const SizedBox(height: Insets.xl),
          const SectionHeader(label: 'Collections'),
          Panel(
            child: Column(
              children: [
                _CollectionBar(
                  label: 'Relics recovered',
                  value: profile.relicsFound.length,
                  total: Catalog.relics.length,
                  color: Palette.arcane,
                ),
                const SizedBox(height: Insets.m),
                _CollectionBar(
                  label: 'Creatures recorded',
                  value: profile.creaturesFound.length,
                  total: Catalog.creatures.length,
                  color: Palette.cinder,
                ),
                const SizedBox(height: Insets.m),
                _CollectionBar(
                  label: 'Achievements earned',
                  value: profile.achievements.length,
                  total: Catalog.achievements.length,
                  color: Palette.gold,
                ),
                const SizedBox(height: Insets.m),
                _CollectionBar(
                  label: 'Levels cleared',
                  value: profile.levelsCompleted,
                  total: LevelGenerator.totalLevels,
                  color: Palette.ember,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: Insets.xl),
          const SectionHeader(label: 'Raw numbers'),
          Panel(
            child: Column(
              children: [
                DetailRow(
                  label: 'Runs started',
                  value: '${profile.totalRuns}',
                  icon: Icons.play_arrow_rounded,
                ),
                DetailRow(
                  label: 'Runs won',
                  value: '${profile.totalWins}',
                  icon: Icons.check_rounded,
                ),
                DetailRow(
                  label: 'Win rate',
                  value: '${(profile.winRate * 100).round()}%',
                  valueColor: Palette.success,
                  icon: Icons.percent_rounded,
                ),
                DetailRow(
                  label: 'Steps taken',
                  value: '${profile.totalMoves}',
                  icon: Icons.directions_walk_rounded,
                ),
                DetailRow(
                  label: 'Restarts',
                  value: '${profile.totalRestarts}',
                  icon: Icons.refresh_rounded,
                ),
                DetailRow(
                  label: 'Undos',
                  value: '${profile.undosUsed}',
                  icon: Icons.undo_rounded,
                ),
                DetailRow(
                  label: 'Hints used',
                  value: '${profile.hintsUsed}',
                  icon: Icons.lightbulb_outline_rounded,
                ),
                DetailRow(
                  label: 'Time on the trail',
                  value: _formatDuration(profile.playSeconds),
                  icon: Icons.schedule_rounded,
                ),
                DetailRow(
                  label: 'Longest streak',
                  value: '${profile.streakDays} days',
                  icon: Icons.bolt_rounded,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 260.ms),
        ],
      ),
    );
  }

  static String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Panel(
            padding: const EdgeInsets.all(Insets.l),
            child: StatTile(
              value: '${profile.totalStars}',
              label: 'Stars earned',
              icon: Icons.star_rounded,
              accent: Palette.gold,
            ),
          ),
        ),
        const SizedBox(width: Insets.m),
        Expanded(
          child: Panel(
            padding: const EdgeInsets.all(Insets.l),
            child: StatTile(
              value: '${profile.crystalsFound}',
              label: 'Shards found',
              icon: Icons.hexagon_rounded,
              accent: Palette.ice,
            ),
          ),
        ),
      ],
    );
  }
}

class _RegionBars extends StatelessWidget {
  const _RegionBars({required this.profile, required this.perRegion});

  final PlayerProfile profile;
  final int perRegion;

  @override
  Widget build(BuildContext context) {
    final maxStars = (perRegion * 3).toDouble();
    return BarChart(
      BarChartData(
        maxY: maxStars,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxStars / 3,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: Palette.hairline,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: maxStars / 3,
              getTitlesWidget: (value, _) => Text(
                '${value.round()}',
                style: AppText.bodyS.copyWith(fontSize: 9),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (value, _) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'R${value.round() + 1}',
                  style: AppText.overline.copyWith(fontSize: 8.5),
                ),
              ),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < Catalog.regions.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: profile
                      .starsInRegion(i + 1, perRegion)
                      .toDouble()
                      .clamp(0, maxStars),
                  width: 12,
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Catalog.regions[i].accent.withValues(alpha: 0.45),
                      Catalog.regions[i].accent,
                    ],
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxStars,
                    color: Palette.surfaceTop.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MechanismRadar extends StatelessWidget {
  const _MechanismRadar({required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final values = <double>[
      profile.iceMelted.toDouble(),
      profile.growthBurned.toDouble(),
      profile.gatesPassed.toDouble(),
      profile.golemSteps.toDouble(),
      profile.forgesLit.toDouble(),
    ];
    final peak = values.fold<double>(1, (a, b) => b > a ? b : a);

    return RadarChart(
      RadarChartData(
        radarShape: RadarShape.polygon,
        radarBackgroundColor: Colors.transparent,
        radarBorderData: const BorderSide(color: Palette.hairline),
        gridBorderData: const BorderSide(color: Palette.hairline),
        tickBorderData: const BorderSide(color: Colors.transparent),
        ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 1),
        tickCount: 3,
        titlePositionPercentageOffset: 0.16,
        getTitle: (index, _) => RadarChartTitle(
          text: switch (index) {
            0 => 'Ice',
            1 => 'Growth',
            2 => 'Gates',
            3 => 'Golems',
            _ => 'Forges',
          },
        ),
        titleTextStyle: AppText.overline.copyWith(fontSize: 9),
        dataSets: [
          RadarDataSet(
            fillColor: Palette.ember.withValues(alpha: 0.22),
            borderColor: Palette.ember,
            borderWidth: 2,
            entryRadius: 2.5,
            dataEntries: [
              for (final v in values) RadarEntry(value: v / peak * 100),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollectionBar extends StatelessWidget {
  const _CollectionBar({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: AppText.bodyM)),
            Text(
              '$value / $total',
              style: AppText.label.copyWith(fontSize: 12, color: color),
            ),
          ],
        ),
        const SizedBox(height: Insets.s),
        MeterBar(value: total == 0 ? 0 : value / total, color: color, height: 5),
      ],
    );
  }
}
