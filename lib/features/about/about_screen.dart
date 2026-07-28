import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/palette.dart';
import '../../core/design/typography.dart';
import '../../core/router/routes.dart';
import '../../data/catalog.dart';
import '../../data/sprites.dart';
import '../../game/logic/level_generator.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/indicators.dart';
import '../../widgets/surfaces.dart';

/// Credits, build information and links to the legal documents.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '1.0.0';
  String _build = '1';

  @override
  void initState() {
    super.initState();
    _readPackageInfo();
  }

  Future<void> _readPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _version = info.version;
        _build = info.buildNumber;
      });
    } on Exception {
      // Falls back to the defaults above; nothing here is load-bearing.
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'About',
      subtitle: 'Build, credits and legal',
      child: ListView(
        padding: const EdgeInsets.only(bottom: Insets.xxl),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    borderRadius: Corners.l,
                    border: Border.all(color: Palette.hairlineStrong),
                    boxShadow: [
                      BoxShadow(
                        color: Palette.emberDeep.withValues(alpha: 0.28),
                        blurRadius: 26,
                        spreadRadius: -6,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(Sprites.icon, fit: BoxFit.cover),
                ),
                const SizedBox(height: Insets.l),
                Text('Cinderforge Trail', style: AppText.title),
                const SizedBox(height: 2),
                Text('One touch. One trail. One way out.',
                    style: AppText.bodyM),
              ],
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.94, 0.94)),
          const SizedBox(height: Insets.xl),
          const SectionHeader(label: 'Build'),
          Panel(
            child: Column(
              children: [
                DetailRow(
                  label: 'Version',
                  value: '$_version ($_build)',
                  icon: Icons.tag_rounded,
                ),
                DetailRow(
                  label: 'Bundle ID',
                  value: 'com.cinderforge.trailgame',
                  icon: Icons.badge_outlined,
                ),
                DetailRow(
                  label: 'App ID',
                  value: '6792827359',
                  icon: Icons.numbers_rounded,
                ),
                DetailRow(
                  label: 'Plays offline',
                  value: 'Yes, entirely',
                  valueColor: Palette.success,
                  icon: Icons.wifi_off_rounded,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: Insets.xl),
          const SectionHeader(label: 'Contents'),
          Panel(
            child: Column(
              children: [
                DetailRow(
                  label: 'Levels',
                  value: '${LevelGenerator.totalLevels}',
                  icon: Icons.grid_view_rounded,
                ),
                DetailRow(
                  label: 'Regions',
                  value: '${Catalog.regions.length}',
                  icon: Icons.terrain_rounded,
                ),
                DetailRow(
                  label: 'Relics',
                  value: '${Catalog.relics.length}',
                  icon: Icons.diamond_rounded,
                ),
                DetailRow(
                  label: 'Creatures',
                  value: '${Catalog.creatures.length}',
                  icon: Icons.pets_rounded,
                ),
                DetailRow(
                  label: 'Achievements',
                  value: '${Catalog.achievements.length}',
                  icon: Icons.emoji_events_rounded,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 160.ms),
          const SizedBox(height: Insets.xl),
          const SectionHeader(label: 'Legal'),
          Row(
            children: [
              Expanded(
                child: GhostButton(
                  label: 'Privacy Policy',
                  icon: Icons.privacy_tip_rounded,
                  onPressed: () => context.push(Routes.privacy),
                ),
              ),
              const SizedBox(width: Insets.m),
              Expanded(
                child: GhostButton(
                  label: 'Support',
                  icon: Icons.support_agent_rounded,
                  onPressed: () => context.push(Routes.support),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 220.ms),
          const SizedBox(height: Insets.xl),
          Panel(
            color: Palette.surface.withValues(alpha: 0.6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Credits', style: AppText.label),
                const SizedBox(height: Insets.s),
                Text(
                  'Design, code and art direction by the Cinderforge Trail team. '
                  'Typeset in Cinzel and Manrope, both bundled with the app so '
                  'the game never needs a connection.',
                  style: AppText.bodyS,
                ),
                const SizedBox(height: Insets.m),
                Text(
                  '© 2026 Cinderforge Trail. All rights reserved.',
                  style: AppText.bodyS.copyWith(color: Palette.textMuted),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 280.ms),
        ],
      ),
    );
  }
}
