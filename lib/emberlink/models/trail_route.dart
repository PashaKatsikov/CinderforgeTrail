/// Persisted routing mode for a given install.
///
/// * [fresh] — first launch, backend has not decided yet. A network failure
///   must never downgrade this to [native]; only a successful reply with no
///   URL commits [native].
/// * [portal] — this install was routed to the WebView portal.
/// * [native] — this install shows the game. May still be re-converted to
///   [portal] on a later launch if the backend starts returning a URL.
enum RouteMode { fresh, portal, native }

RouteMode routeModeFromName(String? name) {
  switch (name) {
    case 'portal':
      return RouteMode.portal;
    case 'native':
      return RouteMode.native;
    default:
      return RouteMode.fresh;
  }
}
