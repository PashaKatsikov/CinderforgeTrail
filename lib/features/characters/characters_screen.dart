import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/palette.dart';
import '../../core/design/typography.dart';
import '../../core/services/audio_service.dart';
import '../../data/catalog.dart';
import '../../data/sprites.dart';
import '../../state/app_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/surfaces.dart';

/// Walker selection: a large stage above a horizontal filmstrip.
///
/// The split lets the chosen figure stay big while the alternatives remain a
/// single thumb-swipe away.
class CharactersScreen extends ConsumerStatefulWidget {
  const CharactersScreen({super.key});

  @override
  ConsumerState<CharactersScreen> createState() => _CharactersScreenState();
}

class _CharactersScreenState extends ConsumerState<CharactersScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    final selected = ref.read(profileProvider).selectedCharacter;
    _index = Catalog.characters.indexWhere((c) => c.sprite == selected);
    if (_index < 0) _index = 0;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final audio = ref.watch(audioProvider);
    final character = Catalog.characters[_index];
    final unlocked = profile.levelsCompleted >= character.unlockAt;
    final selected = profile.selectedCharacter == character.sprite;

    return AppScaffold(
      title: 'Walkers',
      subtitle: 'Choose who carries the heat',
      padded: false,
      child: Column(
        children: [
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.page),
              child: Panel(
                padding: const EdgeInsets.all(Insets.l),
                glow: unlocked ? Palette.ember : null,
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Palette.ember.withValues(alpha: 0.16),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          Image.asset(
                            Sprites.character(character.sprite),
                            key: ValueKey(character.sprite),
                            fit: BoxFit.contain,
                            color: unlocked ? null : Palette.void0,
                            colorBlendMode: unlocked ? null : BlendMode.srcATop,
                          )
                              .animate(key: ValueKey(character.sprite))
                              .fadeIn(duration: 260.ms)
                              .scale(begin: const Offset(0.9, 0.9)),
                        ],
                      ),
                    ),
                    const SizedBox(height: Insets.m),
                    Text(
                      unlocked ? character.name : 'Locked',
                      style: AppText.title,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      character.title.toUpperCase(),
                      style: AppText.overline.copyWith(color: Palette.ember),
                    ),
                    const SizedBox(height: Insets.m),
                    Text(
                      unlocked
                          ? character.lore
                          : 'Clear ${character.unlockAt} levels to wake this '
                              'walker.',
                      style: AppText.bodyM,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: Insets.l),
          SizedBox(
            height: 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Insets.page),
              itemCount: Catalog.characters.length,
              separatorBuilder: (_, _) => const SizedBox(width: Insets.s),
              itemBuilder: (context, index) {
                final item = Catalog.characters[index];
                final open = profile.levelsCompleted >= item.unlockAt;
                final active = index == _index;
                return GestureDetector(
                  onTap: () {
                    audio.tap();
                    setState(() => _index = index);
                  },
                  child: AnimatedContainer(
                    duration: Motion.fast,
                    width: 74,
                    decoration: BoxDecoration(
                      borderRadius: Corners.m,
                      color: Palette.surface.withValues(alpha: 0.8),
                      border: Border.all(
                        color: active
                            ? Palette.ember.withValues(alpha: 0.6)
                            : Palette.hairline,
                        width: active ? 1.4 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(Insets.s),
                    child: Opacity(
                      opacity: open ? 1 : 0.4,
                      child: Column(
                        children: [
                          Expanded(
                            child: Image.asset(
                              Sprites.character(item.sprite),
                              fit: BoxFit.contain,
                            ),
                          ),
                          if (!open)
                            const Icon(
                              Icons.lock_rounded,
                              size: 11,
                              color: Palette.textMuted,
                            )
                          else if (profile.selectedCharacter == item.sprite)
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 11,
                              color: Palette.success,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Insets.page),
            child: EmberButton(
              label: selected
                  ? 'Currently walking'
                  : (unlocked ? 'Send ${character.name}' : 'Locked'),
              icon: selected
                  ? Icons.check_rounded
                  : (unlocked ? Icons.hiking_rounded : Icons.lock_rounded),
              enabled: unlocked && !selected,
              onPressed: () {
                ref
                    .read(profileProvider.notifier)
                    .selectCharacter(character.sprite);
                audio.play(Sfx.confirm);
              },
            ),
          ),
        ],
      ),
    );
  }
}
