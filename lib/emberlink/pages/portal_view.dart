import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../core/ember_config.dart';
import '../core/ember_log.dart';
import '../ember_gate.dart';
import '../infra/reach_probe.dart';
import 'offline_page.dart';

/// Arguments for the portal route.
class PortalArgs {
  const PortalArgs(this.url, {this.coldStart = false});
  final String url;
  final bool coldStart;
}

/// Full-screen WebView shell (the "gray" surface).
class PortalView extends ConsumerStatefulWidget {
  const PortalView({super.key, required this.url, this.coldStart = false});

  final String url;
  final bool coldStart;

  @override
  ConsumerState<PortalView> createState() => _PortalViewState();
}

class _PortalViewState extends ConsumerState<PortalView>
    with WidgetsBindingObserver {
  WebViewController? _wv;
  bool _viewportReady = false;
  bool _offline = false;
  bool _coldReloadDone = false;
  int _redirectHits = 0;
  String _lastMainUrl = '';
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enterImmersive();
    _lastMainUrl = widget.url;
    unawaited(_init());
  }

  @override
  void dispose() {
    final services = ref.read(emberServicesProvider);
    if (services.signal.onDestination == _onPushDestination) {
      services.signal.onDestination = null;
    }
    unawaited(_connSub?.cancel());
    WidgetsBinding.instance.removeObserver(this);
    // Hand the status bar / home indicator back to the rest of the app.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  /// Hides the status bar + home-indicator HUD so the portal is truly
  /// full-screen. `immersiveSticky` re-hides them after a system-edge swipe.
  void _enterImmersive() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _enterImmersive();
      unawaited(_consumePending());
    }
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    setState(() {}); // re-read viewPadding after immersive / rotation settles
    _pokeReflow();
  }

  Future<void> _init() async {
    final services = ref.read(emberServicesProvider);
    final ua = await services.agent.userAgent();

    final params = WebKitWebViewControllerCreationParams(
      allowsInlineMediaPlayback: true,
      mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
    );
    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setUserAgent(ua)
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (url.isNotEmpty) _lastMainUrl = url;
          },
          onPageFinished: _onPageFinished,
          onWebResourceError: _onError,
          onNavigationRequest: _onNavigation,
        ),
      );
    // Enable the native iOS edge-swipe back/forward gesture inside the WebView.
    if (controller.platform is WebKitWebViewController) {
      (controller.platform as WebKitWebViewController)
          .setAllowsBackForwardNavigationGestures(true);
    }
    _wv = controller;

    // A push tapped while this portal is live loads straight into the WebView;
    // bootstrap also wires the stash path for pushes that arrive otherwise.
    services.signal.onDestination = _onPushDestination;
    unawaited(services.signal.bootstrap());

    // Show the offline screen the instant every interface drops, instead of
    // waiting for the next WebView load error to surface it.
    _connSub = const ReachProbe().changes.listen((states) {
      if (mounted && !_offline && ReachProbe.allDown(states)) {
        setState(() => _offline = true);
      }
    });

    if (widget.coldStart) {
      await _settleColdViewport();
    } else {
      if (!mounted) return;
      setState(() => _viewportReady = true);
      await controller.loadRequest(Uri.parse(widget.url));
    }
  }

  Future<void> _settleColdViewport() async {
    await Future.delayed(
      const Duration(milliseconds: EmberConfig.coldViewportSettleMs),
    );
    if (!mounted) return;
    setState(() => _viewportReady = true);
    await _wv?.loadRequest(Uri.parse(widget.url));
  }

  // ── Navigation / errors ─────────────────────────────────────────────────
  Future<NavigationDecision> _onNavigation(NavigationRequest request) async {
    emberLog(
      () => '[CFT.nav] ${request.url} main=${request.isMainFrame}',
    );
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;
    switch (uri.scheme) {
      case 'http':
      case 'https':
      case 'about':
      case 'data':
      case 'blob':
        if (request.isMainFrame) _lastMainUrl = request.url;
        return NavigationDecision.navigate;
      case 'javascript':
        // Never hand a javascript: URL to the OS.
        return NavigationDecision.prevent;
      default:
        // tel / mailto AND every partner deep-link / app scheme: hand off to
        // the OS exactly like the template (a silent drop here is what made
        // deep-link taps look dead).
        unawaited(_handoff(uri));
        return NavigationDecision.prevent;
    }
  }

  Future<void> _handoff(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  /// A push tapped while this portal is on screen: load its URL right away.
  void _onPushDestination(String url) {
    if (!mounted) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return;
    _offline = false;
    _redirectHits = 0;
    _lastMainUrl = url;
    _wv?.loadRequest(uri);
  }

  /// Drains a push URL that was stashed while no portal was live (warm start /
  /// app resumed from background). One-shot; safe to call repeatedly.
  Future<void> _consumePending() async {
    final services = ref.read(emberServicesProvider);
    final pending = await services.vault.consumePushUrl();
    if (pending == null) return;
    _onPushDestination(pending);
  }

  void _onError(WebResourceError error) {
    final mainFrame = error.isForMainFrame ?? true;
    if (error.errorCode == -999) return; // cancelled by a new load
    if (error.errorCode == -1007 &&
        _redirectHits < EmberConfig.redirectRetryLimit) {
      _redirectHits++;
      _wv?.loadRequest(Uri.parse(_lastMainUrl));
      return;
    }
    if (!mainFrame) return;
    unawaited(_maybeGoOffline());
  }

  Future<void> _maybeGoOffline() async {
    final reachable = await const ReachProbe().canReach();
    if (!reachable && mounted) setState(() => _offline = true);
  }

  void _onPageFinished(String url) {
    _redirectHits = 0;
    _injectIgnite();
    Future.delayed(
      const Duration(milliseconds: EmberConfig.postPageResizeMs),
      () {
        if (!mounted) return;
        setState(() {});
        _wv?.runJavaScript(
          'window.dispatchEvent(new Event("resize"));'
          'if(window.visualViewport)window.visualViewport.dispatchEvent(new Event("resize"));',
        );
        _injectIgnite();
        if (widget.coldStart && !_coldReloadDone) {
          _coldReloadDone = true;
          _wv?.reload();
        }
      },
    );
  }

  void _pokeReflow() {
    for (final ms in EmberConfig.pokeReflowDelaysMs) {
      Future.delayed(Duration(milliseconds: ms), () {
        if (!mounted) return;
        _wv?.runJavaScript(
          'window.dispatchEvent(new Event("orientationchange"));'
          'window.dispatchEvent(new Event("resize"));',
        );
        _injectIgnite();
      });
    }
  }

  /// One merged, idempotent native-feel bundle (gray_part_mixing_review §6b:
  /// the six template injections are collapsed into a single guarded function).
  void _injectIgnite() {
    _wv?.runJavaScript(_igniteJs);
  }

  static const String _igniteJs = r'''
(function(){
  var root = window; if (root.__cftIgnite) { root.__cftIgnite.apply(); return; }
  function kbOpen(){ return root.visualViewport && root.visualViewport.height < root.innerHeight * 0.75; }
  function ensureViewport(){
    var m = document.querySelector('meta[name=viewport]');
    if(!m){ m=document.createElement('meta'); m.name='viewport'; document.head.appendChild(m); }
    m.setAttribute('content','width=device-width, initial-scale=1, maximum-scale=1, minimum-scale=1, user-scalable=no, viewport-fit=contain');
  }
  function styleOnce(){
    if(document.getElementById('cft-style')) return;
    var s=document.createElement('style'); s.id='cft-style';
    s.textContent=":root{--safe-area-inset-top:0px!important;--safe-area-inset-right:0px!important;--safe-area-inset-bottom:0px!important;--safe-area-inset-left:0px!important;--sat:0px!important;--sar:0px!important;--sab:0px!important;--sal:0px!important;}"+
      "*{-webkit-tap-highlight-color:transparent!important;}"+
      "html,body{overscroll-behavior:none!important;overscroll-behavior-y:none!important;}"+
      "input,textarea,select{font-size:max(16px,1em)!important;}";
    (document.head||document.documentElement).appendChild(s);
  }
  function apply(){ if(kbOpen()) return; ensureViewport(); styleOnce(); }
  function guardGestures(){
    ['gesturestart','gesturechange','gestureend'].forEach(function(t){
      root.addEventListener(t,function(e){e.preventDefault();},{passive:false});
    });
    var last=0;
    document.addEventListener('touchend',function(e){
      var now=Date.now(); if(now-last<=300){e.preventDefault();} last=now;
    },{passive:false});
  }
  function focusRoll(){
    document.addEventListener('focusin',function(e){
      var el=e.target; if(!el||!el.scrollIntoView) return;
      setTimeout(function(){ try{ el.scrollIntoView({behavior:'auto',block:'nearest'}); }catch(_){} },350);
    });
  }
  function sameFrameLinks(){
    // WKWebView silently drops target="_blank" / window.open navigations —
    // they never reach the native navigation delegate, so a tap looks dead.
    // Force every link into the main frame so the delegate (and our router)
    // sees it.
    function relink(node){
      var list = node && node.querySelectorAll ? node.querySelectorAll('a[target]') : null;
      if(!list) return;
      for(var i=0;i<list.length;i++){ if(list[i].target && list[i].target!=='_self'){ list[i].target='_self'; } }
    }
    relink(document);
    try{ window.open=function(u){ if(u){ location.href=u; } return root; }; }catch(_){}
    document.addEventListener('click',function(e){
      var el=e.target;
      for(var i=0;i<5&&el;i++){ if(el.tagName==='A'&&el.target&&el.target!=='_self'){ el.target='_self'; } el=el.parentElement; }
    },true);
    try{
      new MutationObserver(function(muts){
        muts.forEach(function(m){ if(m.addedNodes){ m.addedNodes.forEach(function(n){ relink(n); }); } });
      }).observe(document.documentElement,{childList:true,subtree:true});
    }catch(_){}
  }
  root.__cftIgnite={apply:apply};
  apply(); guardGestures(); focusRoll(); sameFrameLinks();
})();
''';

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_offline) {
      return OfflinePage(
        onRetry: () {
          setState(() {
            _offline = false;
            _redirectHits = 0;
          });
          _wv?.loadRequest(Uri.parse(_lastMainUrl));
        },
      );
    }

    final controller = _wv;
    final safe = MediaQuery.of(context).viewPadding;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final wv = _wv;
        if (wv != null && await wv.canGoBack()) {
          await wv.goBack();
        }
        // Back from the first page must NOT close the portal (invariant #6).
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        // Do NOT let the Scaffold shrink the WebView when the keyboard opens —
        // WKWebView manages its own inset via visualViewport, and a Flutter
        // resize is what caused the content to jump/pull up (matches template).
        resizeToAvoidBottomInset: false,
        body: (controller != null && _viewportReady)
            ? Padding(
                padding: EdgeInsets.only(
                  top: safe.top,
                  bottom: safe.bottom,
                  left: safe.left,
                  right: safe.right,
                ),
                child: WebViewWidget(controller: controller),
              )
            : const ColoredBox(color: Colors.black),
      ),
    );
  }
}
