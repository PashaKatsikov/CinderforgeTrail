import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/palette.dart';
import '../../core/design/typography.dart';
import '../../data/catalog.dart';
import '../../data/models/profile.dart';
import '../../state/app_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/indicators.dart';
import '../../widgets/surfaces.dart';

enum _Filter { all, unlocked, locked }

/// Achievements as a filterable list of wide rows, each led by a progress
/// ring. The ring makes partial progress legible without reading numbers.
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() =>
      _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final all = Catalog.achievements;
    final unlocked = all.where((a) => profile.achievements.contains(a.id));

    final visible = switch (_filter) {
      _Filter.all => all,
      _Filter.unlocked =>
        all.where((a) => profile.achievements.contains(a.id)).toList(),
      _Filter.locked =>
        all.where((a) => !profile.achievements.contains(a.id)).toList(),
    };

    return AppScaffold(
      title: 'Achievements',
      subtitle: '${unlocked.length} of ${all.length} earned',
      padded: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.page),
            child: Panel(
              padding: const EdgeInsets.all(Insets.l),
              child: Row(
                children: [
                  ProgressRing(
                    value: unlocked.length / all.length,
                    size: 56,
                    color: Palette.gold,
                    child: Text(
                      '${(unlocked.length / all.length * 100).round()}%',
                      style: AppText.label.copyWith(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: Insets.l),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Trophy case', style: AppText.section),
                        const SizedBox(height: 4),
                        Text(
                          'Every achievement pays out embers you can spend '
                          'in the Forge.',
                          style: AppText.bodyS,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Insets.l),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Insets.page),
              children: [
                for (final filter in _Filter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: Insets.s),
                    child: ChoiceChipPill(
                      label: switch (filter) {
                        _Filter.all => 'All',
                        _Filter.unlocked => 'Earned',
                        _Filter.locked => 'In progress',
                      },
                      selected: _filter == filter,
                      accent: Palette.gold,
                      onTap: () => setState(() => _filter = filter),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Insets.m),
          Expanded(
            child: visible.isEmpty
                ? const EmptyState(
                    icon: Icons.emoji_events_outlined,
                    title: 'Nothing here yet',
                    message: 'Walk a few more levels and come back.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      Insets.page,
                      Insets.s,
                      Insets.page,
                      Insets.xxl,
                    ),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: Insets.m),
                    itemBuilder: (context, index) => _AchievementRow(
                      info: visible[index],
                      profile: profile,
                    )
                        .animate()
                        .fadeIn(delay: (index * 26).ms, duration: 240.ms)
                        .slideX(begin: 0.05),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.info, required this.profile});

  final AchievementInfo info;
  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final done = profile.achievements.contains(info.id);
    final value = info.progress(profile).clamp(0, info.target);
    final ratio = value / info.target;

    return Panel(
      radius: Corners.m,
      padding: const EdgeInsets.all(Insets.m),
      borderColor:
          done ? Palette.gold.withValues(alpha: 0.4) : Palette.hairline,
      child: Row(
        children: [
          ProgressRing(
            value: done ? 1 : ratio,
            size: 46,
            stroke: 4,
            color: done ? Palette.gold : Palette.ember,
            child: Icon(
              info.icon,
              size: 18,
              color: done ? Palette.gold : Palette.textSecondary,
            ),
          ),
          const SizedBox(width: Insets.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(info.name, style: AppText.label)),
                    if (done)
                      const Icon(
                        Icons.verified_rounded,
                        size: 15,
                        color: Palette.gold,
                      )
                    else
                      Text('$value/${info.target}', style: AppText.bodyS),
                  ],
                ),
                const SizedBox(height: 3),
                Text(info.description, style: AppText.bodyS, maxLines: 2),
                const SizedBox(height: Insets.s),
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 12,
                      color: Palette.ember,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${info.reward}',
                      style: AppText.bodyS.copyWith(color: Palette.ember),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
