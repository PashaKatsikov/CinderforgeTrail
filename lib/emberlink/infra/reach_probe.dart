import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity checks for the boot pipeline.
///
/// Two independent checks kept separate on purpose (see gray_flow_lessons §2):
/// * [isOffline] — instantaneous OS verdict. When true, go straight to the
///   offline screen; never run a DNS probe first (it hangs for seconds while
///   offline and the WebView paints its own error page meanwhile).
/// * [canReach] — an actual DNS lookup, used only to distinguish a transient
///   WebView load error from a real outage.
class ReachProbe {
  const ReachProbe();

  // Rotated per project — not the usual cloudflare.com.
  static const List<String> _hosts = ['apple.com', 'cinderforgetrail.com'];

  Future<bool> isOffline() async {
    final results = await Connectivity().checkConnectivity();
    return results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);
  }

  /// Live connectivity changes from the OS. The portal listens to this so it
  /// can show the offline screen the instant every interface drops — without
  /// waiting for a WebView load error (which only surfaces on the next tap).
  Stream<List<ConnectivityResult>> get changes =>
      Connectivity().onConnectivityChanged;

  static bool allDown(List<ConnectivityResult> states) =>
      states.isEmpty || states.every((r) => r == ConnectivityResult.none);

  Future<bool> canReach() async {
    // Probe both hosts in PARALLEL under one cap. Sequential 4s-per-host
    // lookups made a no-WAN launch sit ~7-8s; running them together caps the
    // wait. The window must still be generous enough that a COLD DNS right
    // after Wi-Fi reconnects (the Retry case) resolves in time — a too-tight
    // cap reported a false offline the moment the network came back.
    Future<bool> lookup(String host) => InternetAddress.lookup(host)
        .then((r) => r.isNotEmpty && r.first.rawAddress.isNotEmpty)
        .catchError((_) => false);
    try {
      final results = await Future.wait(_hosts.map(lookup)).timeout(
        const Duration(milliseconds: 3500),
        onTimeout: () => const [false],
      );
      return results.any((ok) => ok);
    } catch (_) {
      return false;
    }
  }
}
