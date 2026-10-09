import 'package:flutter/material.dart';
import 'platform_web_view_interface.dart';

PlatformWebViewWidget createPlatformWebViewWidget({
  Key? key,
  required String initialUrl,
  required OnPageLoadedCallback onPageLoaded,
  OnPageStartedCallback? onPageStarted,
  required OnPageProgressCallback onProgress,
  required OnWebErrorCallback onError,
  OnUpiMessageCallback? onUpiMessage,
  OnAuthStatusCallback? onAuthStatus,
  void Function(PlatformWebViewController controller)? onControllerCreated,
}) {
  return _StubWebViewWidget(
    key: key,
    initialUrl: initialUrl,
    onPageLoaded: onPageLoaded,
    onPageStarted: onPageStarted,
    onProgress: onProgress,
    onError: onError,
    onUpiMessage: onUpiMessage,
    onAuthStatus: onAuthStatus,
    onControllerCreated: onControllerCreated,
  );
}

class _StubWebViewWidget extends PlatformWebViewWidget {
  const _StubWebViewWidget({
    super.key,
    required super.initialUrl,
    required super.onPageLoaded,
    super.onPageStarted,
    required super.onProgress,
    required super.onError,
    super.onUpiMessage,
    super.onAuthStatus,
    super.onControllerCreated,
  });

  @override
  State<_StubWebViewWidget> createState() => _StubWebViewWidgetState();
}

class _StubWebViewWidgetState extends State<_StubWebViewWidget> implements PlatformWebViewController {
  @override
  void initState() {
    super.initState();
    widget.onControllerCreated?.call(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onProgress(1.0);
      widget.onPageLoaded(widget.initialUrl);
    });
  }

  @override
  void loadUrl(String url) {}

  @override
  Future<String?> currentUrl() async => widget.initialUrl;

  @override
  Future<bool> canGoBack() async => false;

  @override
  Future<void> goBack() async {}

  @override
  void reload() {}

  @override
  void postResponse(String rawResponse, int requestCode) {}

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Web view not supported on this platform'));
  }
}
