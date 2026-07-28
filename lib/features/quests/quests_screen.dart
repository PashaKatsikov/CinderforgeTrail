import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/palette.dart';
import '../../core/design/typography.dart';
import '../../core/services/audio_service.dart';
import '../../data/daily_quests.dart';
import '../../state/app_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/indicators.dart';
import '../../widgets/surfaces.dart';

/// Daily objectives, drawn as a vertical timeline.
///
/// The connecting rail makes the three quests read as one day's work instead
/// of three unrelated cards.
class QuestsScreen extends ConsumerWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(dailyQuestsProvider);
    final profile = ref.watch(profileProvider);
    final audio = ref.watch(audioProvider);
    final remaining = _untilReset();

    return AppScaffold(
      title: 'Daily Trials',
      subtitle: 'Resets in $remaining',
      child: ListView(
        padding: const EdgeInsets.only(bottom: Insets.xxl),
        children: [
          Panel(
            glow: Palette.gold,
            child: Row(
              children: [
                ProgressRing(
                  value: (profile.streakDays % 7) / 7,
                  size: 58,
                  color: Palette.gold,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${profile.streakDays}',
                        style: AppText.numeral.copyWith(fontSize: 17),
                      ),
                      Text('DAYS', style: AppText.overline.copyWith(fontSize: 7)),
                    ],
                  ),
                ),
                const SizedBox(width: Insets.l),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Walking streak', style: AppText.section),
                      const SizedBox(height: 4),
                      Text(
                        'Come back every day to keep the forge lit. '
                        'Seven days in a row doubles tomorrow\'s payout.',
                        style: AppText.bodyS,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.xl),
          const SectionHeader(label: 'Today'),
          for (var i = 0; i < entries.length; i++)
            _QuestNode(
              quest: entries[i].quest,
              progress: entries[i].progress,
              claimed: entries[i].claimed,
              isLast: i == entries.length - 1,
              onClaim: () {
                if (ref.read(profileProvider.notifier).claimQuest(i)) {
                  audio.play(Sfx.reward);
                  audio.buzz(HapticKind.medium);
                }
              },
            ).animate().fadeIn(delay: (i * 90).ms).slideX(begin: 0.06),
          const SizedBox(height: Insets.xl),
          Panel(
            color: Palette.surface.withValues(alpha: 0.6),
            child: Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: Palette.ember,
                  size: 18,
                ),
                const SizedBox(width: Insets.m),
                Expanded(
                  child: Text(
                    'Embers from trials can be spent in the Forge on permanent '
                    'upgrades.',
                    style: AppText.bodyS,
                  ),
                ),
                Text(
                  '${profile.embers}',
                  style: AppText.numeral.copyWith(
                    fontSize: 16,
                    color: Palette.ember,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _untilReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final left = tomorrow.difference(now);
    return '${left.inHours}h ${left.inMinutes % 60}m';
  }
}

class _QuestNode extends StatelessWidget {
  const _QuestNode({
    required this.quest,
    required this.progress,
    required this.claimed,
    required this.isLast,
    required this.onClaim,
  });

  final DailyQuest quest;
  final int progress;
  final bool claimed;
  final bool isLast;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final done = progress >= quest.target;
    final color = claimed
        ? Palette.success
        : (done ? Palette.gold : Palette.ember);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? color.withValues(alpha: 0.22)
                        : Palette.surfaceTop,
                    border: Border.all(color: color, width: 1.4),
                  ),
                  child: claimed
                      ? const Icon(Icons.check_rounded,
                          size: 12, color: Palette.success)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Palette.hairlineStrong,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : Insets.m),
              child: Panel(
                radius: Corners.m,
                padding: const EdgeInsets.all(Insets.l),
                borderColor: done
                    ? color.withValues(alpha: 0.4)
                    : Palette.hairline,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(quest.icon, size: 15, color: color),
                        const SizedBox(width: Insets.s),
                        Expanded(child: Text(quest.title, style: AppText.label)),
                        Text(
                          '+${quest.reward}',
                          style: AppText.label.copyWith(
                            fontSize: 12,
                            color: Palette.ember,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(quest.description, style: AppText.bodyS),
                    const SizedBox(height: Insets.m),
                    Row(
                      children: [
                        Expanded(
                          child: MeterBar(
                            value: (progress / quest.target).clamp(0.0, 1.0),
                            color: color,
                            height: 5,
                          ),
                        ),
                        const SizedBox(width: Insets.m),
                        Text(
                          '${progress.clamp(0, quest.target)}/${quest.target}',
                          style: AppText.bodyS,
                        ),
                      ],
                    ),
                    if (done && !claimed) ...[
                      const SizedBox(height: Insets.m),
                      EmberButton(
                        label: 'Collect ${quest.reward} embers',
                        icon: Icons.redeem_rounded,
                        dense: true,
                        onPressed: onClaim,
                      ),
                    ],
                    if (claimed) ...[
                      const SizedBox(height: Insets.s),
                      Text(
                        'Collected',
                        style: AppText.overline
                            .copyWith(color: Palette.success),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
