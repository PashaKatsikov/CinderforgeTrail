import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/palette.dart';
import '../../core/design/typography.dart';
import '../../widgets/buttons.dart';

/// A hosted document with a bundled copy that is used whenever the network is
/// unavailable, slow, or returns an error.
///
/// The offline copy is not a placeholder: it is the same document, shipped in
/// the APK, so these pages always render real content.
class WebDocument {
  const WebDocument({
    required this.title,
    required this.url,
    required this.assetPath,
  });

  final String title;
  final String url;
  final String assetPath;

  static const privacy = WebDocument(
    title: 'Privacy Policy',
    url: 'https://cinderforgetrail.com/privacy-policy.html',
    assetPath: 'assets/app/legal/privacy_policy.html',
  );

  static const support = WebDocument(
    title: 'Support',
    url: 'https://cinderforgetrail.com/support.html',
    assetPath: 'assets/app/legal/support.html',
  );
}

class WebPageScreen extends StatefulWidget {
  const WebPageScreen({super.key, required this.document});

  final WebDocument document;

  @override
  State<WebPageScreen> createState() => _WebPageScreenState();
}

class _WebPageScreenState extends State<WebPageScreen> {
  late final WebViewController _controller;
  Timer? _watchdog;

  bool _loading = true;
  bool _usingBundled = false;
  bool _settled = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _onLoaded(),
          onWebResourceError: (error) {
            // Sub-resource failures (a missing font, say) must not throw away
            // a page that already rendered.
            if (error.isForMainFrame ?? true) _fallback();
          },
          onHttpError: (_) => _fallback(),
          onNavigationRequest: _handleNavigation,
        ),
      );
    _loadRemote();
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    super.dispose();
  }

  void _loadRemote() {
    _watchdog?.cancel();
    // Without a deadline an offline device sits on a blank white page until
    // the platform's own (very long) timeout fires.
    _watchdog = Timer(const Duration(seconds: 6), () {
      if (mounted && _loading) _fallback();
    });
    _controller.loadRequest(Uri.parse(widget.document.url));
  }

  Future<void> _fallback() async {
    if (_settled && _usingBundled) return;
    _watchdog?.cancel();
    _usingBundled = true;
    final html = await rootBundle.loadString(widget.document.assetPath);
    if (!mounted) return;
    await _controller.loadHtmlString(
      html,
      baseUrl: widget.document.url,
    );
  }

  void _onLoaded() {
    _watchdog?.cancel();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _settled = true;
    });
  }

  Future<NavigationDecision> _handleNavigation(NavigationRequest request) async {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;

    // Mail and store links belong to the system, not to this WebView.
    if (uri.scheme == 'mailto' || uri.scheme == 'tel') {
      unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  Future<void> _retry() async {
    setState(() {
      _loading = true;
      _usingBundled = false;
      _settled = false;
    });
    _loadRemote();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.base,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              title: widget.document.title,
              offline: _usingBundled,
              onBack: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
              onRetry: _usingBundled ? _retry : null,
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: ColoredBox(
                  color: Colors.white,
                  child: Stack(
                    children: [
                      WebViewWidget(controller: _controller),
                      if (_loading)
                        const ColoredBox(
                          color: Colors.white,
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Palette.ember,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.offline,
    required this.onBack,
    required this.onRetry,
  });

  final String title;
  final bool offline;
  final VoidCallback onBack;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Insets.m,
        Insets.s,
        Insets.m,
        Insets.m,
      ),
      child: Row(
        children: [
          IconPill(icon: Icons.arrow_back_rounded, onPressed: onBack, size: 40),
          const SizedBox(width: Insets.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppText.section),
                Text(
                  offline ? 'OFFLINE COPY' : 'CINDERFORGETRAIL.COM',
                  style: AppText.overline.copyWith(
                    color: offline ? Palette.gold : Palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null)
            IconPill(
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
              size: 40,
            ),
        ],
      ),
    );
  }
}
