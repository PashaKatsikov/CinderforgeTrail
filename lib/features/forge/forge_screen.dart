import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/palette.dart';
import '../../core/design/typography.dart';
import '../../core/services/audio_service.dart';
import '../../data/models/profile.dart';
import '../../data/sprites.dart';
import '../../state/app_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/indicators.dart';
import '../../widgets/surfaces.dart';

/// Permanent upgrades bought with embers.
///
/// Rank pips sit on the right of each row so the whole ladder can be read in
/// one vertical sweep, and the currency header stays pinned while scrolling.
class ForgeScreen extends ConsumerWidget {
  const ForgeScreen({super.key});

  static const _icons = {
    Upgrade.emberheart: Icons.favorite_rounded,
    Upgrade.prospector: Icons.local_fire_department_rounded,
    Upgrade.scholar: Icons.school_rounded,
    Upgrade.forgeSense: Icons.lightbulb_rounded,
    Upgrade.cartographer: Icons.route_rounded,
    Upgrade.relicSense: Icons.travel_explore_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final audio = ref.watch(audioProvider);

    return AppScaffold(
      title: 'The Forge',
      subtitle: 'Spend embers on permanent gear',
      padded: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.page),
            child: Panel(
              glow: Palette.ember,
              padding: const EdgeInsets.all(Insets.l),
              child: Row(
                children: [
                  Image.asset(
                    Sprites.mechanism(1),
                    width: 44,
                    height: 44,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.local_fire_department_rounded,
                      color: Palette.ember,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: Insets.l),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('EMBERS AVAILABLE', style: AppText.overline),
                        AnimatedNumber(
                          value: profile.embers,
                          style: AppText.numeral.copyWith(
                            fontSize: 26,
                            color: Palette.ember,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('RANK ${profile.rank}', style: AppText.overline),
                      Text(profile.rankTitle, style: AppText.label),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Insets.l),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                Insets.page,
                0,
                Insets.page,
                Insets.xxl,
              ),
              itemCount: Upgrade.values.length,
              separatorBuilder: (_, _) => const SizedBox(height: Insets.m),
              itemBuilder: (context, index) {
                final upgrade = Upgrade.values[index];
                final rank = profile.upgradeRank(upgrade);
                final maxed = rank >= upgrade.maxRank;
                final cost = maxed ? 0 : upgrade.costAt(rank);
                final affordable = !maxed && profile.embers >= cost;

                return _UpgradeRow(
                  upgrade: upgrade,
                  icon: _icons[upgrade]!,
                  rank: rank,
                  cost: cost,
                  maxed: maxed,
                  affordable: affordable,
                  onBuy: () {
                    if (ref.read(profileProvider.notifier).buyUpgrade(upgrade)) {
                      audio.play(Sfx.reward);
                      audio.buzz(HapticKind.heavy);
                    } else {
                      audio.play(Sfx.error);
                    }
                  },
                ).animate().fadeIn(delay: (index * 45).ms).slideY(begin: 0.06);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeRow extends StatelessWidget {
  const _UpgradeRow({
    required this.upgrade,
    required this.icon,
    required this.rank,
    required this.cost,
    required this.maxed,
    required this.affordable,
    required this.onBuy,
  });

  final Upgrade upgrade;
  final IconData icon;
  final int rank;
  final int cost;
  final bool maxed;
  final bool affordable;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Panel(
      radius: Corners.m,
      padding: const EdgeInsets.all(Insets.l),
      borderColor:
          maxed ? Palette.gold.withValues(alpha: 0.35) : Palette.hairline,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: Corners.s,
                  color: Palette.surfaceTop,
                  border: Border.all(color: Palette.hairlineStrong),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: maxed ? Palette.gold : Palette.ember,
                ),
              ),
              const SizedBox(width: Insets.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(upgrade.label, style: AppText.label),
                    const SizedBox(height: 2),
                    Text(upgrade.description, style: AppText.bodyS),
                  ],
                ),
              ),
              const SizedBox(width: Insets.s),
              Column(
                children: [
                  for (var i = 0; i < upgrade.maxRank; i++)
                    Container(
                      width: 14,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: i < rank
                            ? (maxed ? Palette.gold : Palette.ember)
                            : Palette.hairlineStrong,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Insets.m),
          Row(
            children: [
              Text(
                maxed ? 'MASTERED' : 'RANK $rank / ${upgrade.maxRank}',
                style: AppText.overline.copyWith(
                  color: maxed ? Palette.gold : Palette.textMuted,
                ),
              ),
              const Spacer(),
              if (!maxed)
                SizedBox(
                  width: 132,
                  child: EmberButton(
                    label: '$cost',
                    icon: Icons.local_fire_department_rounded,
                    dense: true,
                    enabled: affordable,
                    onPressed: onBuy,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
