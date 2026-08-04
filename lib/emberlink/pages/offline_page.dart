import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../infra/reach_probe.dart';
import 'ember_bg_button.dart';

/// No-internet screen. Retry does NOT blindly re-run the pipeline: it first
/// confirms reachability on THIS screen (spinner on the button). Only once the
/// network is actually back does it invoke [onRetry] — which re-runs the whole
/// boot (ATT prompt → config → white/gray). If still offline it stays put and
/// shows a hint, so the user never sees a loading screen flash back to nowifi
/// (mirrors EggRunnerAdventure's EmptyAirPage). Rotatable.
class OfflinePage extends StatefulWidget {
  const OfflinePage({super.key, required this.onRetry});

  /// Runs only after connectivity is confirmed. Never patches state in place —
  /// it hands off to a fresh boot / a fresh WebView load.
  final VoidCallback onRetry;

  static const _portraitBg =
      'assets/Cinderforge_Trail_additional_assets/Vertical_Nowifi_Screen.webp';
  static const _landscapeBg =
      'assets/Cinderforge_Trail_additional_assets/Horizontal_Nowifi_Screen.webp';

  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<OfflinePage> {
  bool _checking = false;
  bool _stillOffline = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _retry() async {
    if (_checking) return;
    HapticFeedback.lightImpact();
    setState(() {
      _checking = true;
      _stillOffline = false;
    });
    bool online = false;
    try {
      online = await const ReachProbe().canReach();
    } catch (_) {
      online = false;
    }
    if (!mounted) return;
    if (online) {
      // Hand off to a fresh boot pass while still showing this screen — the
      // caller replaces the route, so no nowifi flash.
      widget.onRetry();
      return;
    }
    setState(() {
      _checking = false;
      _stillOffline = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: OrientationBuilder(
        builder: (context, orientation) {
          final landscape = orientation == Orientation.landscape;
          final size = MediaQuery.sizeOf(context);
          final width = landscape
              ? size.width * 0.35
              : (size.width * 0.70).clamp(220.0, 380.0);
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                landscape ? OfflinePage._landscapeBg : OfflinePage._portraitBg,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: Color(0xFF0B0A0F)),
              ),
              Align(
                // Landscape: no SafeArea, centered horizontally so the notch
                // inset does not skew the button.
                alignment: Alignment(0, landscape ? 0.72 : 0.80),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EmberBgButton(
                      label: 'Retry',
                      width: width.toDouble(),
                      busy: _checking,
                      onPressed: _retry,
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      child: _stillOffline
                          ? const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Text(
                                'No connection yet',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  shadows: [
                                    Shadow(color: Colors.black, blurRadius: 5),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
