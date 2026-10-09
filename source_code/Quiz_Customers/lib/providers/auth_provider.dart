import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/services/supabase_service.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return service.authStateChanges;
});

final currentUserIdProvider = Provider<String?>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return service.currentUserId;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return service.currentUser != null;
});

class AuthNotifier extends Notifier<User?> {
  @override
  User? build() {
    return ref.watch(supabaseServiceProvider).currentUser;
  }

  Future<void> signOut() async {
    await ref.read(supabaseServiceProvider).signOut();
    state = null;
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, User?>(() => AuthNotifier());

