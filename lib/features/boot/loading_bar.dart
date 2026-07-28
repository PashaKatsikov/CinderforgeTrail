import 'package:flutter/material.dart';

import '../../core/design/palette.dart';
import '../../core/design/typography.dart';

/// The loading bar shown on the splash screen.
///
/// It fills strictly left to right and is driven by the same value that the
/// percentage label reads, so the two can never disagree.
class ForgeProgressBar extends StatelessWidget {
  const ForgeProgressBar({
    super.key,
    required this.value,
    required this.width,
    required this.height,
  });

  final double value;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final radius = BorderRadius.circular(height);

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xCC0A0810),
          borderRadius: radius,
          border: Border.all(color: const Color(0x33FFB347), width: 1),
          boxShadow: const [
            BoxShadow(color: Color(0x66000000), blurRadius: 10, spreadRadius: 1),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(height * 0.18),
          child: ClipRRect(
            borderRadius: radius,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: clamped,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFFB6300A),
                        Color(0xFFFF6B2C),
                        Color(0xFFFFC46B),
                      ],
                      stops: [0, 0.6, 1],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Palette.ember.withValues(alpha: 0.55),
                        blurRadius: height * 0.9,
                      ),
                    ],
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: FractionallySizedBox(
                      heightFactor: 0.42,
                      widthFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.32),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Loading" followed by dots that cycle without shifting the text.
class LoadingWordmark extends StatefulWidget {
  const LoadingWordmark({super.key, required this.fontSize});

  final double fontSize;

  @override
  State<LoadingWordmark> createState() => _LoadingWordmarkState();
}

class _LoadingWordmarkState extends State<LoadingWordmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: AppFonts.display,
      fontSize: widget.fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: widget.fontSize * 0.22,
      color: Palette.textPrimary,
      shadows: const [
        Shadow(color: Color(0xCC000000), blurRadius: 12, offset: Offset(0, 2)),
        Shadow(color: Color(0x66FF6B2C), blurRadius: 22),
      ],
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('LOADING', style: style),
        // Reserved width keeps the wordmark from jumping as dots appear.
        SizedBox(
          width: widget.fontSize * 1.5,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final count = (_controller.value * 4).floor().clamp(0, 3);
              return Text('.' * count, style: style, maxLines: 1);
            },
          ),
        ),
      ],
    );
  }
}
