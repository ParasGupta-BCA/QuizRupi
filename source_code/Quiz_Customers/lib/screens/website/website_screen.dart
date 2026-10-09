import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/app_settings_provider.dart';
import 'platform_web_view.dart';

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
        final isLoggedIn = forceLoggedIn ?? (cachedIsWebLoggedIn ?? false);
        if (isLoggedIn && cachedUrl.contains('dashboard.html') && isSpinWheelSite(trimmed)) {
          return cachedUrl;
        }
      } else {
        // Different domain! Invalidate the old domain's cached URL and login state
        cachedLastWebUrl = null;
        cachedIsWebLoggedIn = false;
        SharedPreferences.getInstance().then((p) {
          p.remove(keyLastWebUrl);
          p.remove(keyWebLoggedIn);
        }).catchError((_) {});
      }
    }

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
  PlatformWebViewController? _platformController;
  final ValueNotifier<double> _loadingProgressNotifier = ValueNotifier<double>(0.0);
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _currentLoadedUrl = '';

  Timer? _splashFailsafeTimer;
  bool _isPageLoaded = false;
  bool _isTransitionComplete = false;
  bool _isUpiPaymentActive = false;

  static const _upiPlatformChannel = MethodChannel('com.quizrupi.customer/upi');

  @override
  void initState() {
    super.initState();
    final liveSettings = ref.read(appSettingsProvider).settings;
    final adminUrl = liveSettings.isWebsiteModeValid ? liveSettings.websiteUrl?.trim() : null;
    final baseTarget = (adminUrl != null && adminUrl.isNotEmpty) ? adminUrl : widget.initialUrl;

    _currentLoadedUrl = WebsiteScreen.resolveTargetWebUrl(baseTarget);
    _loadCachedLoginState();
    if (!kIsWeb) {
      _fetchDeviceId();
    }

    // Failsafe timer: only if network stalls for 12s, reveal to avoid indefinite freeze
    _splashFailsafeTimer = Timer(const Duration(seconds: 12), () {
      if (mounted && !_isPageLoaded && !_hasError) {
        setState(() {
          _isPageLoaded = true;
        });
      }
    });
  }

  Future<void> _fetchDeviceId() async {
    try {
      await _upiPlatformChannel.invokeMethod<String>('getDeviceId');
    } catch (e) {
      debugPrint('[QuizRupi] _fetchDeviceId error: $e');
    }
  }

  Future<void> _loadCachedLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUrl = prefs.getString(WebsiteScreen.keyLastWebUrl);
      final isLoggedIn = prefs.getBool(WebsiteScreen.keyWebLoggedIn) ?? false;

      final initialUri = Uri.tryParse(_currentLoadedUrl);
      final cachedUri = lastUrl != null ? Uri.tryParse(lastUrl) : null;
      if (initialUri != null && cachedUri != null && initialUri.host.toLowerCase() != cachedUri.host.toLowerCase()) {
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
          _platformController?.loadUrl(target);
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

  Future<void> _handleWebUpiMessage(String rawJson) async {
    debugPrint('[QuizRupi] Received bridge message: $rawJson');
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) return;

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

      final appSettings = ref.read(appSettingsProvider).settings;
      final adminUpi = appSettings.upiId.trim();
      final adminPayee = appSettings.payeeName.trim();

      final effectiveUpiId = (adminUpi.isNotEmpty && adminUpi != 'quizrupi@upi')
          ? adminUpi
          : (webUpiId.isNotEmpty ? webUpiId : (adminUpi.isNotEmpty ? adminUpi : 'ccpay.79901028186004@icici'));

      String cleanPriceStr = rawPrice.replaceAll(RegExp(r'[^0-9.]'), '');
      double numPrice = double.tryParse(cleanPriceStr) ?? 0.0;
      final formattedAmount = numPrice > 0 ? numPrice.toStringAsFixed(2) : '10.00';

      final effectiveMerchant = (webMerchant.isNotEmpty && !webMerchant.toLowerCase().contains('quizrupi'))
          ? webMerchant
          : (adminPayee.isNotEmpty && adminPayee != 'Super Quiz Store' && adminPayee != 'QuizRupi Store' ? adminPayee : 'Rozgo Spin');

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

      // Check if on desktop web without native UPI handler
      final isDesktopWeb = kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.linux);

      if (isDesktopWeb) {
        await _showDesktopUpiPaymentDialog(
          upiId: effectiveUpiId,
          payeeName: effectiveMerchant,
          formattedAmount: formattedAmount,
          orderId: orderId,
          requestCode: index,
        );
      } else {
        await _launchUpiIntent(upiUriString: upiUriString, requestCode: index);
      }
    } catch (e) {
      debugPrint('[QuizRupi] _handleWebUpiMessage error: $e');
    }
  }

  Future<void> _showDesktopUpiPaymentDialog({
    required String upiId,
    required String payeeName,
    required String formattedAmount,
    required String orderId,
    required int requestCode,
  }) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('UPI Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ₹$formattedAmount', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Payee: $payeeName', style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      upiId,
                      style: const TextStyle(color: AppColors.secondary, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.white70),
                    tooltip: 'Copy UPI ID',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: upiId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('UPI ID copied to clipboard'), duration: Duration(seconds: 1)),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please open any UPI app on your phone (GPay, PhonePe, Paytm), pay the amount to the UPI ID above, then tap Paid.',
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _notifyWebviewUpiResponse('discard', requestCode);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _notifyWebviewUpiResponse('Status=SUCCESS&txnRef=$orderId', requestCode);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('I Have Paid'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUpiIntent({
    required String upiUriString,
    required int requestCode,
  }) async {
    _isUpiPaymentActive = true;
    bool handledByPlatform = false;

    if (!kIsWeb) {
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
      } finally {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            _isUpiPaymentActive = false;
          }
        });
      }
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
          _isUpiPaymentActive = false;
          _notifyWebviewUpiResponse('discard', requestCode);
        }
      }
    }
  }

  void _notifyWebviewUpiResponse(String rawResponse, dynamic requestCode) {
    try {
      final reqCodeNum = (requestCode is int) ? requestCode : (int.tryParse(requestCode?.toString() ?? '4') ?? 4);

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

      String normalizedResponse;
      if (status == 'success') {
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

      _platformController?.postResponse(normalizedResponse, reqCodeNum);
    } catch (e) {
      debugPrint('[QuizRupi] _notifyWebviewUpiResponse error: $e');
    }
  }

  Future<bool> _handlePopScope() async {
    if (_isUpiPaymentActive) return false;

    if (!kIsWeb) {
      final currentUrl = await _platformController?.currentUrl() ?? _currentLoadedUrl;
      final isDashboardOrRoot = currentUrl.contains('dashboard.html') ||
          WebsiteScreen.isLoginPath(currentUrl) ||
          WebsiteScreen.isRootUrl(currentUrl, widget.initialUrl);

      if (!isDashboardOrRoot && await (_platformController?.canGoBack() ?? Future.value(false))) {
        await _platformController?.goBack();
        return false;
      }
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
            Text('Exit Super Quiz?', style: TextStyle(color: Colors.white, fontSize: 18)),
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
      if (!kIsWeb) {
        SystemNavigator.pop();
      }
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _loadingProgressNotifier.dispose();
    _splashFailsafeTimer?.cancel();
    if (!kIsWeb) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.surfaceContainerLowest,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to real-time settings updates from Admin
    ref.listen<AppSettingsState>(appSettingsProvider, (previous, next) {
      final settings = next.settings;

      // 1. If remote mode switched OFF -> return to store immediately!
      if (!settings.isWebsiteModeValid) {
        if (mounted) {
          context.go('/');
        }
        return;
      }

      // 2. Reload if Admin changed the website URL in the database
      final newUrl = settings.websiteUrl?.trim() ?? '';
      final prevUrl = previous?.settings.websiteUrl?.trim() ?? '';
      if (newUrl.isNotEmpty) {
        final target = WebsiteScreen.resolveTargetWebUrl(newUrl);
        final currentUri = Uri.tryParse(_currentLoadedUrl);
        final targetUri = Uri.tryParse(target);
        final isDifferentHost = currentUri == null ||
            targetUri == null ||
            currentUri.host.toLowerCase() != targetUri.host.toLowerCase();
        final isChanged = (prevUrl.isNotEmpty && prevUrl != newUrl) || isDifferentHost;

        if (isChanged && target != _currentLoadedUrl) {
          _currentLoadedUrl = target;
          _platformController?.loadUrl(target);
        }
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0B1326),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF0F172A),
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          await _handlePopScope();
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF0B1326),
          body: SafeArea(
            top: true,
            bottom: false,
            child: Stack(
              children: [
                // 1. Platform WebView / iframe
                Positioned.fill(
                  child: _hasError
                      ? _buildErrorView()
                      : RepaintBoundary(
                          child: createPlatformWebViewWidget(
                            initialUrl: _currentLoadedUrl,
                            onControllerCreated: (controller) {
                              _platformController = controller;
                            },
                            onPageStarted: (url) {
                              if (mounted) {
                                setState(() {
                                  _isLoading = true;
                                  _hasError = false;
                                  _errorMessage = '';
                                  _currentLoadedUrl = url;
                                });
                              }
                            },
                            onProgress: (progress) {
                              _loadingProgressNotifier.value = progress;
                              if (progress >= 1.0) {
                                if (mounted && _isLoading) {
                                  setState(() {
                                    _isLoading = false;
                                    _isPageLoaded = true;
                                  });
                                }
                              }
                            },
                            onPageLoaded: (url) {
                              if (mounted) {
                                setState(() {
                                  _isLoading = false;
                                  _isPageLoaded = true;
                                  _currentLoadedUrl = url;
                                });
                              }
                            },
                            onError: (error) {
                              if (mounted && !_isPageLoaded) {
                                setState(() {
                                  _hasError = true;
                                  _errorMessage = error;
                                  _isLoading = false;
                                });
                              }
                            },
                            onUpiMessage: (rawJson) {
                              _handleWebUpiMessage(rawJson);
                            },
                            onAuthStatus: (isLoggedIn) {
                              _updateCachedLoginState(isLoggedIn);
                            },
                          ),
                        ),
                ),

                // 2. Loading progress indicator at top
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
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
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
                        duration: const Duration(milliseconds: 300),
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
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryContainer.withValues(alpha: 0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Super',
                  style: AppTextStyles.headlineXl.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  ' Quiz',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _isLoading = true;
                    });
                    _platformController?.loadUrl(_currentLoadedUrl);
                  },
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text(
                    'Retry',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (kIsWeb) ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.tryParse(_currentLoadedUrl);
                      if (uri != null) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open in Tab'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
