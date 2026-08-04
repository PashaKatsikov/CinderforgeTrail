import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'core/ember_config.dart';
import 'core/ember_log.dart';
import 'infra/beacon_exchange.dart';
import 'infra/cold_tap_reader.dart';
import 'infra/ember_vault.dart';
import 'infra/reach_probe.dart';
import 'infra/signal_hub.dart';
import 'infra/tracking_consent.dart';
import 'infra/trail_attribution.dart';
import 'models/beacon_reply.dart';
import 'models/trail_destination.dart';
import 'models/trail_route.dart';

/// The routing brain. `decide()` is idempotent: it de-dupes only *concurrent*
/// calls and clears its cache on completion, so a later Retry re-runs the whole
/// pipeline (lessons §3).
class TrailCoordinator {
  TrailCoordinator({
    required EmberVault vault,
    required ReachProbe probe,
    required TrailAttribution attribution,
    required SignalHub signal,
    required TrackingConsent consent,
    required BeaconExchange exchange,
    ColdTapReader cold = const ColdTapReader(),
  }) {
    _vault = vault;
    _probe = probe;
    _attr = attribution;
    _signal = signal;
    _consent = consent;
    _exchange = exchange;
    _cold = cold;
  }

  late final EmberVault _vault;
  late final ReachProbe _probe;
  late final TrailAttribution _attr;
  late final SignalHub _signal;
  late final TrackingConsent _consent;
  late final BeaconExchange _exchange;
  late final ColdTapReader _cold;

  Future<TrailDestination>? _inflight;

  String get _locale {
    final l = PlatformDispatcher.instance.locale;
    final region = l.countryCode;
    return (region == null || region.isEmpty)
        ? l.languageCode
        : '${l.languageCode}_$region';
  }

  Future<TrailDestination> decide() =>
      _inflight ??= _run().whenComplete(() => _inflight = null);

  Future<TrailDestination> _run() async {
    // 0 — cold-start push tap wins over everything (all modes).
    final coldUrl = await _cold.consume();
    if (coldUrl != null) {
      await _vault.writeMode(RouteMode.portal);
      await _vault.saveDestination(coldUrl);
      unawaited(_warmAttributionSilently());
      return PortalTrail(coldUrl, coldStart: true);
    }

    final mode = _vault.readMode();
    final offline = await _probe.isOffline();

    switch (mode) {
      case RouteMode.native:
        if (offline) return const NativeTrail();
        return _recoverFromNative();
      case RouteMode.portal:
        return _returningPortal(offline);
      case RouteMode.fresh:
        return _firstDecision(offline);
    }
  }

  // ── First launch ───────────────────────────────────────────────────────
  Future<TrailDestination> _firstDecision(bool offline) async {
    // No connectivity → offline screen, stay fresh so a later online launch can
    // still reach the portal. We only leave `fresh` once the network is real.
    if (offline) return const OfflineTrail();
    if (!await _probe.canReach()) return const OfflineTrail();

    // Network is confirmed. From here the outcome is ALWAYS white or gray —
    // never back to offline (matches EggRunnerAdventure's _firstDecision, and
    // the required UX: Retry → loading + ATT → config → white/gray).
    final reply = await _runPipeline();
    if (reply.granted) {
      await _commitPortal(reply);
      return _inviteOrPortal(reply.destination!);
    }
    // No granted URL (organic → 404, or a server hiccup): commit the game. This
    // is not a dead end — a returning-native launch re-checks config and can
    // still convert to the portal later.
    await _vault.writeMode(RouteMode.native);
    return const NativeTrail();
  }

  // ── Returning, was portal ───────────────────────────────────────────────
  Future<TrailDestination> _returningPortal(bool offline) async {
    // A push tapped while the app was killed/backgrounded (delivered via
    // Firebase's warm-start path, not SceneDelegate) is stashed — open it now.
    final pending = await _vault.consumePushUrl();
    if (pending != null) {
      await _vault.writeMode(RouteMode.portal);
      return PortalTrail(pending);
    }

    // The saved URL is a FALLBACK only — never a short-circuit. When online we
    // ALWAYS re-run the config pipeline so a URL the operator changed in the
    // config takes effect on the very next launch. (The template returns a
    // non-expired cached URL here without asking the server, which is exactly
    // the "old link keeps opening" bug seen in sibling apps — do not re-add it.)
    final saved = await _vault.readSavedDestination();
    if (offline) {
      return saved != null ? PortalTrail(saved) : const OfflineTrail();
    }
    if (!await _probe.canReach()) {
      return saved != null ? PortalTrail(saved) : const OfflineTrail();
    }

    final reply = await _runPipeline();
    if (reply.granted) {
      // Fresh URL from config wins and is persisted for the offline fallback.
      await _commitPortal(reply);
      return PortalTrail(reply.destination!);
    }
    // Config gave nothing this launch: fall back to the last known URL so a
    // paying user is not stranded, else offline.
    if (saved != null) return PortalTrail(saved);
    return const OfflineTrail();
  }

  // ── Returning, was native (re-conversion allowed) ───────────────────────
  Future<TrailDestination> _recoverFromNative() async {
    if (!await _probe.canReach()) return const NativeTrail();
    final reply = await _runPipeline();
    if (reply.granted) {
      await _commitPortal(reply);
      return _inviteOrPortal(reply.destination!);
    }
    return const NativeTrail();
  }

  // ── Shared pipeline ──────────────────────────────────────────────────────
  Future<BeaconReply> _runPipeline() async {
    // Consent is its own memoized future; APNs warms in parallel, not ahead.
    unawaited(_consent.ensure());
    await _signal.bootstrap(onToken: _onTokenReady);
    await _attr.start();
    await _attr.awaitSignals(timeout: EmberConfig.awaitSignalsTimeout);

    final token = await _signal.awaitToken();
    final idfa = await _consent.idfaIfAuthorized();
    return _exchange.send(
      _attr.buildPayload(locale: _locale, pushToken: token, idfa: idfa),
    );
  }

  Future<void> _commitPortal(BeaconReply reply) async {
    await _vault.writeMode(RouteMode.portal);
    await _vault.saveDestination(
      reply.destination!,
      expiresAt: reply.expiresAt,
    );
  }

  TrailDestination _inviteOrPortal(String url) =>
      _vault.canOfferInvite ? InviteThenPortalTrail(url) : PortalTrail(url);

  /// Token arrived after a token-less POST: re-POST once with the token and
  /// persist any freshly granted URL for the next launch.
  Future<void> _onTokenReady(String token) async {
    try {
      final idfa = await _consent.idfaIfAuthorized();
      final reply = await _exchange.send(
        _attr.buildPayload(locale: _locale, pushToken: token, idfa: idfa),
      );
      if (reply.granted) {
        await _commitPortal(reply);
      }
    } catch (e) {
      emberLog(() => '[CFT.coord] token re-post failed $e');
    }
  }

  /// Cold-start path: learn the device server-side without blocking the UI.
  Future<void> _warmAttributionSilently() async {
    try {
      await _signal.bootstrap(onToken: _onTokenReady);
      await _attr.start();
      await _attr.awaitSignals(timeout: EmberConfig.awaitSignalsTimeout);
      final token = await _signal.awaitToken();
      final idfa = await _consent.idfaIfAuthorized();
      await _exchange.send(
        _attr.buildPayload(locale: _locale, pushToken: token, idfa: idfa),
      );
    } catch (_) {/* best effort */}
  }
}
