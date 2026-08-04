import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ember_gate.dart';
import 'ember_bg_button.dart';

/// Push-permission promo shown once before the first entry into the portal.
/// Accept → system dialog; Skip → snooze. Both then forward to [onDone].
class NotifyInvitation extends ConsumerStatefulWidget {
  const NotifyInvitation({super.key, required this.onDone});

  /// Called with the result once the user has chosen; the caller opens the
  /// portal afterwards.
  final VoidCallback onDone;

  static const _portraitBg =
      'assets/Cinderforge_Trail_additional_assets/Vertical_Notifications_Screen.webp';
  static const _landscapeBg =
      'assets/Cinderforge_Trail_additional_assets/Horizontal_Notifications_Screen.webp';

  @override
  ConsumerState<NotifyInvitation> createState() => _NotifyInvitationState();
}

class _NotifyInvitationState extends ConsumerState<NotifyInvitation> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _accept() async {
    if (_busy) return;
    setState(() => _busy = true);
    final services = ref.read(emberServicesProvider);
    final granted = await services.signal.requestConsent();
    if (!granted) await services.vault.markPushOsDenied();
    if (mounted) widget.onDone();
  }

  Future<void> _skip() async {
    if (_busy) return;
    setState(() => _busy = true);
    await ref.read(emberServicesProvider).vault.snoozeInvite();
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: OrientationBuilder(
        builder: (context, orientation) {
          final landscape = orientation == Orientation.landscape;
          final size = MediaQuery.sizeOf(context);
          // Landscape lays the two buttons side by side (Allow left, Skip
          // right), so each is narrower; portrait keeps them stacked.
          final buttonWidth = landscape
              ? (size.width * 0.30).clamp(160.0, 300.0)
              : (size.width * 0.72).clamp(240.0, 400.0);
          final allow = EmberBgButton(
            label: 'Allow',
            width: buttonWidth.toDouble(),
            onPressed: _accept,
          );
          final skip = EmberBgButton(
            label: 'Skip',
            width: buttonWidth.toDouble(),
            primary: false,
            onPressed: _skip,
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                landscape
                    ? NotifyInvitation._landscapeBg
                    : NotifyInvitation._portraitBg,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: Color(0xFF0B0A0F)),
              ),
              Align(
                alignment: Alignment(0, landscape ? 0.78 : 0.82),
                child: landscape
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          allow,
                          const SizedBox(width: 16),
                          skip,
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          allow,
                          const SizedBox(height: 12),
                          skip,
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
