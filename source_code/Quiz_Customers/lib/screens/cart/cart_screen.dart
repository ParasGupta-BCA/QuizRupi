import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  Future<void> _updateQuantity(String cartItemId, int currentQty, int delta) async {
    final newQty = currentQty + delta;
    final service = ref.read(supabaseServiceProvider);

    try {
      await service.updateCartItemQuantity(cartItemId, newQty);
      ref.read(cartRefreshTriggerProvider.notifier).state++;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.crimsonRed, content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _removeItem(String cartItemId) async {
    final service = ref.read(supabaseServiceProvider);
    try {
      await service.removeFromCart(cartItemId);
      ref.read(cartRefreshTriggerProvider.notifier).state++;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.crimsonRed, content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _clearCart() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear Cart?', style: AppTextStyles.headlineSm),
        content: const Text('Are you sure you want to remove all books from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimsonRed),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = ref.read(supabaseServiceProvider);
      await service.clearCart(userId);
      ref.read(cartRefreshTriggerProvider.notifier).state++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartItemsProvider);
    final itemCount = ref.watch(cartItemCountProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final comboDiscount = ref.watch(cartComboDiscountProvider);
    final finalPayable = (subtotal - comboDiscount).clamp(0.0, 99999.0);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/shop');
            }
          },
        ),
        title: Text(
          itemCount > 0 ? 'My Cart ($itemCount items)' : 'My Cart',
          style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (itemCount > 0)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.outline),
              tooltip: 'Clear Cart',
              onPressed: _clearCart,
            ),
        ],
      ),
      body: cartAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 44,
                        color: AppColors.outline,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Your Cart is Empty',
                      style: AppTextStyles.headlineSm.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Explore our bestselling quiz books and build your knowledge arsenal!',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.outline),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/shop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.menu_book, color: Colors.white),
                      label: Text(
                        'Browse Quiz Books',
                        style: AppTextStyles.labelLg.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Combo Deal Promo Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: items.length >= 3
                              ? [
                                  AppColors.emeraldGreen.withOpacity(0.2),
                                  AppColors.surfaceContainerHigh,
                                ]
                              : [
                                  AppColors.secondary.withOpacity(0.2),
                                  AppColors.surfaceContainerHigh,
                                ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: items.length >= 3
                              ? AppColors.emeraldGreen.withOpacity(0.4)
                              : AppColors.secondary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: items.length >= 3
                                  ? AppColors.emeraldGreen.withOpacity(0.2)
                                  : AppColors.secondaryContainer.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              items.length >= 3 ? Icons.celebration : Icons.bolt,
                              color: items.length >= 3 ? AppColors.emeraldGreen : AppColors.secondary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  items.length >= 3
                                      ? '🎉 Mega Combo Deal Applied!'
                                      : 'Mega Combo Deal: 3 for ₹499!',
                                  style: AppTextStyles.labelLg.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  items.length >= 3
                                      ? 'You save ₹${comboDiscount.toInt()} on 3 books combo.'
                                      : 'Add ${3 - items.length} more book(s) to unlock bundle price ₹499',
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (items.length < 3)
                            TextButton(
                              onPressed: () => context.go('/shop'),
                              child: Text(
                                '+ Add',
                                style: AppTextStyles.labelMd.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Items List
                    Text(
                      'Items in Cart',
                      style: AppTextStyles.headlineSm.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final book = item.book;
                        final price = book?.price ?? 199.0;
                        final mrp = book?.mrp ?? 299.0;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.outlineVariant.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Book Cover
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 58,
                                  height: 82,
                                  color: AppColors.surfaceContainerHigh,
                                  child: book?.coverImageUrl != null && book!.coverImageUrl!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: book.coverImageUrl!,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) => const Icon(
                                            Icons.menu_book,
                                            color: AppColors.outline,
                                          ),
                                        )
                                      : const Icon(Icons.menu_book, color: AppColors.outline),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Info & Stepper
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      book?.title ?? 'Quiz Book',
                                      style: AppTextStyles.labelLg.copyWith(
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          '₹${price.toInt()}',
                                          style: AppTextStyles.priceDisplay.copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (mrp > price)
                                          Text(
                                            '₹${mrp.toInt()}',
                                            style: AppTextStyles.bodySm.copyWith(
                                              decoration: TextDecoration.lineThrough,
                                              color: AppColors.outline,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Stepper & Delete
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Quantity selector
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceContainer,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () => _updateQuantity(item.id, item.quantity, -1),
                                                child: Container(
                                                  width: 26,
                                                  height: 26,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.surfaceContainerLowest,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Icon(Icons.remove, size: 14, color: AppColors.onSurface),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                                child: Text(
                                                  '${item.quantity}',
                                                  style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w700),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () => _updateQuantity(item.id, item.quantity, 1),
                                                child: Container(
                                                  width: 26,
                                                  height: 26,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.surfaceContainerLowest,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Icon(Icons.add, size: 14, color: AppColors.onSurface),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Remove button
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.crimsonRed),
                                          onPressed: () => _removeItem(item.id),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Bill Details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.outlineVariant.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bill Details',
                            style: AppTextStyles.headlineSm.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Items Total (${items.length} items)', style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                              Text('₹${subtotal.toInt()}', style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          if (comboDiscount > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Mega Combo Discount', style: AppTextStyles.bodyMd.copyWith(color: AppColors.emeraldGreen)),
                                Text('-₹${comboDiscount.toInt()}', style: AppTextStyles.bodyMd.copyWith(color: AppColors.emeraldGreen, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Delivery Charges', style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                              Text('FREE', style: AppTextStyles.bodyMd.copyWith(color: AppColors.emeraldGreen, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const Divider(height: 24, color: AppColors.outlineVariant),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Payable',
                                style: AppTextStyles.headlineSm.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                '₹${finalPayable.toInt()}',
                                style: AppTextStyles.headlineSm.copyWith(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Sticky Bottom Checkout Footer
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest.withOpacity(0.97),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.outlineVariant.withOpacity(0.2),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Total',
                            style: AppTextStyles.bodySm.copyWith(color: AppColors.outline, fontSize: 11),
                          ),
                          Text(
                            '₹${finalPayable.toInt()}',
                            style: AppTextStyles.headlineSm.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => context.push('/checkout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 2,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Proceed to Checkout',
                                  style: AppTextStyles.labelLg.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryContainer),
        ),
        error: (err, _) => Center(
          child: Text('Error loading cart: $err', style: const TextStyle(color: AppColors.crimsonRed)),
        ),
      ),
    );
  }
}
