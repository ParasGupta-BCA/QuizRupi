import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/app_settings_model.dart';
import '../../providers/profile_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../website/website_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _failsafeTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _animController.forward();

    // Guaranteed failsafe timer: max 1.8s on splash screen
    _failsafeTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted && !_hasNavigated) {
        debugPrint('Splash screen failsafe timer triggered navigation');
        _performNavigation(isFailsafe: true);
      }
    });

    // Run session check after first frame is safely drawn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSessionAndNavigate();
    });
  }

  Future<void> _checkSessionAndNavigate() async {
    if (_hasNavigated) return;

    try {
      final minSplashDelay = Future.delayed(const Duration(milliseconds: 500));
      final prefsFuture = SharedPreferences.getInstance();
      final settingsFuture =
          ref.read(appSettingsProvider.notifier).loadInitialSettings();

      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        try {
          ref.read(userProfileProvider.future);
          ref.read(quizCategoriesProvider.future);
          ref.read(booksProvider.future);
          ref.read(todayChallengeProvider.future);
          ref.read(dailyChallengeProgressProvider.future);
        } catch (e) {
          debugPrint('Splash pre-warming notice: $e');
        }
      }

      final results = await Future.wait([
        minSplashDelay,
        prefsFuture,
        settingsFuture,
      ]).timeout(
        const Duration(milliseconds: 1500),
        onTimeout: () => [null, null, null],
      );

      final prefs = results[1] as SharedPreferences?;
      final settings = results[2] as AppSettingsModel? ??
          ref.read(appSettingsProvider).settings;

      _performNavigation(
        prefs: prefs,
        settings: settings,
      );
    } catch (e, st) {
      debugPrint('Error in splash navigation: $e\n$st');
      _performNavigation(isFailsafe: true);
    }
  }

  void _performNavigation({
    SharedPreferences? prefs,
    AppSettingsModel? settings,
    bool isFailsafe = false,
  }) async {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    _failsafeTimer?.cancel();

    final activeSettings = settings ?? ref.read(appSettingsProvider).settings;
    final session = Supabase.instance.client.auth.currentSession;

    // 1. If Remote Website mode is active with a valid HTTPS url, navigate directly to website
    if (activeSettings.isWebsiteModeValid) {
      final adminUrl = activeSettings.websiteUrl?.trim() ?? '';
      final targetUrl = WebsiteScreen.resolveTargetWebUrl(adminUrl);
      if (!mounted) return;
      context.go('/website', extra: {
        'url': targetUrl,
        'title': activeSettings.websiteTitle,
      });
      return;
    }

    // 2. Read onboarding state
    bool hasCompletedOnboarding = false;
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      hasCompletedOnboarding = p.getBool('has_completed_onboarding') ?? false;
    } catch (_) {}

    if (!mounted) return;

    // 3. Otherwise, normal store and quiz flow
    if (session != null) {
      context.go('/');
    } else if (!hasCompletedOnboarding) {
      context.go('/onboarding');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _failsafeTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
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
      ),
    );
  }
}
