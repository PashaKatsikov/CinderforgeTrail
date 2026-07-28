import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/palette.dart';
import '../../core/design/typography.dart';
import '../../core/router/routes.dart';
import '../../core/services/audio_service.dart';
import '../../data/models/settings.dart';
import '../../state/app_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/surfaces.dart';

/// Preferences, organised as labelled groups of full-width rows.
///
/// Deliberately the plainest layout in the app: settings are scanned, not
/// explored, so nothing competes with the labels.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final audio = ref.watch(audioProvider);

    void update(AppSettings next, {bool cue = true}) {
      controller.update(next);
      if (cue) audio.play(Sfx.toggleOn);
    }

    return AppScaffold(
      title: 'Settings',
      subtitle: 'Sound, feel and readability',
      child: ListView(
        padding: const EdgeInsets.only(bottom: Insets.xxl),
        children: [
          const SectionHeader(label: 'Audio'),
          Panel(
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.l,
              vertical: Insets.s,
            ),
            child: Column(
              children: [
                _SwitchRow(
                  icon: Icons.volume_up_rounded,
                  title: 'Sound effects',
                  subtitle: 'Taps, forges and level cues',
                  value: settings.soundEnabled,
                  onChanged: (v) =>
                      update(settings.copyWith(soundEnabled: v)),
                ),
                const FadedDivider(indent: 34),
                _SliderRow(
                  icon: Icons.graphic_eq_rounded,
                  title: 'Volume',
                  value: settings.soundVolume,
                  enabled: settings.soundEnabled,
                  onChanged: (v) => controller.update(
                    settings.copyWith(soundVolume: v),
                  ),
                  onChangeEnd: (_) => audio.play(Sfx.confirm),
                ),
                const FadedDivider(indent: 34),
                _SwitchRow(
                  icon: Icons.vibration_rounded,
                  title: 'Haptics',
                  subtitle: 'Short vibration on every step',
                  value: settings.hapticsEnabled,
                  onChanged: (v) =>
                      update(settings.copyWith(hapticsEnabled: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.xl),
          const SectionHeader(label: 'Controls'),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: Insets.s,
                  runSpacing: Insets.s,
                  children: [
                    for (final scheme in ControlScheme.values)
                      ChoiceChipPill(
                        label: scheme.label,
                        selected: settings.controls == scheme,
                        onTap: () =>
                            update(settings.copyWith(controls: scheme)),
                      ),
                  ],
                ),
                const SizedBox(height: Insets.m),
                Text(settings.controls.description, style: AppText.bodyS),
              ],
            ),
          ),
          const SizedBox(height: Insets.xl),
          const SectionHeader(label: 'Board'),
          Panel(
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.l,
              vertical: Insets.s,
            ),
            child: Column(
              children: [
                _SwitchRow(
                  icon: Icons.timer_outlined,
                  title: 'Cooling countdown',
                  subtitle: 'Show moves left before each stage changes',
                  value: settings.showTrailTimers,
                  onChanged: (v) =>
                      update(settings.copyWith(showTrailTimers: v)),
                ),
                const FadedDivider(indent: 34),
                _SwitchRow(
                  icon: Icons.grid_4x4_rounded,
                  title: 'Tile outlines',
                  subtitle: 'Faint guides around walkable ground',
                  value: settings.showGridGuides,
                  onChanged: (v) =>
                      update(settings.copyWith(showGridGuides: v)),
                ),
                const FadedDivider(indent: 34),
                _SliderRow(
                  icon: Icons.zoom_out_map_rounded,
                  title: 'Board size',
                  value: (settings.boardScale - 0.8) / 0.4,
                  onChanged: (v) => controller.update(
                    settings.copyWith(boardScale: 0.8 + v * 0.4),
                  ),
                  onChangeEnd: (_) => audio.play(Sfx.confirm),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.xl),
          const SectionHeader(label: 'Accessibility'),
          Panel(
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.l,
              vertical: Insets.s,
            ),
            child: Column(
              children: [
                _SwitchRow(
                  icon: Icons.motion_photos_off_rounded,
                  title: 'Reduce motion',
                  subtitle: 'Stop ambient glow and floating pickups',
                  value: settings.reduceMotion,
                  onChanged: (v) =>
                      update(settings.copyWith(reduceMotion: v)),
                ),
                const FadedDivider(indent: 34),
                _SwitchRow(
                  icon: Icons.help_outline_rounded,
                  title: 'Confirm restart',
                  subtitle: 'Ask before wiping the current route',
                  value: settings.confirmRestart,
                  onChanged: (v) =>
                      update(settings.copyWith(confirmRestart: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.xl),
          const SectionHeader(label: 'Legal'),
          Panel(
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.l,
              vertical: Insets.s,
            ),
            child: Column(
              children: [
                _LinkRow(
                  icon: Icons.privacy_tip_rounded,
                  title: 'Privacy Policy',
                  onTap: () => context.push(Routes.privacy),
                ),
                const FadedDivider(indent: 34),
                _LinkRow(
                  icon: Icons.support_agent_rounded,
                  title: 'Support',
                  onTap: () => context.push(Routes.support),
                ),
                const FadedDivider(indent: 34),
                _LinkRow(
                  icon: Icons.info_outline_rounded,
                  title: 'About this game',
                  onTap: () => context.push(Routes.about),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.xl),
          GhostButton(
            label: 'Reset all progress',
            icon: Icons.restart_alt_rounded,
            tone: Palette.danger,
            onPressed: () => _confirmReset(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Palette.surfaceHigh,
        shape: const RoundedRectangleBorder(borderRadius: Corners.l),
        title: Text('Erase progress?', style: AppText.section),
        content: Text(
          'Every star, relic and upgrade will be lost. This cannot be undone.',
          style: AppText.bodyM,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Erase', style: TextStyle(color: Palette.danger)),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      ref.read(profileProvider.notifier).resetProgress();
      ref.read(audioProvider).play(Sfx.confirm);
    }
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.s),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Palette.textSecondary),
          const SizedBox(width: Insets.l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppText.label),
                const SizedBox(height: 2),
                Text(subtitle, style: AppText.bodyS),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Insets.s),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Palette.textSecondary),
            const SizedBox(width: Insets.l),
            SizedBox(width: 88, child: Text(title, style: AppText.label)),
            Expanded(
              child: Slider(
                value: value.clamp(0.0, 1.0),
                onChanged: enabled ? onChanged : null,
                onChangeEnd: onChangeEnd,
              ),
            ),
            SizedBox(
              width: 38,
              child: Text(
                '${(value.clamp(0.0, 1.0) * 100).round()}',
                style: AppText.bodyS,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Insets.m),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Palette.textSecondary),
            const SizedBox(width: Insets.l),
            Expanded(child: Text(title, style: AppText.label)),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Palette.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
