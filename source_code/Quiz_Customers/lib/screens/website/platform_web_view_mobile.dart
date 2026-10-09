import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
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
  return MobilePlatformWebViewWidget(
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

class MobilePlatformWebViewWidget extends PlatformWebViewWidget {
  const MobilePlatformWebViewWidget({
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
  State<MobilePlatformWebViewWidget> createState() => _MobilePlatformWebViewWidgetState();
}

class _MobilePlatformWebViewWidgetState extends State<MobilePlatformWebViewWidget>
    implements PlatformWebViewController {
  late final WebViewController _controller;
  late final PlatformWebViewWidgetCreationParams _widgetParams;
  bool _bridgeInjectedForCurrentPage = false;
  String _currentUrl = '';

  static const String _directUpiBridgeScript = r'''
(function() {
  try {
    if (window._quizRupiBridgeInstalled) return;
    window._quizRupiBridgeInstalled = true;

    try {
      var path = window.location.pathname || '';
      var host = window.location.hostname || '';
      var isSpinSite = host.indexOf('manishenterprise') !== -1 || path.indexOf('/ui') !== -1;
      var isLoginView = isSpinSite && (path.endsWith('index.html') || path.endsWith('/ui/') || path.endsWith('/ui'));
      var loginStatus = localStorage.getItem('webspin_login_status');
      var activeUser = localStorage.getItem('webspin_active_user') || localStorage.getItem('webspin_user');
      var isUserLoggedIn = (loginStatus === 'loggedIn') && Boolean(activeUser);

      if (isLoginView && isUserLoggedIn) {
        if (document.documentElement) {
          document.documentElement.style.display = 'none';
        }
        window.location.replace('dashboard.html');
        return;
      }

      if (isSpinSite && window.QuizRupiBridge && typeof window.QuizRupiBridge.postMessage === 'function') {
        window.QuizRupiBridge.postMessage(JSON.stringify({
          type: 'auth_status',
          isLoggedIn: isUserLoggedIn || path.includes('dashboard.html'),
          url: window.location.href
        }));
      }

      if (!window._quizRupiAuthHookAttached) {
        window._quizRupiAuthHookAttached = true;
        var rawSetItem = localStorage.setItem;
        localStorage.setItem = function(k, v) {
          rawSetItem.apply(this, arguments);
          if (k === 'webspin_login_status' && v === 'loggedIn') {
            if (window.QuizRupiBridge) {
              window.QuizRupiBridge.postMessage(JSON.stringify({
                type: 'auth_status',
                isLoggedIn: true,
                url: window.location.href
              }));
            }
          }
        };

        var rawRemoveItem = localStorage.removeItem;
        localStorage.removeItem = function(k) {
          rawRemoveItem.apply(this, arguments);
          if (k === 'webspin_login_status' || k === 'webspin_active_user') {
            if (window.QuizRupiBridge) {
              window.QuizRupiBridge.postMessage(JSON.stringify({
                type: 'auth_status',
                isLoggedIn: false,
                url: window.location.href
              }));
            }
          }
        };
      }
    } catch(authErr) {
      console.warn('[QuizRupi Auth Sync] error:', authErr);
    }

    if (!document.getElementById('quizrupi-suppress-modal-style')) {
      var style = document.createElement('style');
      style.id = 'quizrupi-suppress-modal-style';
      style.textContent = `
        #paymentGatewayModal,
        .modal#paymentGatewayModal,
        .modal-backdrop#paymentGatewayModal,
        div#paymentGatewayModal {
          display: none !important;
          visibility: hidden !important;
          opacity: 0 !important;
          pointer-events: none !important;
          height: 0 !important;
          width: 0 !important;
          max-height: 0 !important;
          max-width: 0 !important;
          overflow: hidden !important;
          position: absolute !important;
          z-index: -9999 !important;
        }
      `;
      (document.head || document.documentElement).appendChild(style);
    }

    window.triggerNativeDirectUPI = function(rawPrice, orderId, rawNote, upiId, merchantName, index) {
      if (typeof isPaymentInProgress !== 'undefined' && isPaymentInProgress) return;
      if (typeof isPaymentInProgress !== 'undefined') isPaymentInProgress = true;

      window.currentPendingUpiPayment = {
        price: rawPrice,
        orderId: orderId,
        note: rawNote,
        upiId: upiId,
        merchantName: merchantName,
        index: index
      };

      if (window.QuizRupiBridge && typeof window.QuizRupiBridge.postMessage === 'function') {
        window.QuizRupiBridge.postMessage(JSON.stringify({
          type: 'upi_payment',
          price: rawPrice,
          orderId: orderId,
          note: rawNote,
          upiId: upiId,
          merchantName: merchantName,
          index: index
        }));
      }
    };
  } catch(err) {
    console.error('[QuizRupi Bridge] injection error:', err);
  }
})();
''';

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
    _initializeWebView(_currentUrl);
    widget.onControllerCreated?.call(this);
  }

  void _initializeWebView(String url) {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B1326))
      ..addJavaScriptChannel(
        'QuizRupiBridge',
        onMessageReceived: (JavaScriptMessage message) {
          widget.onUpiMessage?.call(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            final p = progress / 100.0;
            widget.onProgress(p);
            if (progress >= 70 && !_bridgeInjectedForCurrentPage) {
              _bridgeInjectedForCurrentPage = true;
              _injectDirectUpiBridge();
            }
          },
          onPageStarted: (String url) {
            _bridgeInjectedForCurrentPage = false;
            _currentUrl = url;
            widget.onProgress(0.1);
            widget.onPageStarted?.call(url);
          },
          onPageFinished: (String url) {
            _currentUrl = url;
            widget.onProgress(1.0);
            widget.onPageLoaded(url);
            _injectDirectUpiBridge();
          },
          onWebResourceError: (WebResourceError error) {
            if (error.errorCode == -2 || error.errorCode == -6 || error.errorCode == -8) {
              widget.onError(error.description);
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;

            if (uri.scheme == 'upi') {
              widget.onUpiMessage?.call(jsonEncode({
                'type': 'upi_scheme',
                'url': request.url,
              }));
              return NavigationDecision.prevent;
            }

            final scheme = uri.scheme.toLowerCase();
            if (scheme != 'https' &&
                scheme != 'http' &&
                scheme != 'about' &&
                scheme != 'data' &&
                scheme != 'blob' &&
                scheme != 'javascript') {
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );

    if (_controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      final androidController = _controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
      androidController.setVerticalScrollBarEnabled(false);
      androidController.setHorizontalScrollBarEnabled(false);
      androidController.setOverScrollMode(WebViewOverScrollMode.ifContentScrolls);
      androidController.setAllowFileAccess(true);
      androidController.setAllowContentAccess(true);
      androidController.setUseWideViewPort(true);
      androidController.setMixedContentMode(MixedContentMode.alwaysAllow);
      androidController.enableZoom(false);
      androidController.setTextZoom(100);
    }

    const gestureRecognizers = <Factory<OneSequenceGestureRecognizer>>{
      Factory<VerticalDragGestureRecognizer>(VerticalDragGestureRecognizer.new),
      Factory<HorizontalDragGestureRecognizer>(HorizontalDragGestureRecognizer.new),
      Factory<ScaleGestureRecognizer>(ScaleGestureRecognizer.new),
      Factory<TapGestureRecognizer>(TapGestureRecognizer.new),
      Factory<LongPressGestureRecognizer>(LongPressGestureRecognizer.new),
    };

    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      _widgetParams = AndroidWebViewWidgetCreationParams(
        controller: _controller.platform,
        displayWithHybridComposition: true,
        gestureRecognizers: gestureRecognizers,
      );
    } else {
      _widgetParams = PlatformWebViewWidgetCreationParams(
        controller: _controller.platform,
        gestureRecognizers: gestureRecognizers,
      );
    }

    loadUrl(url);
  }

  Future<void> _injectDirectUpiBridge() async {
    try {
      await _controller.runJavaScript(_directUpiBridgeScript);
    } catch (e) {
      debugPrint('[QuizRupi Mobile] _injectDirectUpiBridge error: $e');
    }
  }

  @override
  void loadUrl(String url) {
    var cleanUrl = url.trim();
    if (cleanUrl.isNotEmpty && !cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'https://$cleanUrl';
    }
    final uri = Uri.tryParse(cleanUrl);
    if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
      _currentUrl = cleanUrl;
      _controller.loadRequest(uri);
    } else {
      widget.onError('Invalid website URL.');
    }
  }

  @override
  Future<String?> currentUrl() async {
    try {
      return await _controller.currentUrl() ?? _currentUrl;
    } catch (_) {
      return _currentUrl;
    }
  }

  @override
  Future<bool> canGoBack() async {
    try {
      return await _controller.canGoBack();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> goBack() async {
    try {
      if (await _controller.canGoBack()) {
        await _controller.goBack();
      }
    } catch (_) {}
  }

  @override
  void reload() {
    try {
      _controller.reload();
    } catch (_) {
      loadUrl(_currentUrl);
    }
  }

  @override
  void postResponse(String rawResponse, int requestCode) {
    try {
      final safeResponse = jsonEncode(rawResponse);
      final js = '''
(function() {
  try {
    if (typeof isPaymentInProgress !== 'undefined') isPaymentInProgress = false;
    if (window.currentPendingUpiPayment) window.currentPendingUpiPayment = null;
    if (typeof hidePaymentLoadingDialog === 'function') hidePaymentLoadingDialog();
    if (typeof closePaymentGatewayModal === 'function') closePaymentGatewayModal();

    var resp = $safeResponse;
    if (typeof window.processUPIResponse === 'function') {
      window.processUPIResponse(resp, $requestCode);
    } else if (typeof window.onUpiResult === 'function') {
      window.onUpiResult(resp);
    }
  } catch(e) {
    console.warn('[QuizRupi Mobile] postResponse error:', e);
  }
})();
''';
      _controller.runJavaScript(js);
    } catch (e) {
      debugPrint('[QuizRupi Mobile] postResponse error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget.fromPlatformCreationParams(
      params: _widgetParams,
    );
  }
}
