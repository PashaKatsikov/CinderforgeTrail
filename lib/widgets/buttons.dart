import 'package:flutter/material.dart';

import '../core/design/app_theme.dart';
import '../core/design/palette.dart';
import '../core/design/typography.dart';

/// Filled ember action. The only strongly coloured control in the app, so it
/// always reads as the single primary choice on a screen.
class EmberButton extends StatefulWidget {
  const EmberButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    this.gradient = Palette.emberGradient,
    this.height,
    this.dense = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final Gradient gradient;
  final double? height;

  /// Shorter variant for buttons that sit inside cards and list rows.
  final bool dense;

  /// Lets a caller grey the button out while keeping the callback wired, so
  /// tapping can still explain why the action is unavailable.
  final bool enabled;

  @override
  State<EmberButton> createState() => _EmberButtonState();
}

class _EmberButtonState extends State<EmberButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && widget.onPressed != null;
    final height = widget.height ?? (widget.dense ? 40 : 54);
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _down = false);
              widget.onPressed!();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: Motion.fast,
        curve: Motion.curve,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Container(
            height: height,
            width: widget.expanded ? double.infinity : null,
            padding: EdgeInsets.symmetric(
              horizontal: widget.dense
                  ? Insets.m
                  : (widget.expanded ? Insets.l : Insets.xl),
            ),
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: Corners.m,
              boxShadow: [
                BoxShadow(
                  color: Palette.emberDeep.withValues(alpha: _down ? 0.18 : 0.38),
                  blurRadius: _down ? 12 : 24,
                  offset: Offset(0, _down ? 3 : 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: widget.dense ? 16 : 20,
                    color: Colors.white,
                  ),
                  SizedBox(width: widget.dense ? Insets.s : Insets.m),
                ],
                Flexible(
                  child: Text(
                    widget.label.toUpperCase(),
                    style: widget.dense
                        ? AppText.button.copyWith(fontSize: 11.5)
                        : AppText.button,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Quiet outlined action for secondary choices.
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    this.tone = Palette.textPrimary,
    this.height = 50,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final Color tone;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.4 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: Corners.m,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          splashColor: tone.withValues(alpha: 0.08),
          child: Container(
            height: height,
            width: expanded ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: Insets.xl),
            decoration: BoxDecoration(
              borderRadius: Corners.m,
              border: Border.all(color: tone.withValues(alpha: 0.28)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: tone),
                  const SizedBox(width: Insets.s),
                ],
                Flexible(
                  child: Text(
                    label.toUpperCase(),
                    style: AppText.button.copyWith(color: tone, fontSize: 12.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular icon control used in headers and the in-game toolbar.
class IconPill extends StatelessWidget {
  const IconPill({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tone = Palette.textPrimary,
    this.badge,
    this.size = 44,
    this.filled = false,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color tone;

  /// Small counter drawn in the corner, e.g. remaining hints.
  final String? badge;
  final double size;
  final bool filled;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Opacity(
      opacity: onPressed == null ? 0.35 : 1,
      child: Material(
        color: filled
            ? tone.withValues(alpha: 0.16)
            : Palette.surface.withValues(alpha: 0.7),
        shape: CircleBorder(
          side: BorderSide(
            color: filled ? tone.withValues(alpha: 0.45) : Palette.hairline,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: size * 0.44, color: tone),
                if (badge != null)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: const BoxDecoration(
                        color: Palette.ember,
                        borderRadius: Corners.pill,
                      ),
                      child: Text(
                        badge!,
                        style: AppText.bodyS.copyWith(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Selectable chip used for filters and segmented choices.
class ChoiceChipPill extends StatelessWidget {
  const ChoiceChipPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.accent = Palette.ember,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Motion.curve,
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.l,
          vertical: Insets.s + 2,
        ),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.16)
              : Palette.surface.withValues(alpha: 0.6),
          borderRadius: Corners.pill,
          border: Border.all(
            color: selected ? accent.withValues(alpha: 0.6) : Palette.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: selected ? accent : Palette.textMuted,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppText.label.copyWith(
                fontSize: 12,
                color: selected ? Palette.textPrimary : Palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
