import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/state_provider_compat.dart';
import '../data/models/cart_item_model.dart';
import 'auth_provider.dart';

final cartRefreshTriggerProvider = StateProvider<int>((ref) => 0);

final cartItemsProvider = FutureProvider<List<CartItemModel>>((ref) async {
  ref.watch(cartRefreshTriggerProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  final service = ref.watch(supabaseServiceProvider);
  return await service.getCartItems(userId);
});

final cartItemCountProvider = Provider<int>((ref) {
  final cartAsync = ref.watch(cartItemsProvider);
  return cartAsync.maybeWhen(
    data: (items) => items.fold(0, (sum, item) => sum + item.quantity),
    orElse: () => 0,
  );
});

final cartSubtotalProvider = Provider<double>((ref) {
  final cartAsync = ref.watch(cartItemsProvider);
  return cartAsync.maybeWhen(
    data: (items) {
      double total = 0;
      for (final item in items) {
        final price = item.book?.price ?? 199.0;
        total += price * item.quantity;
      }
      return total;
    },
    orElse: () => 0.0,
  );
});

// Combo Deal: if cart has 3 or more distinct books, bundle price ₹499 for first 3 books!
final cartComboDiscountProvider = Provider<double>((ref) {
  final cartAsync = ref.watch(cartItemsProvider);
  return cartAsync.maybeWhen(
    data: (items) {
      if (items.length >= 3) {
        // Calculate original price of the 3 books
        double firstThreeSum = 0;
        for (int i = 0; i < 3; i++) {
          firstThreeSum += items[i].book?.price ?? 199.0;
        }
        if (firstThreeSum > 499) {
          return firstThreeSum - 499.0;
        }
      }
      return 0.0;
    },
    orElse: () => 0.0,
  );
});
