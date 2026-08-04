import 'package:flutter/material.dart';

/// A large, legible gradient button used by the gray-flow foreground screens.
/// Labels use `height: 1.0` + centered alignment so there is no baseline drift.
class EmberBgButton extends StatelessWidget {
  const EmberBgButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width,
    this.primary = true,
    this.busy = false,
  });

  final String label;
  final VoidCallback onPressed;
  final double? width;
  final bool primary;

  /// When true the button shows a spinner and ignores taps — used while the
  /// offline screen confirms reachability before it re-runs the pipeline.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final gradient = primary
        ? const LinearGradient(colors: [Color(0xFFFF7A2C), Color(0xFFE0451C)])
        : const LinearGradient(colors: [Color(0xFF6C4A38), Color(0xFF4A2E22)]);
    return SizedBox(
      width: width,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x66000000), blurRadius: 14, offset: Offset(0, 6)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: busy ? null : onPressed,
            child: Center(
              child: busy
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
