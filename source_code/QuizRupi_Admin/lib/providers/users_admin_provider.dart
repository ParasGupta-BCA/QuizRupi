import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/state_provider_compat.dart';
import '../data/models/admin_models.dart';
import 'admin_auth_provider.dart';

final userSearchProvider = StateProvider<String>((ref) => '');

final usersAdminListProvider = FutureProvider<List<UserModel>>((ref) async {
  final service = ref.watch(adminServiceProvider);
  final search = ref.watch(userSearchProvider);
  return await service.getUsers(search: search);
});
