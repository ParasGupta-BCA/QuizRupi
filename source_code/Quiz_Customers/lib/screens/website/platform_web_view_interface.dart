import 'package:flutter/material.dart';

typedef OnPageLoadedCallback = void Function(String url);
typedef OnPageStartedCallback = void Function(String url);
typedef OnPageProgressCallback = void Function(double progress);
typedef OnWebErrorCallback = void Function(String error);
typedef OnUpiMessageCallback = void Function(String rawJson);
typedef OnAuthStatusCallback = void Function(bool isLoggedIn);

abstract class PlatformWebViewController {
  void loadUrl(String url);
  Future<String?> currentUrl();
  Future<bool> canGoBack();
  Future<void> goBack();
  void reload();
  void postResponse(String rawResponse, int requestCode);
  void dispose();
}

abstract class PlatformWebViewWidget extends StatefulWidget {
  final String initialUrl;
  final OnPageLoadedCallback onPageLoaded;
  final OnPageStartedCallback? onPageStarted;
  final OnPageProgressCallback onProgress;
  final OnWebErrorCallback onError;
  final OnUpiMessageCallback? onUpiMessage;
  final OnAuthStatusCallback? onAuthStatus;
  final void Function(PlatformWebViewController controller)? onControllerCreated;

  const PlatformWebViewWidget({
    super.key,
    required this.initialUrl,
    required this.onPageLoaded,
    this.onPageStarted,
    required this.onProgress,
    required this.onError,
    this.onUpiMessage,
    this.onAuthStatus,
    this.onControllerCreated,
  });
}
