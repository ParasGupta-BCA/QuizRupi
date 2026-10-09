import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/state_provider_compat.dart';
import '../data/models/profile_model.dart';
import 'auth_provider.dart';

final profileRefreshTriggerProvider = StateProvider<int>((ref) => 0);

final userProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  ref.watch(profileRefreshTriggerProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  final service = ref.watch(supabaseServiceProvider);
  return await service.getProfile(userId);
});
