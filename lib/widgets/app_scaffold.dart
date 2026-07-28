import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/design/app_theme.dart';
import '../core/design/palette.dart';
import '../core/design/typography.dart';
import 'buttons.dart';
import 'surfaces.dart';

/// Shared page chrome: artwork backdrop, a slim header, and a scrolling or
/// fixed body. Every screen uses it so navigation feels like one place.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.backdrop,
    this.backdropAlignment = Alignment.center,
    this.backdropOpacity = 0.32,
    this.backdropBlur = 3,
    this.actions = const [],
    this.showBack = true,
    this.onBack,
    this.bottomBar,
    this.padded = true,
    this.floating,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final String? backdrop;
  final Alignment backdropAlignment;
  final double backdropOpacity;
  final double backdropBlur;
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? bottomBar;
  final bool padded;
  final Widget? floating;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlay,
      child: Scaffold(
        body: Stack(
          children: [
            if (backdrop != null)
              BackdropArt(
                asset: backdrop!,
                alignment: backdropAlignment,
                opacity: backdropOpacity,
                blur: backdropBlur,
              )
            else
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.75),
                      radius: 1.15,
                      colors: [Color(0xFF1A1220), Palette.base],
                    ),
                  ),
                ),
              ),
            SafeArea(
              child: Column(
                children: [
                  _Header(
                    title: title,
                    subtitle: subtitle,
                    actions: actions,
                    showBack: showBack,
                    onBack: onBack,
                  ),
                  Expanded(
                    child: padded
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Insets.page,
                            ),
                            child: child,
                          )
                        : child,
                  ),
                  if (bottomBar != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Insets.page,
                        Insets.m,
                        Insets.page,
                        Insets.m,
                      ),
                      child: bottomBar!,
                    ),
                ],
              ),
            ),
            ?floating,
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.showBack,
    required this.onBack,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Insets.page - 4,
        Insets.m,
        Insets.page - 4,
        Insets.l,
      ),
      child: Row(
        children: [
          if (showBack)
            IconPill(
              icon: Icons.arrow_back_rounded,
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              size: 40,
            )
          else
            const SizedBox(width: 4),
          const SizedBox(width: Insets.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppText.section,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: AppText.bodyS,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          for (final action in actions)
            Padding(
              padding: const EdgeInsets.only(left: Insets.s),
              child: action,
            ),
        ],
      ),
    );
  }
}