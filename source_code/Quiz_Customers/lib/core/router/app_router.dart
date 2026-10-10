import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_scaffold_with_nav.dart';
import '../../data/models/badge_model.dart';

// Screens
import '../../screens/splash/splash_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/quiz/quiz_arena_screen.dart';
import '../../screens/quiz/live_quiz_session_screen.dart';
import '../../screens/quiz/quiz_result_screen.dart';
import '../../screens/quiz/live_battle_arena_screen.dart';
import '../../screens/shop/shop_screen.dart';
import '../../screens/shop/book_detail_screen.dart';
import '../../screens/cart/cart_screen.dart';
import '../../screens/cart/checkout_screen.dart';
import '../../screens/cart/order_confirmation_screen.dart';
import '../../screens/profile/profile_orders_screen.dart';
import '../../screens/orders/order_tracking_screen.dart';
import '../../screens/wallet/wallet_history_screen.dart';
import '../../screens/profile/saved_addresses_screen.dart';
import '../../screens/profile/quiz_history_screen.dart';
import '../../screens/profile/refer_earn_screen.dart';
import '../../screens/website/website_screen.dart';
import '../../providers/app_settings_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen(appSettingsProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: RouterRefreshNotifier(ref),
    redirect: (context, state) {
      final appSettingsState = ref.read(appSettingsProvider);
      final session = Supabase.instance.client.auth.currentSession;
      final path = state.uri.path;
      final isAuthRoute = path == '/login' ||
          path == '/signup' ||
          path == '/splash' ||
          path == '/onboarding' ||
          path == '/website';

      // 1. Initial Loading State:
      // While initial settings are loading, maintain splash screen so cold start plays cleanly
      if (appSettingsState.isLoading) {
        if (path != '/splash') {
          return '/splash';
        }
        return null;
      }

      final isWebsiteMode = appSettingsState.settings.isWebsiteModeValid;

      // 2. Remote Website Mode is ACTIVE:
      if (isWebsiteMode) {
        // Allow splash screen to finish animation cleanly
        if (path == '/splash') {
          return null;
        }
        // Force all routes to /website when website mode is active
        if (path != '/website') {
          return '/website';
        }
        return null;
      }

      // 3. Remote Website Mode is INACTIVE (Store / Quiz Mode):
      // If user is currently on /website, return them to the store
      if (path == '/website') {
        return session != null ? '/' : '/login';
      }

      // User must log in first: if no active session and not on an auth screen, force to login
      if (session == null && !isAuthRoute) {
        return '/login';
      }

      // If already logged in and on login or signup screen, redirect to home
      if (session != null && (path == '/login' || path == '/signup')) {
        return '/';
      }

      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.explore_off_rounded,
                    size: 44,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Page Not Found',
                  style: AppTextStyles.headlineSm.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The requested page (${state.uri.path}) does not exist.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: () => context.go('/'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.home, size: 20),
                  label: const Text(
                    'Return to Home',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    routes: [
      // Splash & Onboarding
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Remote Website Screen (Remote Control full screen WebView)
      GoRoute(
        path: '/website',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final settings = ref.read(appSettingsProvider).settings;
          final adminUrl = settings.isWebsiteModeValid ? settings.websiteUrl?.trim() : null;
          final rawUrl = (adminUrl != null && adminUrl.isNotEmpty)
              ? adminUrl
              : (extra?['url'] as String? ??
                  state.uri.queryParameters['url'] ??
                  'https://quizrupi.com');
          final resolvedUrl = WebsiteScreen.resolveTargetWebUrl(rawUrl);
          final title = extra?['title'] as String? ??
              state.uri.queryParameters['title'] ??
              settings.websiteTitle;
          return WebsiteScreen(
            initialUrl: resolvedUrl,
            initialTitle: title,
          );
        },
      ),

      // Auth
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // /home redirect alias to main Home branch
      GoRoute(
        path: '/home',
        redirect: (context, state) => '/',
      ),

      // Main Navigation Tabs Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppScaffoldWithNav(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Branch 1: Quiz Arena
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/quiz',
                builder: (context, state) => const QuizArenaScreen(),
              ),
            ],
          ),

          // Branch 2: Shop
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shop',
                builder: (context, state) => const ShopScreen(),
              ),
            ],
          ),

          // Branch 3: Profile & Orders
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileOrdersScreen(),
              ),
            ],
          ),
        ],
      ),

      // Quiz Sub-Routes
      GoRoute(
        path: '/quiz-session',
        builder: (context, state) {
          final catId = state.uri.queryParameters['categoryId'] ?? '';
          final mode = state.uri.queryParameters['mode'] ?? 'solo';
          final title = state.uri.queryParameters['title'] ?? 'Quiz Session';
          return LiveQuizSessionScreen(
            categoryId: catId,
            mode: mode,
            title: title,
          );
        },
      ),
      GoRoute(
        path: '/quiz/session/:categoryId',
        builder: (context, state) {
          final catId = state.pathParameters['categoryId'] ??
              state.uri.queryParameters['categoryId'] ??
              '';
          final mode = state.uri.queryParameters['mode'] ?? 'solo';
          final title = state.uri.queryParameters['title'] ?? 'Quiz Session';
          return LiveQuizSessionScreen(
            categoryId: catId,
            mode: mode,
            title: title,
          );
        },
      ),
      GoRoute(
        path: '/quiz-result',
        builder: (context, state) {
          final extra = state.extra;
          final score = int.tryParse(state.uri.queryParameters['score'] ?? '') ??
              (extra is Map ? extra['score'] as int? ?? 0 : 0);
          final correct = int.tryParse(state.uri.queryParameters['correct'] ??
                  state.uri.queryParameters['correctCount'] ??
                  '') ??
              (extra is Map ? extra['correctCount'] as int? ?? 0 : 0);
          final total = int.tryParse(state.uri.queryParameters['total'] ??
                  state.uri.queryParameters['totalQuestions'] ??
                  '') ??
              (extra is Map ? extra['totalQuestions'] as int? ?? 10 : 10);
          final coins = int.tryParse(state.uri.queryParameters['coins'] ??
                  state.uri.queryParameters['coinsEarned'] ??
                  '') ??
              (extra is Map ? extra['coinsEarned'] as int? ?? 0 : 0);
          final xp = int.tryParse(state.uri.queryParameters['xp'] ??
                  state.uri.queryParameters['xpEarned'] ??
                  '') ??
              (extra is Map ? extra['xpEarned'] as int? ?? 0 : 0);
          final badges = extra is List<BadgeModel>
              ? extra
              : (extra is Map && extra['newBadges'] is List<BadgeModel>
                  ? extra['newBadges'] as List<BadgeModel>
                  : <BadgeModel>[]);
          return QuizResultScreen(
            score: score,
            correctCount: correct,
            totalQuestions: total,
            coinsEarned: coins,
            xpEarned: xp,
            newBadges: badges,
          );
        },
      ),
      GoRoute(
        path: '/quiz/result',
        builder: (context, state) {
          final extra = state.extra;
          final score = int.tryParse(state.uri.queryParameters['score'] ?? '') ??
              (extra is Map ? extra['score'] as int? ?? 0 : 0);
          final correct = int.tryParse(state.uri.queryParameters['correct'] ??
                  state.uri.queryParameters['correctCount'] ??
                  '') ??
              (extra is Map ? extra['correctCount'] as int? ?? 0 : 0);
          final total = int.tryParse(state.uri.queryParameters['total'] ??
                  state.uri.queryParameters['totalQuestions'] ??
                  '') ??
              (extra is Map ? extra['totalQuestions'] as int? ?? 10 : 10);
          final coins = int.tryParse(state.uri.queryParameters['coins'] ??
                  state.uri.queryParameters['coinsEarned'] ??
                  '') ??
              (extra is Map ? extra['coinsEarned'] as int? ?? 0 : 0);
          final xp = int.tryParse(state.uri.queryParameters['xp'] ??
                  state.uri.queryParameters['xpEarned'] ??
                  '') ??
              (extra is Map ? extra['xpEarned'] as int? ?? 0 : 0);
          final badges = extra is List<BadgeModel>
              ? extra
              : (extra is Map && extra['newBadges'] is List<BadgeModel>
                  ? extra['newBadges'] as List<BadgeModel>
                  : <BadgeModel>[]);
          return QuizResultScreen(
            score: score,
            correctCount: correct,
            totalQuestions: total,
            coinsEarned: coins,
            xpEarned: xp,
            newBadges: badges,
          );
        },
      ),
      GoRoute(
        path: '/live-battle',
        builder: (context, state) {
          final catId = state.uri.queryParameters['categoryId'] ?? '';
          final catName =
              state.uri.queryParameters['categoryName'] ?? 'General Knowledge';
          return LiveBattleArenaScreen(
            categoryId: catId,
            categoryName: catName,
          );
        },
      ),
      GoRoute(
        path: '/quiz/battle',
        builder: (context, state) {
          final catId = state.uri.queryParameters['categoryId'] ?? '';
          final catName =
              state.uri.queryParameters['categoryName'] ?? 'General Knowledge';
          return LiveBattleArenaScreen(
            categoryId: catId,
            categoryName: catName,
          );
        },
      ),

      // Book Details
      GoRoute(
        path: '/book/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return BookDetailScreen(bookId: id);
        },
      ),
      GoRoute(
        path: '/book',
        builder: (context, state) {
          final id = state.uri.queryParameters['id'] ?? '';
          return BookDetailScreen(bookId: id);
        },
      ),

      // Cart & Checkout
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/order-confirmation/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return OrderConfirmationScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/order-confirmation',
        builder: (context, state) {
          final orderId = state.uri.queryParameters['orderId'] ?? '';
          return OrderConfirmationScreen(orderId: orderId);
        },
      ),

      // Orders Tracking
      GoRoute(
        path: '/order-tracking/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return OrderTrackingScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/order-tracking',
        builder: (context, state) {
          final orderId = state.uri.queryParameters['orderId'] ?? '';
          return OrderTrackingScreen(orderId: orderId);
        },
      ),

      // Wallet
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletHistoryScreen(),
      ),

      // Addresses
      GoRoute(
        path: '/addresses',
        builder: (context, state) => const SavedAddressesScreen(),
      ),

      // Quiz History
      GoRoute(
        path: '/quiz-history',
        builder: (context, state) => const QuizHistoryScreen(),
      ),

      // Refer & Earn
      GoRoute(
        path: '/refer-earn',
        builder: (context, state) => const ReferEarnScreen(),
      ),
    ],
  );
});
