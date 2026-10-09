import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/state_provider_compat.dart';
import '../data/models/admin_models.dart';
import 'admin_auth_provider.dart';

final orderStatusFilterProvider = StateProvider<String>((ref) => 'All');
final orderSearchProvider = StateProvider<String>((ref) => '');

final ordersAdminListProvider = FutureProvider<List<OrderModel>>((ref) async {
  final service = ref.watch(adminServiceProvider);
  final status = ref.watch(orderStatusFilterProvider);
  final search = ref.watch(orderSearchProvider);
  return await service.getOrders(status: status, search: search);
});
