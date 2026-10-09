import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/state_provider_compat.dart';
import '../data/models/order_model.dart';
import '../data/models/address_model.dart';
import 'auth_provider.dart';

final ordersRefreshTriggerProvider = StateProvider<int>((ref) => 0);

final userOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  ref.watch(ordersRefreshTriggerProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  final service = ref.watch(supabaseServiceProvider);
  return await service.getUserOrders(userId);
});

final orderDetailProvider =
    FutureProvider.family<OrderModel?, String>((ref, orderId) async {
  final service = ref.watch(supabaseServiceProvider);
  return await service.getOrderById(orderId);
});

final userAddressesProvider = FutureProvider<List<AddressModel>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  final service = ref.watch(supabaseServiceProvider);
  return await service.getAddresses(userId);
});
