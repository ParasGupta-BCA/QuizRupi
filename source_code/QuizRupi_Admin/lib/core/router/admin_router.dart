import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/responsive_scaffold.dart';
import '../../providers/admin_auth_provider.dart';
import '../../screens/auth/admin_login_screen.dart';
import '../../screens/splash/admin_splash_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/app_control/app_control_screen.dart';
import '../../screens/books/books_management_screen.dart';
import '../../screens/orders/orders_management_screen.dart';
import '../../screens/users/users_management_screen.dart';
import '../../screens/quiz/quiz_management_screen.dart';
import '../../screens/promotions/promotions_management_screen.dart';
import '../../screens/settings/settings_screen.dart';

class AdminRouterNotifier extends ChangeNotifier {
  final Ref _ref;

  AdminRouterNotifier(this._ref) {
    _ref.listen<AdminAuthState>(adminAuthProvider, (_, __) => notifyListeners());
  }
}

final adminRouterNotifierProvider = Provider<AdminRouterNotifier>((ref) {
  return AdminRouterNotifier(ref);
});

final adminRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(adminRouterNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(adminAuthProvider);
      final isLoggedIn = authState.user != null && authState.isAdmin;
      final isSplash = state.uri.path == '/splash';
      final isLoginPage = state.uri.path == '/login';

      // 1. Let splash screen complete initial session verification and routing
      if (isSplash) {
        return null;
      }

      // 2. Redirect unauthenticated users to /login
      if (!isLoggedIn && !isLoginPage) {
        return '/login';
      }

      // 3. Redirect authenticated admins from login page to dashboard
      if (isLoggedIn && isLoginPage) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const AdminSplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/',
        redirect: (context, state) => '/dashboard',
      ),
      ShellRoute(
        builder: (context, state, child) {
          return ResponsiveScaffold(
            currentRoute: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/app-control',
            pageBuilder: (context, state) => const NoTransitionPage(child: AppControlScreen()),
          ),
          GoRoute(
            path: '/books',
            pageBuilder: (context, state) => const NoTransitionPage(child: BooksManagementScreen()),
          ),
          GoRoute(
            path: '/orders',
            pageBuilder: (context, state) => const NoTransitionPage(child: OrdersManagementScreen()),
          ),
          GoRoute(
            path: '/users',
            pageBuilder: (context, state) => const NoTransitionPage(child: UsersManagementScreen()),
          ),
          GoRoute(
            path: '/quiz',
            pageBuilder: (context, state) => const NoTransitionPage(child: QuizManagementScreen()),
          ),
          GoRoute(
            path: '/promotions',
            pageBuilder: (context, state) => const NoTransitionPage(child: PromotionsManagementScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
    ],
  );
});
