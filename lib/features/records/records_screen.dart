import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/palette.dart';
import '../../core/design/typography.dart';
import '../../core/router/routes.dart';
import '../../data/catalog.dart';
import '../../game/logic/level_generator.dart';
import '../../state/app_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/indicators.dart';
import '../../widgets/surfaces.dart';

enum _Sort { best, worst, recent }

/// Personal bests, sorted like a leaderboard.
///
/// Rows are dense and numeric on purpose: this screen is for comparing runs,
/// so anything decorative would get in the way.
class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  _Sort _sort = _Sort.best;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final entries = profile.bestMoves.entries.toList();

    // "Best" ranks by how far under par the run finished, so a tight run on a
    // small level does not automatically outrank a long, efficient one.
    int margin(int id) => LevelGenerator.byId(id).parMoves - profile.bestMoves[id]!;

    switch (_sort) {
      case _Sort.best:
        entries.sort((a, b) => margin(b.key).compareTo(margin(a.key)));
      case _Sort.worst:
        entries.sort((a, b) => margin(a.key).compareTo(margin(b.key)));
      case _Sort.recent:
        entries.sort((a, b) => b.key.compareTo(a.key));
    }

    final atPar = entries.where((e) => margin(e.key) >= 0).length;

    return AppScaffold(
      title: 'Records',
      subtitle: '$atPar runs finished at or under par',
      padded: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.page),
            child: Row(
              children: [
                for (final sort in _Sort.values)
                  Padding(
                    padding: const EdgeInsets.only(right: Insets.s),
                    child: ChoiceChipPill(
                      label: switch (sort) {
                        _Sort.best => 'Sharpest',
                        _Sort.worst => 'Needs work',
                        _Sort.recent => 'Latest',
                      },
                      selected: _sort == sort,
                      onTap: () => setState(() => _sort = sort),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Insets.m),
          Expanded(
            child: entries.isEmpty
                ? EmptyState(
                    icon: Icons.leaderboard_outlined,
                    title: 'No records yet',
                    message: 'Finish a level and your best route lands here.',
                    action: 'Open the trail map',
                    onAction: () => context.push(Routes.regions),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      Insets.page,
                      Insets.s,
                      Insets.page,
                      Insets.xxl,
                    ),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: Insets.s),
                    itemBuilder: (context, index) {
                      final id = entries[index].key;
                      final moves = entries[index].value;
                      final level = LevelGenerator.byId(id);
                      final info = Catalog.region(level.region);
                      final delta = level.parMoves - moves;

                      return _RecordRow(
                        place: index + 1,
                        title: 'R${level.region} · Level ${level.indexInRegion}',
                        region: info.name,
                        accent: info.accent,
                        moves: moves,
                        par: level.parMoves,
                        delta: delta,
                        stars: profile.stars[id] ?? 0,
                        onTap: () => context.push(Routes.gameOf(id)),
                      )
                          .animate()
                          .fadeIn(delay: (index * 20).ms, duration: 220.ms);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.place,
    required this.title,
    required this.region,
    required this.accent,
    required this.moves,
    required this.par,
    required this.delta,
    required this.stars,
    required this.onTap,
  });

  final int place;
  final String title;
  final String region;
  final Color accent;
  final int moves;
  final int par;
  final int delta;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final medal = switch (place) {
      1 => Palette.gold,
      2 => const Color(0xFFC9CBD4),
      3 => const Color(0xFFC08457),
      _ => Palette.textMuted,
    };

    return Panel(
      onTap: onTap,
      radius: Corners.m,
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.m,
        vertical: Insets.m,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '$place',
              style: AppText.numeral.copyWith(fontSize: 15, color: medal),
            ),
          ),
          Container(width: 1, height: 30, color: Palette.hairline),
          const SizedBox(width: Insets.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppText.label.copyWith(fontSize: 13)),
                Text(
                  region.toUpperCase(),
                  style: AppText.overline.copyWith(color: accent, fontSize: 8.5),
                ),
              ],
            ),
          ),
          StarRow(stars: stars, size: 12),
          const SizedBox(width: Insets.m),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$moves',
                style: AppText.numeral.copyWith(fontSize: 15),
              ),
              Text(
                delta >= 0 ? '$delta under par' : '${-delta} over',
                style: AppText.overline.copyWith(
                  color: delta >= 0 ? Palette.success : Palette.danger,
                  fontSize: 8.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
