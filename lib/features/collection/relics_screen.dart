import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/palette.dart';
import '../../core/design/typography.dart';
import '../../core/services/audio_service.dart';
import '../../data/catalog.dart';
import '../../data/sprites.dart';
import '../../state/app_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/indicators.dart';
import '../../widgets/surfaces.dart';

/// Relic vault, presented as an uneven mosaic so the collection feels like a
/// display case rather than a spreadsheet.
class RelicsScreen extends ConsumerWidget {
  const RelicsScreen({super.key});

  static const _rarityColors = {
    'Common': Palette.textSecondary,
    'Rare': Palette.ice,
    'Epic': Palette.arcane,
    'Legendary': Palette.gold,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final found = profile.relicsFound;

    return AppScaffold(
      title: 'Relic Vault',
      subtitle: '${found.length} of ${Catalog.relics.length} recovered',
      padded: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.page),
            sliver: SliverToBoxAdapter(
              child: Panel(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Vault progress', style: AppText.section),
                          const SizedBox(height: Insets.s),
                          MeterBar(
                            value: found.length / Catalog.relics.length,
                            color: Palette.arcane,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Insets.l),
                    Text(
                      '${(found.length / Catalog.relics.length * 100).round()}%',
                      style: AppText.numeral.copyWith(color: Palette.arcane),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Insets.l)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Insets.page,
              0,
              Insets.page,
              Insets.xxl,
            ),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: Insets.m,
              crossAxisSpacing: Insets.m,
              childCount: Catalog.relics.length,
              itemBuilder: (context, index) {
                final relic = Catalog.relics[index];
                final owned = found.contains(relic.sprite);
                return _RelicCard(
                  relic: relic,
                  owned: owned,
                  // Alternating heights break the grid into a mosaic.
                  tall: index % 3 == 0,
                  onTap: () {
                    ref.read(audioProvider).play(Sfx.popup);
                    _showDetail(context, relic, owned);
                  },
                )
                    .animate()
                    .fadeIn(delay: (index * 22).ms, duration: 240.ms)
                    .scale(begin: const Offset(0.95, 0.95));
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, RelicInfo relic, bool owned) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Palette.void0.withValues(alpha: 0.7),
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(Insets.page),
          child: GlassPanel(
            padding: const EdgeInsets.all(Insets.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 120,
                  child: owned
                      ? Image.asset(Sprites.relic(relic.sprite))
                      : const Icon(
                          Icons.help_outline_rounded,
                          size: 60,
                          color: Palette.textMuted,
                        ),
                ),
                const SizedBox(height: Insets.l),
                Text(
                  owned ? relic.name : 'Unrecovered',
                  style: AppText.title,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Insets.s),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Insets.m,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: Corners.pill,
                    border: Border.all(
                      color: (_rarityColors[relic.rarity] ?? Palette.textMuted)
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    relic.rarity.toUpperCase(),
                    style: AppText.overline.copyWith(
                      color: _rarityColors[relic.rarity],
                    ),
                  ),
                ),
                const SizedBox(height: Insets.l),
                Text(
                  owned
                      ? relic.lore
                      : 'Clear more levels to bring this one home.',
                  style: AppText.bodyM,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RelicCard extends StatelessWidget {
  const _RelicCard({
    required this.relic,
    required this.owned,
    required this.tall,
    required this.onTap,
  });

  final RelicInfo relic;
  final bool owned;
  final bool tall;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent =
        RelicsScreen._rarityColors[relic.rarity] ?? Palette.textMuted;
    return Panel(
      onTap: onTap,
      radius: Corners.m,
      padding: const EdgeInsets.all(Insets.m),
      borderColor: owned ? accent.withValues(alpha: 0.35) : Palette.hairline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: tall ? 108 : 78,
            width: double.infinity,
            child: owned
                ? Image.asset(Sprites.relic(relic.sprite), fit: BoxFit.contain)
                : Center(
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 22,
                      color: Palette.textMuted.withValues(alpha: 0.6),
                    ),
                  ),
          ),
          const SizedBox(height: Insets.s),
          Text(
            owned ? relic.name : '???',
            style: AppText.label.copyWith(
              fontSize: 12.5,
              color: owned ? Palette.textPrimary : Palette.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            relic.rarity.toUpperCase(),
            style: AppText.overline.copyWith(
              color: owned ? accent : Palette.textMuted,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
