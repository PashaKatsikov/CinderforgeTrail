import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/palette.dart';
import '../../core/design/typography.dart';
import '../../data/catalog.dart';
import '../../data/sprites.dart';
import '../../state/app_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/surfaces.dart';

/// Creature codex as a swipeable card deck.
///
/// One creature fills the screen at a time so its artwork can be shown at a
/// size that does it justice, which no grid on this device could manage.
class BestiaryScreen extends ConsumerStatefulWidget {
  const BestiaryScreen({super.key});

  @override
  ConsumerState<BestiaryScreen> createState() => _BestiaryScreenState();
}

class _BestiaryScreenState extends ConsumerState<BestiaryScreen> {
  late final PageController _controller =
      PageController(viewportFraction: 0.82);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final creatures = Catalog.creatures;
    final known = profile.creaturesFound;

    return AppScaffold(
      title: 'Bestiary',
      subtitle: '${known.length} of ${creatures.length} recorded',
      padded: false,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: creatures.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, index) {
                final creature = creatures[index];
                final discovered = known.contains(creature.sprite);
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    var delta = 0.0;
                    if (_controller.position.haveDimensions) {
                      delta = (_controller.page ?? 0) - index;
                    } else {
                      delta = (_page - index).toDouble();
                    }
                    final scale = (1 - delta.abs() * 0.10).clamp(0.86, 1.0);
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Insets.s,
                      vertical: Insets.m,
                    ),
                    child: _CreatureCard(
                      creature: creature,
                      discovered: discovered,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: Insets.l, top: Insets.s),
            child: SmoothPageIndicator(
              controller: _controller,
              count: creatures.length,
              effect: const ExpandingDotsEffect(
                dotHeight: 5,
                dotWidth: 5,
                expansionFactor: 4,
                spacing: 5,
                activeDotColor: Palette.ember,
                dotColor: Palette.hairlineStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatureCard extends StatelessWidget {
  const _CreatureCard({required this.creature, required this.discovered});

  final CreatureInfo creature;
  final bool discovered;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.all(Insets.l),
      glow: discovered ? Palette.cinder : null,
      child: Column(
        children: [
          Expanded(
            child: discovered
                ? Image.asset(
                    Sprites.creature(creature.sprite),
                    fit: BoxFit.contain,
                  )
                    .animate(
                      onPlay: (c) => c.repeat(reverse: true),
                    )
                    .moveY(begin: -5, end: 5, duration: 2600.ms)
                : Center(
                    child: Icon(
                      Icons.visibility_off_outlined,
                      size: 54,
                      color: Palette.textMuted.withValues(alpha: 0.5),
                    ),
                  ),
          ),
          const SizedBox(height: Insets.l),
          Text(
            discovered ? creature.name : 'Unrecorded',
            style: AppText.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            discovered ? creature.habitat.toUpperCase() : 'KEEP WALKING',
            style: AppText.overline.copyWith(color: Palette.cinder),
          ),
          const SizedBox(height: Insets.l),
          const FadedDivider(),
          const SizedBox(height: Insets.m),
          Text(
            discovered
                ? creature.behaviour
                : 'This one has not crossed your path yet.',
            style: AppText.bodyM,
            textAlign: TextAlign.center,
            maxLines: 4,
          ),
          const SizedBox(height: Insets.m),
          if (discovered)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Trait(label: 'Habitat', value: creature.habitat),
                Container(width: 1, height: 26, color: Palette.hairline),
                _Trait(label: 'Entry', value: '#${creature.sprite}'),
              ],
            ),
        ],
      ),
    );
  }
}

class _Trait extends StatelessWidget {
  const _Trait({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: AppText.overline),
        const SizedBox(height: 2),
        Text(value, style: AppText.label.copyWith(fontSize: 12)),
      ],
    );
  }
}
