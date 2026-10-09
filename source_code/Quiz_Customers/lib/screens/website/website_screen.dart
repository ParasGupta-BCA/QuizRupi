import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/app_settings_provider.dart';

class WebsiteScreen extends ConsumerStatefulWidget {
  final String initialUrl;
  final String? initialTitle;

  const WebsiteScreen({
    super.key,
    required this.initialUrl,
    this.initialTitle,
  });

  // Persistence keys & in-memory cache for instant dashboard routing
  static const keyWebLoggedIn = 'quizrupi_web_user_logged_in';
  static const keyLastWebUrl = 'quizrupi_last_web_url';
  static bool? cachedIsWebLoggedIn;
  static String? cachedLastWebUrl;

  /// Pre-warms cache before any route or widget builds for zero-delay dashboard resolution
  static Future<void> initPersistence() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      cachedIsWebLoggedIn = prefs.getBool(keyWebLoggedIn) ?? false;
      cachedLastWebUrl = prefs.getString(keyLastWebUrl);
    } catch (e) {
      debugPrint('[QuizRupi] initPersistence error: $e');
    }
  }

  static bool isSpinWheelSite(String url) {
    final lower = url.trim().toLowerCase();
    return lower.contains('manishenterprise') || lower.contains('/ui');
  }

  static bool isLoginPath(String url) {
    if (!isSpinWheelSite(url)) return false;
    final lower = url.trim().toLowerCase();
    return lower.endsWith('index.html') ||
        lower.endsWith('/ui/') ||
        lower.endsWith('/ui') ||
        lower.endsWith('/login') ||
        lower.endsWith('/login.html');
  }

  static bool isRootUrl(String currentUrl, String initialUrl) {
    final cur = Uri.tryParse(currentUrl.trim());
    final init = Uri.tryParse(initialUrl.trim());
    if (cur == null || init == null) return true;
    return cur.host.toLowerCase() == init.host.toLowerCase() &&
        (cur.path == init.path || cur.path == '/' || cur.path.isEmpty);
  }

  /// Resolves the URL strictly according to the admin configuration:
  /// - Strictly honors the admin-settled target URL and host.
  /// - Invalidates and cleans up any stale cache from a different domain.
  /// - Only applies spin wheel dashboard.html redirection if the target site is specifically a spin wheel app.
  static String resolveTargetWebUrl(String rawUrl, {bool? forceLoggedIn}) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return trimmed;

    final targetUri = Uri.tryParse(trimmed);
    if (targetUri == null || !targetUri.hasScheme) return trimmed;

    final targetHost = targetUri.host.toLowerCase();

    // Verify if cachedLastWebUrl belongs to the exact same website/host
    final cachedUrl = cachedLastWebUrl?.trim();
    if (cachedUrl != null && cachedUrl.isNotEmpty) {
      final cachedUri = Uri.tryParse(cachedUrl);
      if (cachedUri != null && cachedUri.host.toLowerCase() == targetHost) {
        // Same domain: if user was logged in and cached URL is valid on this domain, we can keep it
        final isLoggedIn = forceLoggedIn ?? (cachedIsWebLoggedIn ?? false);
        if (isLoggedIn && cachedUrl.contains('dashboard.html') && isSpinWheelSite(trimmed)) {
          return cachedUrl;
        }
      } else {
        // Different domain! The admin changed the website URL!
        // Immediately invalidate the old domain's cached URL and login state
        cachedLastWebUrl = null;
        cachedIsWebLoggedIn = false;
        SharedPreferences.getInstance().then((p) {
          p.remove(keyLastWebUrl);
          p.remove(keyWebLoggedIn);
        }).catchError((_) {});
      }
    }

    // Only apply dashboard.html transformation if the URL itself is specifically a spin wheel /ui/ endpoint
    final isLoggedIn = forceLoggedIn ?? (cachedIsWebLoggedIn ?? false);
    if (isLoggedIn && isSpinWheelSite(trimmed)) {
      if (trimmed.endsWith('/ui/') || trimmed.endsWith('/ui')) {
        return trimmed.endsWith('/') ? '${trimmed}dashboard.html' : '$trimmed/dashboard.html';
      }
      if (trimmed.endsWith('index.html')) {
        return trimmed.replaceAll('index.html', 'dashboard.html');
      }
      if (trimmed.contains('/ui') && !trimmed.contains('.html')) {
        return trimmed.endsWith('/') ? '${trimmed}dashboard.html' : '$trimmed/dashboard.html';
      }
    }

    return trimmed;
  }

  @override
  ConsumerState<WebsiteScreen> createState() => _WebsiteScreenState();
}

class _WebsiteScreenState extends ConsumerState<WebsiteScreen> {
  late final WebViewController _controller;
  late final PlatformWebViewWidgetCreationParams _widgetParams;
  final ValueNotifier<double> _loadingProgressNotifier = ValueNotifier<double>(0.0);
  bool _isLoading = true;
  bool _bridgeInjectedForCurrentPage = false;
  bool _hasError = false;
  String _errorMessage = '';
  String _currentLoadedUrl = '';

  // Adaptive extracted status bar & navigation bar colors
  Color _topBgColor = const Color(0xFF0B1326);
  Color _bottomBgColor = const Color(0xFF0F172A);
  Timer? _postLoadCheckTimer;
  Timer? _splashFailsafeTimer;
  bool _isPageLoaded = false;
  bool _isTransitionComplete = false;
  bool _isUpiPaymentActive = false;
  String _cachedDeviceId = '';

  bool get _isTopDark => _topBgColor.computeLuminance() < 0.48;
  Brightness get _topBrightness => _isTopDark ? Brightness.light : Brightness.dark;

  bool get _isBottomDark => _bottomBgColor.computeLuminance() < 0.48;
  Brightness get _bottomBrightness => _isBottomDark ? Brightness.light : Brightness.dark;

