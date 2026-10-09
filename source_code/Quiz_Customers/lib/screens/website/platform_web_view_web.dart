// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
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
  return WebPlatformWebViewWidget(
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

class WebPlatformWebViewWidget extends PlatformWebViewWidget {
  const WebPlatformWebViewWidget({
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
  State<WebPlatformWebViewWidget> createState() => _WebPlatformWebViewWidgetState();
}

class _WebPlatformWebViewWidgetState extends State<WebPlatformWebViewWidget>
    implements PlatformWebViewController {
  late final String _viewType;
  html.IFrameElement? _iframe;
  StreamSubscription<html.MessageEvent>? _messageSubscription;
  StreamSubscription<html.Event>? _loadSubscription;
  StreamSubscription<html.Event>? _errorSubscription;
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
    _viewType = 'quizrupi-iframe-${DateTime.now().microsecondsSinceEpoch}';

    _iframe = html.IFrameElement()
      ..src = _currentUrl
      ..id = 'quizrupi-web-iframe'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.position = 'absolute'
      ..style.top = '0'
      ..style.left = '0'
      ..style.backgroundColor = '#0B1326'
      ..allow = 'fullscreen; accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; payment; web-share'
      ..setAttribute('allowfullscreen', 'true')
      ..setAttribute(
        'sandbox',
        'allow-forms allow-modals allow-orientation-lock allow-pointer-lock allow-popups allow-popups-to-escape-sandbox allow-presentation allow-same-origin allow-scripts allow-top-navigation allow-top-navigation-by-user-activation',
      );

    _loadSubscription = _iframe!.onLoad.listen((_) {
      if (mounted) {
        widget.onProgress(1.0);
        widget.onPageLoaded(_currentUrl);
      }
    });

    _errorSubscription = _iframe!.onError.listen((_) {
      if (mounted) {
        widget.onError('Failed to load page in iframe');
      }
    });

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _iframe!,
    );

    _messageSubscription = html.window.onMessage.listen((event) {
      final data = event.data;
      if (data == null) return;

      String? dataStr;
      if (data is String) {
        dataStr = data;
      } else {
        try {
          dataStr = jsonEncode(data);
        } catch (_) {}
      }

      if (dataStr != null && dataStr.isNotEmpty) {
        try {
          final decoded = jsonDecode(dataStr);
          if (decoded is Map<String, dynamic>) {
            if (decoded['type'] == 'auth_status') {
              final isLogged = decoded['isLoggedIn'] == true;
              widget.onAuthStatus?.call(isLogged);
            }
          }
        } catch (_) {}

        widget.onUpiMessage?.call(dataStr);
      }
    });

    widget.onControllerCreated?.call(this);
    widget.onProgress(0.3);
  }

  @override
  void didUpdateWidget(covariant WebPlatformWebViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialUrl != widget.initialUrl && widget.initialUrl.isNotEmpty) {
      loadUrl(widget.initialUrl);
    }
  }

  @override
  void loadUrl(String url) {
    var cleanUrl = url.trim();
    if (cleanUrl.isNotEmpty && !cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'https://$cleanUrl';
    }
    _currentUrl = cleanUrl;
    widget.onProgress(0.2);
    widget.onPageStarted?.call(cleanUrl);
    if (_iframe != null) {
      _iframe!.src = cleanUrl;
    }
  }

  @override
  void reload() {
    if (_iframe != null) {
      widget.onProgress(0.2);
      _iframe!.src = _currentUrl;
    }
  }

  @override
  Future<String?> currentUrl() async => _currentUrl;

  @override
  Future<bool> canGoBack() async => false;

  @override
  Future<void> goBack() async {
    html.window.history.back();
  }

  @override
  void postResponse(String rawResponse, int requestCode) {
    try {
      final payload = {
        'type': 'upi_response',
        'status': rawResponse,
        'requestCode': requestCode,
      };
      _iframe?.contentWindow?.postMessage(jsonEncode(payload), '*');
      _iframe?.contentWindow?.postMessage(payload, '*');
    } catch (e) {
      debugPrint('[QuizRupi Web] postResponse error: $e');
    }
  }

  @override
  void dispose() {
    _loadSubscription?.cancel();
    _errorSubscription?.cancel();
    _messageSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
