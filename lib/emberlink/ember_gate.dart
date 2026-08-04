import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'infra/beacon_exchange.dart';
import 'infra/ember_agent.dart';
import 'infra/ember_vault.dart';
import 'infra/reach_probe.dart';
import 'infra/signal_hub.dart';
import 'infra/tracking_consent.dart';
import 'infra/trail_attribution.dart';
import 'trail_coordinator.dart';

/// Aggregates the Emberlink services and exposes the pieces the UI needs.
/// Built once in `main()` and injected through [emberServicesProvider].
class EmberServices {
  EmberServices({
    required this.vault,
    required this.agent,
    required this.signal,
    required this.coordinator,
  });

  final EmberVault vault;
  final EmberAgent agent;
  final SignalHub signal;
  final TrailCoordinator coordinator;

  static Future<EmberServices> boot() async {
    final vault = await EmberVault.open();
    final agent = EmberAgent();
    final signal = SignalHub(vault);
    final coordinator = TrailCoordinator(
      vault: vault,
      probe: const ReachProbe(),
      attribution: TrailAttribution(agent),
      signal: signal,
      consent: TrackingConsent(),
      exchange: BeaconExchange(agent),
    );
    return EmberServices(
      vault: vault,
      agent: agent,
      signal: signal,
      coordinator: coordinator,
    );
  }
}

/// Overridden in `main()` with the booted instance.
final emberServicesProvider = Provider<EmberServices>(
  (ref) => throw UnimplementedError('emberServicesProvider must be overridden'),
);
