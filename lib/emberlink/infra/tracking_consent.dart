import 'dart:async';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/widgets.dart';

import '../core/ember_config.dart';
import '../core/ember_log.dart';

/// Owns the ATT prompt as its own memoized future, separate from the AppsFlyer
/// SDK start (lessons §26): once resolved it is never re-attempted, and the
/// request only fires while the app is frontmost and after the first frame.
class TrackingConsent {
  TrackingConsent();

  Future<TrackingStatus>? _future;

  Future<TrackingStatus> ensure() => _future ??= _request();

  Future<TrackingStatus> _request() async {
    await WidgetsBinding.instance.endOfFrame;
    await Future.delayed(
      const Duration(milliseconds: EmberConfig.attPromptDelayMs),
    );
    await _waitFrontmost();

    var status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      status = await AppTrackingTransparency.requestTrackingAuthorization();
      if (status == TrackingStatus.notDetermined) {
        // Lost while not frontmost — settle and try exactly once more.
        await _waitFrontmost();
        status = await AppTrackingTransparency.requestTrackingAuthorization();
      }
    }
    emberLog(() => '[CFT.att] status $status');
    return status;
  }

  Future<String?> idfaIfAuthorized() async {
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.authorized) {
        final id = await AppTrackingTransparency.getAdvertisingIdentifier();
        if (id.isNotEmpty &&
            id != '00000000-0000-0000-0000-000000000000') {
          return id;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _waitFrontmost() async {
    for (var i = 0; i < 20; i++) {
      final state = WidgetsBinding.instance.lifecycleState;
      // Treat null as frontmost — iOS reports it late on a cold start.
      if (state == null || state == AppLifecycleState.resumed) return;
      await Future.delayed(const Duration(milliseconds: 120));
    }
  }
}
