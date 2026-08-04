import 'dart:convert';

import '../core/ember_config.dart';
import '../core/ember_log.dart';
import '../models/beacon_reply.dart';
import 'ember_agent.dart';

/// POSTs the flat config body to the endpoint and parses the reply. Any
/// non-200 / socket / decode failure is a NEGATIVE answer (never throws).
class BeaconExchange {
  BeaconExchange(this._agent);

  final EmberAgent _agent;

  Future<BeaconReply> send(Map<String, dynamic> body) async {
    final encoded = jsonEncode(body);
    emberLog(() => '[CFT.beacon] request $encoded');
    try {
      final res = await _agent.postJson(EmberConfig.configEndpoint, encoded);
      emberLog(() => '[CFT.beacon] ${res.statusCode} ${res.body}');
      // Any HTTP status is a definitive answer (a 404 for organic is correct).
      if (res.statusCode != 200) return const BeaconReply.declined();
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        final reply = BeaconReply.fromJson(decoded);
        // A granted URL must pass the domain allowlist, else treat as declined.
        if (reply.granted && !EmberConfig.hostAllowed(reply.destination)) {
          emberLog(() => '[CFT.beacon] destination host not allowlisted');
          return const BeaconReply.declined();
        }
        return reply;
      }
      return const BeaconReply.declined();
    } catch (e) {
      // Socket / DNS / timeout — transient, no definitive answer.
      emberLog(() => '[CFT.beacon] failed $e');
      return const BeaconReply.unreachable();
    }
  }
}
