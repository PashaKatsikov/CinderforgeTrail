/// Result of the routing pipeline, consumed by the splash to pick a screen.
sealed class TrailDestination {
  const TrailDestination();
}

/// Show the game (organic / reviewer / failed first fetch).
class NativeTrail extends TrailDestination {
  const NativeTrail();
}

/// Show the offline screen; Retry re-runs the whole pipeline.
class OfflineTrail extends TrailDestination {
  const OfflineTrail();
}

/// Open the portal WebView at [url].
///
/// [coldStart] is true only when this came from a killed-app push tap, which
/// needs the deferred-mount viewport fix.
class PortalTrail extends TrailDestination {
  const PortalTrail(this.url, {this.coldStart = false});

  final String url;
  final bool coldStart;
}

/// Show the push-permission invitation before opening the portal at [url].
class InviteThenPortalTrail extends TrailDestination {
  const InviteThenPortalTrail(this.url);

  final String url;
}
