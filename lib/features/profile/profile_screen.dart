import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/palette.dart';
import '../../core/design/typography.dart';
import '../../core/router/routes.dart';
import '../../data/catalog.dart';
import '../../data/models/profile.dart';
import '../../data/sprites.dart';
import '../../game/logic/level_generator.dart';
import '../../state/app_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/avatar_picker.dart';
import '../../widgets/buttons.dart';
import '../../widgets/indicators.dart';
import '../../widgets/surfaces.dart';

/// Identity card for the player: rank, walker, and a compact summary of
/// everything earned so far.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final character = Catalog.characters.firstWhere(
      (c) => c.sprite == profile.selectedCharacter,
      orElse: () => Catalog.characters.first,
    );

    return AppScaffold(
      title: 'Walker Profile',
      subtitle: profile.rankTitle,
      child: ListView(
        padding: const EdgeInsets.only(bottom: Insets.xxl),
        children: [
          _IdentityCard(profile: profile, characterSprite: character.sprite)
              .animate()
              .fadeIn()
              .slideY(begin: 0.06),
          const SizedBox(height: Insets.xl),
          const SectionHeader(label: 'Standing'),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  value: '${profile.levelsCompleted}',
                  total: '${LevelGenerator.totalLevels}',
                  label: 'Levels',
                  color: Palette.ember,
                ),
              ),
              const SizedBox(width: Insets.m),
              Expanded(
                child: _Metric(
                  value: '${profile.totalStars}',
                  total: '${LevelGenerator.totalLevels * 3}',
                  label: 'Stars',
                  color: Palette.gold,
                ),
              ),
              const SizedBox(width: Insets.m),
              Expanded(
                child: _Metric(
                  value: '${profile.relicsFound.length}',
                  total: '${Catalog.relics.length}',
                  label: 'Relics',
                  color: Palette.arcane,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 120.ms),
          const SizedBox(height: Insets.xl),
          const SectionHeader(label: 'Loadout'),
          Panel(
            child: Column(
              children: [
                for (final upgrade in Upgrade.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Insets.s),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(upgrade.label, style: AppText.bodyM),
                        ),
                        for (var i = 0; i < upgrade.maxRank; i++)
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < profile.upgradeRank(upgrade)
                                  ? Palette.ember
                                  : Palette.hairlineStrong,
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: Insets.s),
                GhostButton(
                  label: 'Open the Forge',
                  icon: Icons.hardware_rounded,
                  onPressed: () => context.push(Routes.forge),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 180.ms),
          const SizedBox(height: Insets.xl),
          const SectionHeader(label: 'Journey'),
          Panel(
            child: Column(
              children: [
                DetailRow(
                  label: 'Current walker',
                  value: character.name,
                  icon: Icons.hiking_rounded,
                ),
                DetailRow(
                  label: 'Rank',
                  value: '${profile.rank} · ${profile.rankTitle}',
                  icon: Icons.military_tech_rounded,
                ),
                DetailRow(
                  label: 'Experience',
                  value: '${profile.xp}',
                  icon: Icons.trending_up_rounded,
                ),
                DetailRow(
                  label: 'Embers held',
                  value: '${profile.embers}',
                  valueColor: Palette.ember,
                  icon: Icons.local_fire_department_rounded,
                ),
                DetailRow(
                  label: 'Daily streak',
                  value: '${profile.streakDays} days',
                  icon: Icons.calendar_month_rounded,
                ),
                DetailRow(
                  label: 'Win rate',
                  value: '${(profile.winRate * 100).round()}%',
                  icon: Icons.percent_rounded,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 240.ms),
          const SizedBox(height: Insets.xl),
          Row(
            children: [
              Expanded(
                child: GhostButton(
                  label: 'Walkers',
                  icon: Icons.people_alt_rounded,
                  onPressed: () => context.push(Routes.characters),
                ),
              ),
              const SizedBox(width: Insets.m),
              Expanded(
                child: GhostButton(
                  label: 'Records',
                  icon: Icons.leaderboard_rounded,
                  onPressed: () => context.push(Routes.records),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.profile, required this.characterSprite});

  final PlayerProfile profile;
  final int characterSprite;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: EdgeInsets.zero,
      glow: Palette.ember,
      child: ClipRRect(
        borderRadius: Corners.l,
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.22,
                child: Image.asset(
                  Sprites.background(profile.rank),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Insets.l),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Аватар — фото или инициалы, с кнопкой изменения
                  AvatarPicker(
                    size: 82,
                    initials: profile.rankTitle
                        .split(' ')
                        .take(2)
                        .map((w) => w.isEmpty ? '' : w[0])
                        .join(),
                  ),
                  const SizedBox(width: Insets.l),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('RANK ${profile.rank}', style: AppText.overline),
                        Text(profile.rankTitle, style: AppText.section),
                        const SizedBox(height: Insets.s),
                        // Спрайт персонажа под ником
                        SizedBox(
                          height: 46,
                          child: Image.asset(
                            Sprites.character(characterSprite),
                            fit: BoxFit.contain,
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                        const SizedBox(height: Insets.s),
                        MeterBar(
                          value: profile.rankProgress,
                          color: Palette.gold,
                          height: 5,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${profile.xpInRank} / 500 XP',
                          style: AppText.bodyS,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.total,
    required this.label,
    required this.color,
  });

  final String value;
  final String total;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Panel(
      radius: Corners.m,
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.s,
        vertical: Insets.l,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppText.numeral.copyWith(fontSize: 22, color: color),
          ),
          Text('of $total', style: AppText.bodyS.copyWith(fontSize: 10)),
          const SizedBox(height: 6),
          Text(label.toUpperCase(), style: AppText.overline),
        ],
      ),
    );
  }
}
