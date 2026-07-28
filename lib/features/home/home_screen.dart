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
import '../../widgets/avatar_picker.dart';
import '../../widgets/buttons.dart';
import '../../widgets/indicators.dart';
import '../../widgets/surfaces.dart';

/// Landing screen: identity, the single most important action, and a compact
/// index of everything else. Laid out as one vertical scroll so the hero art
/// can breathe above a dense menu grid.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final nextLevel = ref.watch(nextLevelProvider);
    final audio = ref.watch(audioProvider);
    final level = LevelGenerator.byId(nextLevel);
    final region = Catalog.region(level.region);
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: [
          BackdropArt(
            asset: Sprites.background(level.region),
            opacity: 0.42,
            blur: 2,
            alignment: Alignment.topCenter,
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                    child: _TopBar(
                      embers: profile.embers,
                      rank: profile.rank,
                      rankTitle: profile.rankTitle,
                    onProfile: () {
                      audio.tap();
                      context.push(Routes.profile);
                    },
                    onSettings: () {
                      audio.tap();
                      context.push(Routes.settings);
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: size.height * 0.24,
                    child: Center(
                      child: Image.asset(
                        Sprites.logo,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) =>
                            Text('CINDERFORGE', style: AppText.hero),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(begin: const Offset(0.92, 0.92), curve: Motion.curve),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    Insets.page,
                    Insets.s,
                    Insets.page,
                    Insets.xxl,
                  ),
                  sliver: SliverList.list(
                    children: [
                      _ContinueCard(
                        regionName: region.name,
                        levelLabel:
                            'Region ${level.region} · Level ${level.indexInRegion}',
                        accent: region.accent,
                        onPlay: () {
                          audio.play(Sfx.levelStart);
                          context.push(Routes.gameOf(nextLevel));
                        },
                      ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.12),
                      const SizedBox(height: Insets.m),
                      Row(
                        children: [
                          Expanded(
                            child: GhostButton(
                              label: 'Trail Map',
                              icon: Icons.map_rounded,
                              onPressed: () {
                                audio.tap();
                                context.push(Routes.regions);
                              },
                            ),
                          ),
                          const SizedBox(width: Insets.m),
                          Expanded(
                            child: GhostButton(
                              label: 'Daily',
                              icon: Icons.today_rounded,
                              tone: Palette.gold,
                              onPressed: () {
                                audio.tap();
                                context.push(Routes.quests);
                              },
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: Insets.xl),
                      _ProgressStrip(
                        levels: profile.levelsCompleted,
                        stars: profile.totalStars,
                        relics: profile.relicsFound.length,
                        streak: profile.streakDays,
                      ).animate().fadeIn(delay: 260.ms),
                      const SizedBox(height: Insets.xl),
                      const SectionHeader(label: 'Journal'),
                      _MenuGrid(audio: audio),
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.embers,
    required this.rank,
    required this.rankTitle,
    required this.onProfile,
    required this.onSettings,
  });

  final int embers;
  final int rank;
  final String rankTitle;
  final VoidCallback onProfile;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Insets.page,
        Insets.m,
        Insets.page,
        Insets.s,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onProfile,
            child: Row(
              children: [
                // Аватар — кликабельный, без отдельной кнопки редактирования
                AvatarPicker(
                  size: 38,
                  initials: rankTitle
                      .split(' ')
                      .take(2)
                      .map((w) => w.isEmpty ? '' : w[0])
                      .join(),
                ),
                const SizedBox(width: Insets.s),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('RANK $rank', style: AppText.overline),
                    Text(rankTitle, style: AppText.bodyM),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.m,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Palette.surface.withValues(alpha: 0.75),
              borderRadius: Corners.pill,
              border: Border.all(color: Palette.hairline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 15,
                  color: Palette.ember,
                ),
                const SizedBox(width: 6),
                AnimatedNumber(
                  value: embers,
                  style: AppText.label.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: Insets.s),
          IconPill(
            icon: Icons.tune_rounded,
            onPressed: onSettings,
            size: 40,
          ),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.regionName,
    required this.levelLabel,
    required this.accent,
    required this.onPlay,
  });

  final String regionName;
  final String levelLabel;
  final Color accent;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Panel(
      glow: accent,
      padding: const EdgeInsets.all(Insets.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: Insets.s),
              Text(levelLabel.toUpperCase(), style: AppText.overline),
            ],
          ),
          const SizedBox(height: Insets.s),
          Text(regionName, style: AppText.title),
          const SizedBox(height: Insets.l),
          EmberButton(
            label: 'Continue the trail',
            icon: Icons.play_arrow_rounded,
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({
    required this.levels,
    required this.stars,
    required this.relics,
    required this.streak,
  });

  final int levels;
  final int stars;
  final int relics;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('$levels', 'Levels', Icons.flag_rounded, Palette.ember),
      ('$stars', 'Stars', Icons.star_rounded, Palette.gold),
      ('$relics', 'Relics', Icons.diamond_rounded, Palette.arcane),
      ('$streak', 'Streak', Icons.bolt_rounded, Palette.success),
    ];
    return Panel(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.l,
        vertical: Insets.l,
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(
              child: StatTile(
                value: items[i].$1,
                label: items[i].$2,
                icon: items[i].$3,
                accent: items[i].$4,
                compact: true,
              ),
            ),
            if (i != items.length - 1)
              Container(width: 1, height: 40, color: Palette.hairline),
          ],
        ],
      ),
    );
  }
}

class _MenuGrid extends StatelessWidget {
  const _MenuGrid({required this.audio});

  final AudioService audio;

  static const _entries = <({String label, IconData icon, String route, Color tone})>[
    (
      label: 'Achievements',
      icon: Icons.emoji_events_rounded,
      route: Routes.achievements,
      tone: Palette.gold
    ),
    (
      label: 'Statistics',
      icon: Icons.insights_rounded,
      route: Routes.statistics,
      tone: Palette.ice
    ),
    (
      label: 'Relics',
      icon: Icons.diamond_rounded,
      route: Routes.relics,
      tone: Palette.arcane
    ),
    (
      label: 'Bestiary',
      icon: Icons.pets_rounded,
      route: Routes.bestiary,
      tone: Palette.cinder
    ),
    (
      label: 'Forge',
      icon: Icons.handyman_rounded,
      route: Routes.forge,
      tone: Palette.ember
    ),
    (
      label: 'Walkers',
      icon: Icons.person_rounded,
      route: Routes.characters,
      tone: Palette.metal
    ),
    (
      label: 'Codex',
      icon: Icons.menu_book_rounded,
      route: Routes.codex,
      tone: Palette.textSecondary
    ),
    (
      label: 'Records',
      icon: Icons.leaderboard_rounded,
      route: Routes.records,
      tone: Palette.success
    ),
    (
      label: 'Weather',
      icon: Icons.storm_rounded,
      route: Routes.weather,
      tone: Palette.ice
    ),
    (
      label: 'How to play',
      icon: Icons.school_rounded,
      route: Routes.howToPlay,
      tone: Palette.textSecondary
    ),
    (
      label: 'Support',
      icon: Icons.support_agent_rounded,
      route: Routes.support,
      tone: Palette.textSecondary
    ),
    (
      label: 'Privacy',
      icon: Icons.privacy_tip_rounded,
      route: Routes.privacy,
      tone: Palette.textSecondary
    ),
    (
      label: 'About',
      icon: Icons.info_rounded,
      route: Routes.about,
      tone: Palette.textSecondary
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: Insets.m,
        crossAxisSpacing: Insets.m,
        childAspectRatio: 1.02,
      ),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return Panel(
          padding: const EdgeInsets.all(Insets.m),
          radius: Corners.m,
          onTap: () {
            audio.tap();
            context.push(entry.route);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(entry.icon, size: 20, color: entry.tone),
              Text(
                entry.label,
                style: AppText.bodyM.copyWith(
                  color: Palette.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: (300 + index * 35).ms, duration: 260.ms)
            .slideY(begin: 0.15, curve: Motion.curve);
      },
    );
  }
}
