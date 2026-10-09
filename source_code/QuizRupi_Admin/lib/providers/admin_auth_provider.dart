import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/services/admin_supabase_service.dart';

final adminServiceProvider = Provider<AdminSupabaseService>((ref) {
  return AdminSupabaseService();
});

class AdminAuthState {
  final User? user;
  final bool isAdmin;
  final bool isLoading;
  final bool isInitialized;
  final String? errorMessage;

  const AdminAuthState({
    this.user,
    this.isAdmin = false,
    this.isLoading = false,
    this.isInitialized = false,
    this.errorMessage,
  });

  AdminAuthState copyWith({
    User? user,
    bool? isAdmin,
    bool? isLoading,
    bool? isInitialized,
    String? errorMessage,
  }) {
    return AdminAuthState(
      user: user ?? this.user,
      isAdmin: isAdmin ?? this.isAdmin,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: errorMessage,
    );
  }
}

class AdminAuthNotifier extends Notifier<AdminAuthState> {
  static const _prefKeyAdminAuth = 'is_admin_authenticated';
  static const _prefKeyAdminEmail = 'saved_admin_email';

  @override
  AdminAuthState build() {
    final client = ref.watch(adminServiceProvider).client;
    final initialUser = client.auth.currentUser;

    // Listen to Supabase auth events
    client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) {
        state = const AdminAuthState(
          user: null,
          isAdmin: false,
          isInitialized: true,
          isLoading: false,
        );
      }
    });

    if (initialUser != null) {
      return AdminAuthState(user: initialUser, isAdmin: true, isInitialized: false, isLoading: false);
    }

    return const AdminAuthState(user: null, isAdmin: false, isInitialized: false, isLoading: false);
  }

  /// Called by AdminSplashScreen to verify and restore saved admin session
  Future<bool> initializeAndVerify() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSavedAdminAuth = prefs.getBool(_prefKeyAdminAuth) ?? false;
      final service = ref.read(adminServiceProvider);
      final currentSession = service.client.auth.currentSession;
      final currentUser = service.client.auth.currentUser;

      if (currentUser != null && (hasSavedAdminAuth || currentSession != null)) {
        // Fast verification with Supabase
        final isAdmin = await service.checkIsAdmin();
        if (isAdmin) {
          await prefs.setBool(_prefKeyAdminAuth, true);
          if (currentUser.email != null) {
            await prefs.setString(_prefKeyAdminEmail, currentUser.email!);
          }
          state = AdminAuthState(
            user: currentUser,
            isAdmin: true,
            isInitialized: true,
            isLoading: false,
          );
          return true;
        } else {
          // Admin privilege was revoked
          await prefs.remove(_prefKeyAdminAuth);
          await service.signOut();
          state = const AdminAuthState(
            user: null,
            isAdmin: false,
            isInitialized: true,
            isLoading: false,
            errorMessage: 'Access denied: Administrator privileges revoked.',
          );
          return false;
        }
      }

      state = const AdminAuthState(
        user: null,
        isAdmin: false,
        isInitialized: true,
        isLoading: false,
      );
      return false;
    } catch (e) {
      debugPrint('Session initialization notice: $e');
      state = const AdminAuthState(
        user: null,
        isAdmin: false,
        isInitialized: true,
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final service = ref.read(adminServiceProvider);
      final response = await service.signInWithPassword(email, password);

      if (response.user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_prefKeyAdminAuth, true);
        await prefs.setString(_prefKeyAdminEmail, email.trim());

        state = AdminAuthState(
          user: response.user,
          isAdmin: true,
          isInitialized: true,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Login failed. Please check credentials.',
        );
        return false;
      }
    } on AuthException catch (e) {
      String msg = e.message;
      if (msg.toLowerCase().contains('invalid login credentials')) {
        msg = 'Invalid email or password. Please check your credentials.';
      } else if (msg.toLowerCase().contains('email not confirmed')) {
        msg = 'Email address is not confirmed.';
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: msg,
      );
      return false;
    } catch (e) {
      String msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.contains('AuthRetryableFetchException') || msg.contains('unexpected_failure')) {
        msg = 'Authentication service error. Please check credentials or try again.';
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: msg,
      );
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeyAdminAuth);
    } catch (_) {}

    final service = ref.read(adminServiceProvider);
    await service.signOut();
    state = const AdminAuthState(user: null, isAdmin: false, isInitialized: true, isLoading: false);
  }
}

final adminAuthProvider = NotifierProvider<AdminAuthNotifier, AdminAuthState>(() {
  return AdminAuthNotifier();
});