  @override
  void initState() {
    super.initState();
    final liveSettings = ref.read(appSettingsProvider).settings;
    final adminUrl = liveSettings.isWebsiteModeValid ? liveSettings.websiteUrl?.trim() : null;
    final baseTarget = (adminUrl != null && adminUrl.isNotEmpty) ? adminUrl : widget.initialUrl;

    _currentLoadedUrl = WebsiteScreen.resolveTargetWebUrl(baseTarget);
    _initializeWebView(_currentLoadedUrl);
    _loadCachedLoginState();
    _fetchDeviceId();

    // Failsafe timer: only if network completely stalls for 15s, reveal to avoid indefinite freeze
    _splashFailsafeTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && !_isPageLoaded && !_hasError) {
        setState(() {
          _isPageLoaded = true;
        });
      }
    });
  }

  Future<void> _fetchDeviceId() async {
    try {
      final id = await _upiPlatformChannel.invokeMethod<String>('getDeviceId');
      if (id != null && id.isNotEmpty && mounted) {
        _cachedDeviceId = id;
        _injectDirectUpiBridge();
      }
    } catch (e) {
      debugPrint('[QuizRupi] _fetchDeviceId error: $e');
    }
  }

  Future<void> _loadCachedLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUrl = prefs.getString(WebsiteScreen.keyLastWebUrl);
      final isLoggedIn = prefs.getBool(WebsiteScreen.keyWebLoggedIn) ?? false;

      // Only preserve login state if the domain matches current target
      final initialUri = Uri.tryParse(_currentLoadedUrl);
      final cachedUri = lastUrl != null ? Uri.tryParse(lastUrl) : null;
      if (initialUri != null && cachedUri != null && initialUri.host.toLowerCase() != cachedUri.host.toLowerCase()) {
        // Different domain: discard old cache
        await prefs.remove(WebsiteScreen.keyLastWebUrl);
        await prefs.remove(WebsiteScreen.keyWebLoggedIn);
        WebsiteScreen.cachedIsWebLoggedIn = false;
        WebsiteScreen.cachedLastWebUrl = null;
        return;
      }

      WebsiteScreen.cachedIsWebLoggedIn = isLoggedIn;
      WebsiteScreen.cachedLastWebUrl = lastUrl;

      if (isLoggedIn && mounted && WebsiteScreen.isSpinWheelSite(_currentLoadedUrl)) {
        final target = WebsiteScreen.resolveTargetWebUrl(_currentLoadedUrl, forceLoggedIn: true);
        if (target != _currentLoadedUrl) {
          _currentLoadedUrl = target;
          _safeLoadUrl(target);
        }
      }
    } catch (e) {
      debugPrint('[QuizRupi] _loadCachedLoginState error: $e');
    }
  }

  Future<void> _updateCachedLoginState(bool isLoggedIn) async {
    WebsiteScreen.cachedIsWebLoggedIn = isLoggedIn;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(WebsiteScreen.keyWebLoggedIn, isLoggedIn);
      if (isLoggedIn) {
        if (_currentLoadedUrl.contains('dashboard.html')) {
          await prefs.setString(WebsiteScreen.keyLastWebUrl, _currentLoadedUrl);
          WebsiteScreen.cachedLastWebUrl = _currentLoadedUrl;
        }
      } else {
        await prefs.remove(WebsiteScreen.keyLastWebUrl);
        WebsiteScreen.cachedLastWebUrl = null;
      }
    } catch (e) {
      debugPrint('[QuizRupi] _updateCachedLoginState error: $e');
    }
  }

  Future<bool> _checkAndFastRedirectIfLoggedIn() async {
    if (!WebsiteScreen.isSpinWheelSite(_currentLoadedUrl)) return false;
    try {
      final result = await _controller.runJavaScriptReturningResult(
        r'''(function() {
          try {
            var status = localStorage.getItem('webspin_login_status');
            var user = localStorage.getItem('webspin_active_user') || localStorage.getItem('webspin_user');
            if (status === 'loggedIn' && Boolean(user)) {
              if (document.documentElement) {
                document.documentElement.style.display = 'none';
              }
              window.location.replace('dashboard.html');
              return 'true';
            }
          } catch(e) {}
          return 'false';
        })()''',
      );
      final isLogged = result.toString().replaceAll('"', '').trim() == 'true';
      if (isLogged) {
        _updateCachedLoginState(true);
        return true;
      }
    } catch (_) {}
    return false;
  }

  void _initializeWebView(String url) {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B1326))
      ..addJavaScriptChannel(
        'QuizRupiBridge',
        onMessageReceived: (JavaScriptMessage message) {
          _handleWebUpiMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            _loadingProgressNotifier.value = progress / 100.0;
            if (progress >= 100) {
              if (mounted && _isLoading) {
                setState(() {
                  _isLoading = false;
                });
              }
            } else if (progress >= 70 && !_bridgeInjectedForCurrentPage) {
              _bridgeInjectedForCurrentPage = true;
              _injectDirectUpiBridge();
            }
          },
          onPageStarted: (String url) {
            _bridgeInjectedForCurrentPage = false;
            _loadingProgressNotifier.value = 0.1;
            if (mounted) {
              final isDashboard = url.contains('dashboard.html');
              final isLogin = WebsiteScreen.isLoginPath(url);
              setState(() {
                _isLoading = true;
                _hasError = false;
                _errorMessage = '';
                _currentLoadedUrl = url;
              });
              if (isLogin) {
                _checkAndFastRedirectIfLoggedIn();
              }
              _injectDirectUpiBridge();
              if (isDashboard) {
                _updateCachedLoginState(true);
              }
            }
          },
          onPageFinished: (String url) async {
            if (!mounted) return;

            final isDashboard = url.contains('dashboard.html');
            final isLogin = WebsiteScreen.isLoginPath(url);

            _extractPageAttributes();
            _injectDirectUpiBridge();

            if (isDashboard) {
              _updateCachedLoginState(true);
            } else if (isLogin) {
              final redirected = await _checkAndFastRedirectIfLoggedIn();
              if (redirected) {
                // Currently redirecting to dashboard.html!
                return;
              }
            }

            if (mounted) {
              setState(() {
                _isLoading = false;
                _currentLoadedUrl = url;
              });
              _loadingProgressNotifier.value = 1.0;

              // Smooth buffer before revealing
              await Future.delayed(const Duration(milliseconds: 150));
              if (mounted && !_isPageLoaded) {
                setState(() {
                  _isPageLoaded = true;
                });
              }
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (error.isForMainFrame ?? true) {
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _isLoading = false;
                  _errorMessage = error.description;
                });
              }
            }
          },
          onNavigationRequest: (NavigationRequest request) async {
            final uri = Uri.tryParse(request.url);
            if (uri == null) {
              return NavigationDecision.prevent;
            }

            final scheme = uri.scheme.toLowerCase();
            final rawUrl = request.url;
            final lowerUrl = rawUrl.toLowerCase();

            // Check if this is a UPI or payment app intent/URL
            final isUpiOrPayment = scheme == 'upi' ||
                scheme == 'phonepe' ||
                scheme == 'paytmmp' ||
                scheme == 'gpay' ||
                scheme == 'bhim' ||
                scheme == 'cred' ||
                scheme == 'credpay' ||
                scheme == 'mobikwik' ||
                lowerUrl.startsWith('upi://') ||
                lowerUrl.contains('scheme=upi') ||
                lowerUrl.contains('data=upi');

            final isWhatsApp = scheme == 'whatsapp' ||
                lowerUrl.contains('wa.me/') ||
                lowerUrl.contains('api.whatsapp.com/') ||
                lowerUrl.contains('chat.whatsapp.com/');

            // Handle external schemes (UPI, telephony, intent, chat, whatsapp)
            if (isUpiOrPayment ||
                isWhatsApp ||
                scheme == 'tel' ||
                scheme == 'mailto' ||
                scheme == 'sms' ||
                scheme == 'whatsapp' ||
                scheme == 'intent') {
              try {
                Uri launchTarget = uri;

                // Handle Android intent:// URIs that wrap a upi:// payload
                if (scheme == 'intent') {
                  if (lowerUrl.contains('upi%3a%2f%2f') || lowerUrl.contains('upi://')) {
                    try {
                      final decoded = Uri.decodeFull(rawUrl);
                      final match = RegExp(r'upi://[^\s;#]+').firstMatch(decoded);
                      if (match != null) {
                        final extracted = Uri.tryParse(match.group(0)!);
                        if (extracted != null) launchTarget = extracted;
                      }
                    } catch (_) {}
                  }
                }

                if (isUpiOrPayment || launchTarget.scheme.toLowerCase() == 'upi') {
                  Uri finalLaunchUri = launchTarget;
                  int reqCode = 0;
                  try {
                    final qParams = Map<String, String>.from(launchTarget.queryParameters);
                    final curAm = qParams['am'];
                    if (curAm != null && curAm.isNotEmpty) {
                      final cleanAm = curAm.replaceAll(RegExp(r'[^0-9.]'), '');
                      final parsedAm = double.tryParse(cleanAm);
                      if (parsedAm != null && parsedAm > 0) {
                        qParams['am'] = parsedAm.toStringAsFixed(2);
                      }
                    }
                    if (qParams['pn'] == null || qParams['pn']!.isEmpty || qParams['pn']!.toLowerCase().contains('quizrupi')) {
                      qParams['pn'] = 'Rozgo Spin';
                    }
                    if (qParams['tn'] == null || qParams['tn']!.isEmpty || qParams['tn']!.toLowerCase().contains('quizrupi')) {
                      qParams['tn'] = 'Rozgo Spin';
                    }
                    if (qParams['tn']?.toLowerCase().contains('vip') ?? false) {
                      reqCode = 4;
                    }
                    finalLaunchUri = launchTarget.replace(queryParameters: qParams);
                  } catch (_) {}

                  await _launchUpiIntent(
                    upiUriString: finalLaunchUri.toString(),
                    requestCode: reqCode,
                  );
                } else {
                  final launched = await launchUrl(launchTarget, mode: LaunchMode.externalApplication);
                  if (!launched) {
                    await launchUrl(launchTarget, mode: LaunchMode.externalNonBrowserApplication);
                  }
                }
              } catch (e) {
                debugPrint('External link/UPI launch error: $e');
              }
              return NavigationDecision.prevent;
            }

            // Allow both HTTPS and HTTP web navigation without blocking
            if (scheme != 'https' && scheme != 'http' && scheme != 'about' && scheme != 'data' && scheme != 'blob' && scheme != 'javascript') {
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

    final gestureRecognizers = const <Factory<OneSequenceGestureRecognizer>>{
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

    _safeLoadUrl(url);
  }

  void _safeLoadUrl(String url) {
    var cleanUrl = url.trim();
    if (cleanUrl.isNotEmpty && !cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'https://$cleanUrl';
    }
    final uri = Uri.tryParse(cleanUrl);
    if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
      _controller.loadRequest(uri);
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = 'Invalid website URL. Please provide a valid web address.';
      });
    }
  }

  /// Dynamically extracts the website top banner/header color and bottom footer color
  Future<void> _extractPageAttributes() async {
    try {
      const jsScript = r'''
(function() {
  function getEffectiveBg(el) {
    var cur = el;
    var depth = 0;
    while (cur && cur !== document.documentElement && depth < 5) {
      depth++;
      var style = window.getComputedStyle(cur);
      var bg = style.backgroundColor;
      if (bg && bg !== 'rgba(0, 0, 0, 0)' && bg !== 'transparent') {
        return bg;
      }
      cur = cur.parentElement;
    }
    return null;
  }

  // 1. Top Color: Theme-color meta -> header/nav -> body
  var topColor = null;
  var metaTheme = document.querySelector('meta[name="theme-color"]');
  if (metaTheme && metaTheme.content) {
    topColor = metaTheme.content;
  }
  if (!topColor) {
    var topEl = document.querySelector('header') ||
                document.querySelector('nav') ||
                document.querySelector('.navbar') ||
                document.querySelector('.header') ||
                document.querySelector('.toolbar');
    if (topEl) {
      topColor = getEffectiveBg(topEl);
    }
  }
  if (!topColor && document.body) {
    topColor = getEffectiveBg(document.body);
  }
  if (!topColor) {
    topColor = window.getComputedStyle(document.documentElement).backgroundColor;
  }

  // 2. Bottom Color: footer -> body
  var bottomColor = null;
  var footer = document.querySelector('footer') ||
               document.querySelector('.footer') ||
               document.querySelector('.bottom-nav') ||
               document.querySelector('.tab-bar');
  if (footer) {
    bottomColor = getEffectiveBg(footer);
  }
  if (!bottomColor && document.body) {
    bottomColor = getEffectiveBg(document.body);
  }
  if (!bottomColor) {
    bottomColor = topColor || '#0B1326';
  }

  return JSON.stringify({
    topColor: topColor || '',
    bottomColor: bottomColor || ''
  });
})();
''';

      final rawResult = await _controller.runJavaScriptReturningResult(jsScript);
      final data = _decodeJsResult(rawResult);
      if (data != null && mounted) {
        final parsedTop = _parseCssColor(data['topColor'] as String?);
        final parsedBottom = _parseCssColor(data['bottomColor'] as String?);

        final newTop = (parsedTop != null && parsedTop.a > 0) ? parsedTop : null;
        final newBottom = (parsedBottom != null && parsedBottom.a > 0) ? parsedBottom : null;

        if ((newTop != null && newTop != _topBgColor) ||
            (newBottom != null && newBottom != _bottomBgColor)) {
          setState(() {
            if (newTop != null) _topBgColor = newTop;
            if (newBottom != null) _bottomBgColor = newBottom;
          });
        }
      }
    } catch (e) {
      debugPrint('Error extracting page attributes: $e');
    }
  }

  Color? _parseCssColor(String? input) {
    if (input == null || input.isEmpty) return null;
    final str = input.trim().toLowerCase();

    // Hex colors
    if (str.startsWith('#')) {
      final hex = str.substring(1);
      if (hex.length == 3) {
        final r = hex[0];
        final g = hex[1];
        final b = hex[2];
        return Color(int.parse('FF$r$r$g$g$b$b', radix: 16));
      } else if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        final aa = hex.substring(6, 8);
        final rgb = hex.substring(0, 6);
        return Color(int.parse('$aa$rgb', radix: 16));
      }
    }

    // rgb or rgba
    if (str.startsWith('rgb')) {
      final match = RegExp(r'rgba?\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)(?:\s*,\s*([0-9.]+))?\s*\)').firstMatch(str);
      if (match != null) {
        final r = int.parse(match.group(1)!);
        final g = int.parse(match.group(2)!);
        final b = int.parse(match.group(3)!);
        final aStr = match.group(4);
        final a = aStr != null ? (double.parse(aStr) * 255).round().clamp(0, 255) : 255;
        return Color.fromARGB(a, r, g, b);
      }
    }

    // Named colors
    switch (str) {
      case 'black': return Colors.black;
      case 'white': return Colors.white;
      case 'transparent': return null;
    }

    return null;
  }

  Map<String, dynamic>? _decodeJsResult(dynamic result) {
    if (result == null) return null;
    final str = result.toString().trim();
    if (str.isEmpty || str == 'null' || str == 'undefined') return null;

    try {
      final firstPass = jsonDecode(str);
      if (firstPass is Map) {
        return Map<String, dynamic>.from(firstPass);
      }
      if (firstPass is String) {
        final secondPass = jsonDecode(firstPass);
        if (secondPass is Map) {
          return Map<String, dynamic>.from(secondPass);
        }
      }
    } catch (_) {}

    return null;
  }

  static const _upiPlatformChannel = MethodChannel('com.quizrupi.customer/upi');

  static const String _directUpiBridgeScript = r'''
(function() {
  try {
    if (window._quizRupiBridgeInstalled) return;
    window._quizRupiBridgeInstalled = true;

    // 0. Auto-redirect to dashboard.html immediately if logged in and on index/login of spin wheel site
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

      // Sync auth status with Flutter
      if (isSpinSite && window.QuizRupiBridge && typeof window.QuizRupiBridge.postMessage === 'function') {
        window.QuizRupiBridge.postMessage(JSON.stringify({
          type: 'auth_status',
          isLoggedIn: isUserLoggedIn || path.includes('dashboard.html'),
          url: window.location.href
        }));
      }

      // Hook localStorage to instantly sync login/logout with Flutter
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

    // 1. Inject aggressive CSS to permanently suppress #paymentGatewayModal and enable GPU acceleration & smooth touch
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
          max-height: 0 !important;
          overflow: hidden !important;
        }

        /* Ensure all legitimate modals (Free Spin, Withdraw, Alerts, etc.) are visible and interactive when shown */
        .modal-backdrop.show:not(#paymentGatewayModal) {
          display: flex !important;
          visibility: visible !important;
          opacity: 1 !important;
          pointer-events: auto !important;
          z-index: 100000 !important;
        }

        #freeSpinModal.show {
          display: flex !important;
          visibility: visible !important;
          opacity: 1 !important;
          pointer-events: auto !important;
          z-index: 100000 !important;
        }

        /* Hide visual scrollbars completely while keeping 100% active scrolling */
        ::-webkit-scrollbar {
          display: none !important;
          width: 0px !important;
          height: 0px !important;
          background: transparent !important;
        }

        *::-webkit-scrollbar {
          display: none !important;
          width: 0px !important;
          height: 0px !important;
          background: transparent !important;
        }

        html, body {
          scrollbar-width: none !important;
          -ms-overflow-style: none !important;
          -webkit-overflow-scrolling: touch !important;
          -webkit-tap-highlight-color: transparent !important;
          -webkit-touch-callout: none !important;
        }

        /* Fast touch response on all clickable elements without tap delay */
        button, a, input, select, textarea, .tab-nav-item, .btn, .card, [role="button"], [role="tab"], .btn-vip-buy, #buynow, #btnBuyCard5, .free-spin-gift-btn, #zzfabButton {
          touch-action: manipulation !important;
          -webkit-tap-highlight-color: transparent !important;
          cursor: pointer !important;
        }

        /* Hardware acceleration ONLY for genuinely animated wheel elements */
        .wheel-container, .spin-wheel {
          transform: translateZ(0);
          -webkit-transform: translateZ(0);
          backface-visibility: hidden;
          -webkit-backface-visibility: hidden;
        }
      `;
      (document.head || document.documentElement).appendChild(style);
    }

    // 2. Hide payment gateway modal if already present in DOM
    var modal = document.getElementById('paymentGatewayModal');
    if (modal) {
      modal.classList.remove('show');
      modal.style.setProperty('display', 'none', 'important');
      modal.style.setProperty('visibility', 'hidden', 'important');
    }

    // 2b. High-performance event delegation for Free Spin (zero recurring timers, instant click)
    document.addEventListener('click', function(e) {
      var btn = e.target && e.target.closest ? e.target.closest('#zzfabButton, .free-spin-gift-btn') : null;
      if (btn) {
        try {
          var freeModal = document.getElementById('freeSpinModal');
          if (freeModal) {
            var userNow = (window.ApiService && ApiService.getActiveUser()) || window.activeUser || {};
            if (typeof window.updateClaimButtonState === 'function') {
              window.updateClaimButtonState(parseInt(userNow.freeSpinStatus) === 1);
            }
            freeModal.classList.add('show');
          }
        } catch(err) {
          console.warn('[QuizRupi FreeSpin] click error:', err);
        }
      }
    }, true);

    // Ensure links with target="_blank" open within the webview smoothly
    document.addEventListener('click', function(e) {
      var a = e.target && e.target.closest ? e.target.closest('a') : null;
      if (a && a.target === '_blank') {
        a.target = '_self';
      }
    }, true);

    if (window.open && !window._origWindowOpen) {
      window._origWindowOpen = window.open;
      window.open = function(url) {
        if (url) {
          window.location.href = url;
          return window;
        }
        return window._origWindowOpen.apply(this, arguments);
      };
    }

    // 3. Define / override window.Android bridge
    window.Android = window.Android || {};

    // Device ID support matching reference WebViewActivity.java
    window.Android.getDeviceId = function() {
      return window._quizRupiDeviceId || '';
    };
    window.Android.requestDeviceId = function() {
      try {
        var id = window._quizRupiDeviceId || '';
        if (typeof window.onReceiveDeviceId === 'function') {
          window.onReceiveDeviceId(id);
        }
      } catch(e) {}
    };

    // Active tab tracker to ensure user returns to the exact same page/tab
    window._currentActiveTab = window._currentActiveTab || 'vip';

    if (typeof window.switchTab === 'function' && !window._quizRupiOrigSwitchTab) {
      window._quizRupiOrigSwitchTab = window.switchTab;
      window.switchTab = function(targetTab, smooth) {
        if (typeof targetTab === 'string') {
          window._currentActiveTab = targetTab;
        } else if (typeof targetTab === 'number') {
          var tabs = ['spin', 'playmore', 'vip'];
          if (tabs[targetTab]) window._currentActiveTab = tabs[targetTab];
        }
        return window._quizRupiOrigSwitchTab.apply(this, arguments);
      };
    }

    var vipTabBtn = document.getElementById('tabVipBtn');
    if (vipTabBtn && !vipTabBtn._quizRupiHooked) {
      vipTabBtn._quizRupiHooked = true;
      vipTabBtn.addEventListener('click', function() { window._currentActiveTab = 'vip'; }, { passive: true });
    }
    var playMoreTabBtn = document.getElementById('tabPlayMoreBtn');
    if (playMoreTabBtn && !playMoreTabBtn._quizRupiHooked) {
      playMoreTabBtn._quizRupiHooked = true;
      playMoreTabBtn.addEventListener('click', function() { window._currentActiveTab = 'playmore'; }, { passive: true });
    }
    var spinTabBtn = document.getElementById('tabSpinBtn');
    if (spinTabBtn && !spinTabBtn._quizRupiHooked) {
      spinTabBtn._quizRupiHooked = true;
      spinTabBtn.addEventListener('click', function() { window._currentActiveTab = 'spin'; }, { passive: true });
    }

    // Hook processUPIResponse to guarantee returning to the same tab on cancel / non-success
    if (typeof window.processUPIResponse === 'function' && !window._quizRupiOrigProcessUPI) {
      window._quizRupiOrigProcessUPI = window.processUPIResponse;
      window.processUPIResponse = function(response, index) {
        var res = window._quizRupiOrigProcessUPI.apply(this, arguments);
        var respStr = String(response || '').toLowerCase();
        if (respStr.indexOf('status=success') === -1) {
          var idx = (typeof index === 'number') ? index : (parseInt(index, 10) || 0);
          var tab = (idx === 4) ? 'vip' :
                    (idx >= 0 && idx < 4) ? 'playmore' :
                    (window._currentActiveTab || 'vip');
          if (typeof window.switchTab === 'function') {
            window.switchTab(tab, false);
          }
        }
        return res;
      };
    }

    // Dynamic price resolver that strictly honors live website prices and DOM elements
    function resolveDynamicWebsitePrice(idx, givenPrice) {
      var raw = String(givenPrice || '').trim();
      var clean = raw.replace(/[^0-9.]/g, '');
      if (clean && parseFloat(clean) > 0) {
        return clean;
      }

      // Check on-page DOM element where card price is rendered in the website
      try {
        if (idx === 0) {
          var r1 = document.getElementById('rate1');
          if (r1 && r1.textContent) {
            var m1 = r1.textContent.match(/[\d.]+/);
            if (m1 && parseFloat(m1[0]) > 0) return m1[0];
          }
        } else if (idx === 1) {
          var r2 = document.getElementById('rate2');
          if (r2 && r2.textContent) {
            var m2 = r2.textContent.match(/[\d.]+/);
            if (m2 && parseFloat(m2[0]) > 0) return m2[0];
          }
        } else if (idx === 2) {
          var r3 = document.getElementById('rate3');
          if (r3 && r3.textContent) {
            var m3 = r3.textContent.match(/[\d.]+/);
            if (m3 && parseFloat(m3[0]) > 0) return m3[0];
          }
        } else if (idx === 3) {
          var r4 = document.getElementById('rate4');
          if (r4 && r4.textContent) {
            var m4 = r4.textContent.match(/[\d.]+/);
            if (m4 && parseFloat(m4[0]) > 0) return m4[0];
          }
        } else if (idx === 4) {
          var vp = document.getElementById('vipPriceVal') ||
                   document.querySelector('#fragmentVip [class*="price"]') ||
                   document.querySelector('#fragmentVip [id*="price"]');
          if (vp && vp.textContent) {
            var mv = vp.textContent.match(/[\d.]+/);
            if (mv && parseFloat(mv[0]) > 0) return mv[0];
          }
        }
      } catch(e) {}

      // Check website spin packages data
      try {
        var pkgs = (typeof currentSpinBuy !== 'undefined' && Array.isArray(currentSpinBuy)) ? currentSpinBuy :
                   (window.SpinPackages && Array.isArray(window.SpinPackages)) ? window.SpinPackages : null;
        if (pkgs && pkgs[idx] && pkgs[idx].price) {
          var cleanPkg = String(pkgs[idx].price).replace(/[^0-9.]/g, '');
          if (cleanPkg && parseFloat(cleanPkg) > 0) return cleanPkg;
        }
      } catch(e) {}

      // If VIP card (idx 4), check website AppData vipAmount
      if (idx === 4) {
        try {
          var appData = (typeof currentAppData !== 'undefined' && currentAppData) ? currentAppData : window.AppData;
          if (appData && appData.vipAmount) {
            var cleanVip = String(appData.vipAmount).replace(/[^0-9.]/g, '');
            if (cleanVip && parseFloat(cleanVip) > 0) return cleanVip;
          }
        } catch(e) {}
      }

      return clean || '10';
    }

    window.Android.startUpiPayment = function(price, orderId, note, upiId, merchantName, index) {
      console.info('[QuizRupi Bridge] startUpiPayment intercepted:', price, orderId, upiId);
      try {
        if (typeof hidePaymentLoadingDialog === 'function') hidePaymentLoadingDialog();
        if (typeof closePaymentGatewayModal === 'function') closePaymentGatewayModal();
        var m = document.getElementById('paymentGatewayModal');
        if (m) {
          m.classList.remove('show');
          m.style.setProperty('display', 'none', 'important');
        }
      } catch(e) {}

      var numIdx = (typeof index === 'number') ? index : (parseInt(index, 10) || 0);
      var effectivePrice = resolveDynamicWebsitePrice(numIdx, price);
      var effectiveNote = String(note || '').trim();
      var effectiveMerchant = String(merchantName || '').trim();

      if (!effectiveNote) {
        if (numIdx === 4 || (note && String(note).toLowerCase().includes('vip'))) {
          effectiveNote = 'VIP Membership - Rs. ' + effectivePrice;
        } else {
          effectiveNote = 'Rozgo Spin';
        }
      }

      if (!effectiveMerchant || effectiveMerchant.toLowerCase().includes('quizrupi')) {
        effectiveMerchant = 'Rozgo Spin';
      }

      if (numIdx === 4 || (effectiveNote && effectiveNote.toLowerCase().includes('vip'))) {
        window._currentActiveTab = 'vip';
      } else if (numIdx >= 0 && numIdx < 4) {
        window._currentActiveTab = 'playmore';
      }

      // Sync window.currentPendingUpiPayment with the exact dynamic website price
      if (window.currentPendingUpiPayment) {
        window.currentPendingUpiPayment.price = effectivePrice;
        window.currentPendingUpiPayment.amount = effectivePrice;
      }

      var payload = {
        price: effectivePrice,
        orderId: String(orderId || ('ORD' + Date.now())),
        note: effectiveNote,
        upiId: String(upiId || ''),
        merchantName: effectiveMerchant,
        index: numIdx
      };

      if (window.QuizRupiBridge && typeof window.QuizRupiBridge.postMessage === 'function') {
        window.QuizRupiBridge.postMessage(JSON.stringify(payload));
      } else {
        var fallbackUrl = 'upi://pay?pa=' + encodeURIComponent(payload.upiId || '') +
          '&pn=' + encodeURIComponent(payload.merchantName || 'Rozgo Spin') +
          '&am=' + encodeURIComponent(payload.price || '10') +
          '&cu=INR&tr=' + encodeURIComponent(payload.orderId || '') +
          '&tn=' + encodeURIComponent(payload.note || 'Rozgo Spin');
        window.location.href = fallbackUrl;
      }
    };

    // 4. Hook openPaymentGatewayModal to completely bypass the popup and honor dynamic price
    window.openPaymentGatewayModal = function(opts) {
      console.info('[QuizRupi Bridge] openPaymentGatewayModal intercepted:', opts);
      if (!opts) opts = {};
      var index = (typeof opts.index === 'number') ? opts.index : (parseInt(opts.index, 10) || 0);
      var price = opts.price || '';
      var orderId = opts.orderId || ('ORD' + Date.now());
      var note = opts.note || (index === 4 ? 'VIP Membership' : 'Rozgo Spin');
      var upi = opts.upi || '';
      var merchant = opts.merchantName || 'Rozgo Spin';

      if (opts.staticURL) {
        try {
          var u = new URL(opts.staticURL);
          if (u.searchParams.get('pa')) upi = u.searchParams.get('pa');
          if (u.searchParams.get('pn')) merchant = u.searchParams.get('pn');
          if (u.searchParams.get('tr')) orderId = u.searchParams.get('tr');
          if (u.searchParams.get('tn')) note = u.searchParams.get('tn');
          if (u.searchParams.get('am')) price = u.searchParams.get('am');
        } catch(e) {}
      }

      if (window.Android && typeof window.Android.startUpiPayment === 'function') {
        window.Android.startUpiPayment(price, orderId, note, upi, merchant, index);
      }
    };

    // 5. Zero-overhead top-level node observer for paymentGatewayModal suppression
    if (!window._quizRupiObserverAttached) {
      window._quizRupiObserverAttached = true;
      var observer = new MutationObserver(function(mutations) {
        for (var i = 0; i < mutations.length; i++) {
          var added = mutations[i].addedNodes;
          for (var j = 0; j < added.length; j++) {
            var n = added[j];
            if (n && n.nodeType === 1 && n.id === 'paymentGatewayModal') {
              n.remove();
            }
          }
        }
      });
      var rootTarget = document.body || document.documentElement;
      if (rootTarget) {
        observer.observe(rootTarget, {
          childList: true,
          subtree: false
        });
      }
    }
  } catch(err) {
    console.error('[QuizRupi Bridge] injection error:', err);
  }
})();
''';

  Future<void> _injectDirectUpiBridge() async {
    try {
      if (_cachedDeviceId.isNotEmpty) {
        await _controller.runJavaScript("window._quizRupiDeviceId = '$_cachedDeviceId';");
      }
      await _controller.runJavaScript(_directUpiBridgeScript);
    } catch (e) {
      debugPrint('[QuizRupi] _injectDirectUpiBridge error: $e');
    }
  }

  Future<void> _handleWebUpiMessage(String rawJson) async {
    debugPrint('[QuizRupi] Received bridge message: $rawJson');
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) return;

      // Handle auth sync messages from webview
      if (decoded['type'] == 'auth_status') {
        final isLoggedIn = decoded['isLoggedIn'] == true;
        _updateCachedLoginState(isLoggedIn);
        return;
      }

      final rawPrice = decoded['price']?.toString() ?? '';
      final orderId = decoded['orderId']?.toString() ?? 'ORD${DateTime.now().millisecondsSinceEpoch}';
      final rawNote = decoded['note']?.toString() ?? '';
      final webUpiId = decoded['upiId']?.toString() ?? '';
      final webMerchant = decoded['merchantName']?.toString() ?? '';
      final index = (decoded['index'] is int)
          ? (decoded['index'] as int)
          : (int.tryParse(decoded['index']?.toString() ?? '0') ?? 0);

      // Check admin app settings for UPI override if configured
      final appSettings = ref.read(appSettingsProvider).settings;
      final adminUpi = appSettings.upiId.trim();
      final adminPayee = appSettings.payeeName.trim();

      // Use admin-configured UPI if set and not default placeholder, else fallback to website's UPI
      final effectiveUpiId = (adminUpi.isNotEmpty && adminUpi != 'quizrupi@upi')
          ? adminUpi
          : (webUpiId.isNotEmpty ? webUpiId : (adminUpi.isNotEmpty ? adminUpi : 'ccpay.79901028186004@icici'));

      // Clean price numeric directly from the website's dynamic payload
      String cleanPriceStr = rawPrice.replaceAll(RegExp(r'[^0-9.]'), '');
      double numPrice = double.tryParse(cleanPriceStr) ?? 0.0;

      // Format amount with 2 decimal places, honoring the exact dynamic price from website
      final formattedAmount = numPrice > 0 ? numPrice.toStringAsFixed(2) : '10.00';

      // Ensure merchant name and note reflect the website only
      final effectiveMerchant = (webMerchant.isNotEmpty && !webMerchant.toLowerCase().contains('quizrupi'))
          ? webMerchant
          : (adminPayee.isNotEmpty && adminPayee != 'QuizRupi Store' ? adminPayee : 'Rozgo Spin');

      final effectiveNote = (rawNote.isNotEmpty && !rawNote.toLowerCase().contains('quizrupi'))
          ? rawNote
          : (index == 4 ? 'VIP Membership - Rs. ${numPrice > 0 ? numPrice.toStringAsFixed(0) : "Plan"}' : 'Rozgo Spin');

      final randomTid = (DateTime.now().millisecondsSinceEpoch % 89999) + 10000;
      final upiUriString = 'upi://pay?'
          'pa=${Uri.encodeComponent(effectiveUpiId)}'
          '&pn=${Uri.encodeComponent(effectiveMerchant)}'
          '&mc=12345'
          '&tid=$randomTid'
          '&tr=${Uri.encodeComponent(orderId)}'
          '&tn=${Uri.encodeComponent(effectiveNote)}'
          '&am=$formattedAmount'
          '&cu=INR';

      debugPrint('[QuizRupi] Direct UPI URI: $upiUriString');
      await _launchUpiIntent(upiUriString: upiUriString, requestCode: index);
    } catch (e) {
      debugPrint('[QuizRupi] _handleWebUpiMessage error: $e');
    }
  }

  Future<void> _launchUpiIntent({
    required String upiUriString,
    required int requestCode,
  }) async {
    _isUpiPaymentActive = true;
    bool handledByPlatform = false;

    try {
      final result = await _upiPlatformChannel.invokeMethod<Map>('launchUpiIntent', {
        'uri': upiUriString,
        'requestCode': requestCode,
      });
      handledByPlatform = true;

      if (mounted) {
        final rawResp = result != null ? (result['response']?.toString() ?? '') : '';
        final response = rawResp.isNotEmpty ? rawResp : 'discard';
        final reqCode = result?['requestCode'] ?? requestCode;
        _notifyWebviewUpiResponse(response, reqCode);
      }
    } catch (e) {
      debugPrint('[QuizRupi] Native platform UPI channel failed: $e. Falling back to url_launcher.');
      if (mounted) {
        _notifyWebviewUpiResponse('discard', requestCode);
      }
    } finally {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          _isUpiPaymentActive = false;
        }
      });
    }

    if (!handledByPlatform) {
      try {
        final uri = Uri.parse(upiUriString);
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
        }
      } catch (e) {
        debugPrint('[QuizRupi] url_launcher fallback error: $e');
      } finally {
        if (mounted) {
          _notifyWebviewUpiResponse('discard', requestCode);
        }
      }
    }
  }

  void _notifyWebviewUpiResponse(String rawResponse, dynamic requestCode) {
    try {
      final reqCodeNum = (requestCode is int) ? requestCode : (int.tryParse(requestCode?.toString() ?? '4') ?? 4);

      // 1. Parse status and approval reference matching reference WebViewActivity.java
      String status = '';
      final trimmed = rawResponse.trim();
      if (trimmed.isNotEmpty && !trimmed.toLowerCase().startsWith('discard')) {
        final params = trimmed.split('&');
        for (final param in params) {
          final parts = param.split('=');
          if (parts.length >= 2) {
            final key = parts[0].trim().toLowerCase();
            final val = parts[1].trim();
            if (key == 'status') {
              status = val.toLowerCase();
            }
          }
        }
      }

      // 2. Classify response matching reference WebViewActivity.java
      String normalizedResponse;
      bool isSuccess = false;

      if (status == 'success') {
        isSuccess = true;
        normalizedResponse = trimmed;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (status == 'failure' || status == 'failed' || trimmed.toLowerCase().contains('fail')) {
        normalizedResponse = 'Status=FAILURE';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment failed. Please try again.'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } else {
        normalizedResponse = 'Status=CANCELLED';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment cancelled'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.amber,
            ),
          );
        }
      }

      final safeNormalizedResponse = jsonEncode(normalizedResponse);

      final js = '''
(function() {
  try {
    if (typeof isPaymentInProgress !== 'undefined') isPaymentInProgress = false;
    if (window.currentPendingUpiPayment) window.currentPendingUpiPayment = null;

    if (typeof hidePaymentLoadingDialog === 'function') hidePaymentLoadingDialog();
    if (typeof closePaymentGatewayModal === 'function') closePaymentGatewayModal();

    var loadingModal = document.getElementById('paymentLoadingModal');
    if (loadingModal) loadingModal.classList.remove('show');

    var gatewayModal = document.getElementById('paymentGatewayModal');
    if (gatewayModal) {
      gatewayModal.classList.remove('show');
      gatewayModal.style.setProperty('display', 'none', 'important');
    }

    var backdrops = document.querySelectorAll('.modal-backdrop');
    for (var i = 0; i < backdrops.length; i++) {
      backdrops[i].remove();
    }
    if (document.body) {
      document.body.classList.remove('modal-open');
      document.body.style.removeProperty('overflow');
    }

    var resp = $safeNormalizedResponse;
    if (typeof window.processUPIResponse === 'function') {
      window.processUPIResponse(resp, $reqCodeNum);
    } else if (typeof window.onUpiResult === 'function') {
      window.onUpiResult(resp);
    }

    if (!$isSuccess && typeof window.switchTab === 'function') {
      var targetTab = ($reqCodeNum === 4) ? 'vip' :
                      ($reqCodeNum >= 0 && $reqCodeNum < 4) ? 'playmore' :
                      (window._currentActiveTab || 'vip');
      window.switchTab(targetTab, false);
    }
  } catch(e) {
    console.warn('[QuizRupi] _notifyWebviewUpiResponse error:', e);
  }
})();
''';
      _controller.runJavaScript(js);
    } catch (e) {
      debugPrint('[QuizRupi] _notifyWebviewUpiResponse error: $e');
    }
  }

  Future<bool> _handlePopScope() async {
    if (_isUpiPaymentActive) return false;

    final currentUrl = await _controller.currentUrl() ?? _currentLoadedUrl;
    final isDashboardOrRoot = currentUrl.contains('dashboard.html') ||
        WebsiteScreen.isLoginPath(currentUrl) ||
        WebsiteScreen.isRootUrl(currentUrl, widget.initialUrl);

    // If not on the main dashboard/login and can go back, navigate back within webview
    if (!isDashboardOrRoot && await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }

    if (!mounted) return true;

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Exit QuizRupi?', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to exit the app?',
          style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      SystemNavigator.pop();
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _loadingProgressNotifier.dispose();
    _postLoadCheckTimer?.cancel();
    _splashFailsafeTimer?.cancel();
    // Restore default app system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.surfaceContainerLowest,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to real-time settings updates from Admin
    ref.listen<AppSettingsState>(appSettingsProvider, (previous, next) {
      final previousSettings = previous?.settings;
      final settings = next.settings;

      // 1. If remote mode switched OFF -> return to store
      if (!settings.isWebsiteModeValid) {
        if (mounted) {
          context.go('/');
        }
        return;
      }

      // 2. Reload if Admin changed the website URL in the database or if current URL doesn't match
      final newUrl = settings.websiteUrl?.trim() ?? '';
      final prevUrl = previousSettings?.websiteUrl?.trim() ?? '';
      if (newUrl.isNotEmpty) {
        final target = WebsiteScreen.resolveTargetWebUrl(newUrl);
        final currentUri = Uri.tryParse(_currentLoadedUrl);
        final targetUri = Uri.tryParse(target);
        final isDifferentHost = currentUri == null || targetUri == null || currentUri.host.toLowerCase() != targetUri.host.toLowerCase();
        final isChanged = (prevUrl.isNotEmpty && prevUrl != newUrl) || isDifferentHost;

        if (isChanged && target != _currentLoadedUrl) {
          _currentLoadedUrl = target;
          _safeLoadUrl(target);
        }
      }
    });

    final effectiveTopColor = _isTransitionComplete ? _topBgColor : AppColors.surface;
    final effectiveBottomColor = _isTransitionComplete ? _bottomBgColor : AppColors.surfaceContainerLowest;
    final effectiveTopBrightness = _isTransitionComplete ? _topBrightness : Brightness.light;
    final effectiveBottomBrightness = _isTransitionComplete ? _bottomBrightness : Brightness.light;
    final effectiveTopIsDark = _isTransitionComplete ? _isTopDark : true;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: effectiveTopColor,
        statusBarIconBrightness: effectiveTopBrightness,
        statusBarBrightness: effectiveTopIsDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: effectiveBottomColor,
        systemNavigationBarIconBrightness: effectiveBottomBrightness,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          await _handlePopScope();
        },
        child: Scaffold(
          backgroundColor: effectiveTopColor,
          body: SafeArea(
            top: true,
            bottom: false,
            child: Stack(
              children: [
                // 1. Fullscreen WebView with smooth transition (GPU layer isolated with RepaintBoundary)
                Positioned.fill(
                  child: _hasError
                      ? _buildErrorView()
                      : RepaintBoundary(
                          child: WebViewWidget.fromPlatformCreationParams(
                            params: _widgetParams,
                          ),
                        ),
                ),

                // 2. Slim loading progress indicator at top (zero-rebuild ValueListenableBuilder)
                if (_isTransitionComplete && _isLoading)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ValueListenableBuilder<double>(
                      valueListenable: _loadingProgressNotifier,
                      builder: (context, progress, _) {
                        if (progress >= 1.0) return const SizedBox.shrink();
                        return LinearProgressIndicator(
                          value: progress,
                          minHeight: 2.5,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isTopDark ? Colors.white : AppColors.primary,
                          ),
                        );
                      },
                    ),
                  ),

                // 3. Splash Screen Overlay: smoothly covers until website is loaded, then cross-fades
                if (!_isTransitionComplete)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: _isPageLoaded,
                      child: AnimatedOpacity(
                        opacity: _isPageLoaded ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        onEnd: () {
                          if (mounted && _isPageLoaded) {
                            setState(() {
                              _isTransitionComplete = true;
                            });
                          }
                        },
                        child: _buildSplashScreenCover(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSplashScreenCover() {
    return Container(
      color: AppColors.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryContainer.withValues(alpha: 0.45),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.lightbulb,
                      size: 48,
                      color: AppColors.secondary,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '₹',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Quiz',
                  style: AppTextStyles.headlineXl.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Rupi',
                  style: AppTextStyles.headlineXl.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Play Quizzes • Earn Points • Win Books',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 44,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Unable to Load Page',
              style: AppTextStyles.headlineSm.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty
                  ? _errorMessage
                  : 'Please check your internet connection and tap retry.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isLoading = true;
                });
                _safeLoadUrl(_currentLoadedUrl);
              },
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
