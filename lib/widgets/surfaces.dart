import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/design/app_theme.dart';
import '../core/design/palette.dart';
import '../core/design/typography.dart';

/// Full-bleed artwork with a scrim, used as the base layer of most screens.
class BackdropArt extends StatelessWidget {
  const BackdropArt({
    super.key,
    required this.asset,
    this.alignment = Alignment.center,
    this.opacity = 0.5,
    this.blur = 0,
    this.tint,
  });

  final String asset;
  final Alignment alignment;
  final double opacity;
  final double blur;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      asset,
      fit: BoxFit.cover,
      alignment: alignment,
      opacity: AlwaysStoppedAnimation(opacity),
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
    if (blur > 0) {
      image = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: image,
      );
    }
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: Palette.base, child: image),
          if (tint != null) ColoredBox(color: tint!),
          const DecoratedBox(
            decoration: BoxDecoration(gradient: Palette.scrim),
          ),
        ],
      ),
    );
  }
}

/// The standard container: a dark translucent panel with a hairline edge.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Insets.l),
    this.radius = Corners.l,
    this.color,
    this.borderColor,
    this.gradient,
    this.onTap,
    this.margin,
    this.glow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius radius;
  final Color? color;
  final Color? borderColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  /// Optional accent glow, used to mark the active or featured panel.
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null
            ? (color ?? Palette.surface.withValues(alpha: 0.82))
            : null,
        gradient: gradient,
        borderRadius: radius,
        border: Border.all(color: borderColor ?? Palette.hairline),
        boxShadow: [
          if (glow != null)
            BoxShadow(
              color: glow!.withValues(alpha: 0.22),
              blurRadius: 28,
              spreadRadius: -6,
            ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    final body = onTap == null
        ? content
        : Material(
            color: Colors.transparent,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              splashColor: Palette.ember.withValues(alpha: 0.10),
              highlightColor: Palette.ember.withValues(alpha: 0.05),
              child: content,
            ),
          );

    return margin == null ? body : Padding(padding: margin!, child: body);
  }
}

/// Frosted variant for panels that sit directly on artwork.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Insets.l),
    this.radius = Corners.l,
    this.sigma = 14,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius radius;
  final double sigma;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Panel(
          padding: padding,
          radius: radius,
          color: Colors.white.withValues(alpha: 0.05),
          borderColor: Palette.hairlineStrong,
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
}

/// Small all-caps heading with an optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.label,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: Insets.m),
  });

  final String label;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Text(label.toUpperCase(), style: AppText.overline)),
          ?trailing,
        ],
      ),
    );
  }
}

/// Placeholder for lists and grids that have nothing to show yet.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Palette.surface.withValues(alpha: 0.7),
                border: Border.all(color: Palette.hairline),
              ),
              child: Icon(icon, size: 24, color: Palette.textMuted),
            ),
            const SizedBox(height: Insets.l),
            Text(title, style: AppText.section, textAlign: TextAlign.center),
            const SizedBox(height: Insets.s),
            Text(message, style: AppText.bodyM, textAlign: TextAlign.center),
            if (action != null && onAction != null) ...[
              const SizedBox(height: Insets.l),
              TextButton(
                onPressed: onAction,
                child: Text(
                  action!,
                  style: AppText.label.copyWith(
                    fontSize: 12,
                    color: Palette.ember,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Thin horizontal rule that fades out, used to separate list groups.
class FadedDivider extends StatelessWidget {
  const FadedDivider({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Container(
        height: 1,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Palette.hairlineStrong, Colors.transparent],
          ),
        ),
      ),
    );
  }
}
