import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/palette.dart';
import '../../core/design/typography.dart';
import '../../core/router/routes.dart';
import '../../widgets/buttons.dart';
import '../../widgets/surfaces.dart';

enum PauseAction { resume, restart, quit }

/// Mid-run menu. Kept as a sheet rather than a page so the board stays
/// visible behind it and the player does not lose their bearings.
Future<PauseAction?> showPauseSheet(BuildContext context) {
  return showModalBottomSheet<PauseAction>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Palette.void0.withValues(alpha: 0.72),
    isScrollControlled: true,
    builder: (context) => const _PauseSheet(),
  );
}

class _PauseSheet extends StatelessWidget {
  const _PauseSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(Insets.page),
        child: GlassPanel(
          padding: const EdgeInsets.all(Insets.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Palette.hairlineStrong,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: Insets.xl),
              Text('Paused', style: AppText.title, textAlign: TextAlign.center),
              const SizedBox(height: Insets.s),
              Text(
                'The trail keeps its heat while you think.',
                style: AppText.bodyM,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Insets.xl),
              EmberButton(
                label: 'Resume',
                icon: Icons.play_arrow_rounded,
                onPressed: () => Navigator.pop(context, PauseAction.resume),
              ),
              const SizedBox(height: Insets.m),
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      label: 'Restart',
                      icon: Icons.refresh_rounded,
                      onPressed: () =>
                          Navigator.pop(context, PauseAction.restart),
                    ),
                  ),
                  const SizedBox(width: Insets.m),
                  Expanded(
                    child: GhostButton(
                      label: 'Codex',
                      icon: Icons.menu_book_rounded,
                      onPressed: () {
                        Navigator.pop(context, PauseAction.resume);
                        context.push(Routes.codex);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Insets.m),
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      label: 'Settings',
                      icon: Icons.tune_rounded,
                      onPressed: () {
                        Navigator.pop(context, PauseAction.resume);
                        context.push(Routes.settings);
                      },
                    ),
                  ),
                  const SizedBox(width: Insets.m),
                  Expanded(
                    child: GhostButton(
                      label: 'Quit',
                      icon: Icons.logout_rounded,
                      tone: Palette.danger,
                      onPressed: () => Navigator.pop(context, PauseAction.quit),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
