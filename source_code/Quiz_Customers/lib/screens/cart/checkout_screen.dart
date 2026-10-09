import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/address_model.dart';
import '../../data/models/app_settings_model.dart';
import '../../data/models/cart_item_model.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  AddressModel? _selectedAddress;
  String _selectedPaymentMethod = 'UPI';
  bool _isSubmitting = false;

  void _showAddAddressDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final line1Ctrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final stateCtrl = TextEditingController(text: 'Delhi');
    final pinCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Delivery Address',
                    style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildInputField(nameCtrl, 'Full Name', Icons.person),
              const SizedBox(height: 10),
              _buildInputField(phoneCtrl, '10-Digit Mobile Number', Icons.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 10),
              _buildInputField(line1Ctrl, 'House / Flat No, Street, Area', Icons.home),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildInputField(cityCtrl, 'City', Icons.location_city)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildInputField(stateCtrl, 'State', Icons.map)),
                ],
              ),
              const SizedBox(height: 10),
              _buildInputField(pinCtrl, '6-Digit Pincode', Icons.pin_drop, keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty ||
                        phoneCtrl.text.isEmpty ||
                        line1Ctrl.text.isEmpty ||
                        pinCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all required fields')),
                      );
                      return;
                    }

                    final userId = ref.read(currentUserIdProvider);
                    if (userId == null) return;

                    final newAddress = AddressModel(
                      userId: userId,
                      fullName: nameCtrl.text.trim(),
                      phoneNumber: phoneCtrl.text.trim(),
                      addressLine1: line1Ctrl.text.trim(),
                      city: cityCtrl.text.trim().isEmpty ? 'New Delhi' : cityCtrl.text.trim(),
                      state: stateCtrl.text.trim().isEmpty ? 'Delhi' : stateCtrl.text.trim(),
                      pincode: pinCtrl.text.trim(),
                      isDefault: true,
                    );

                    final service = ref.read(supabaseServiceProvider);
                    final saved = await service.addAddress(newAddress);
                    ref.invalidate(userAddressesProvider);

                    if (mounted) {
                      setState(() {
                        _selectedAddress = saved;
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Address', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodySm.copyWith(color: AppColors.outline),
          prefixIcon: Icon(icon, size: 18, color: AppColors.outline),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Future<void> _handlePlaceOrder() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      context.push('/login');
      return;
    }

    final cartItems = ref.read(cartItemsProvider).value ?? [];
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }

    final deliveryAddress = _selectedAddress != null
        ? '${_selectedAddress!.fullName}, ${_selectedAddress!.addressLine1}, ${_selectedAddress!.city}, ${_selectedAddress!.state} - ${_selectedAddress!.pincode} (Ph: ${_selectedAddress!.phoneNumber})'
        : '123, Green Park, Hauz Khas, New Delhi - 110016 (Ph: 9876543210)';

    final subtotal = ref.read(cartSubtotalProvider);
    final comboDiscount = ref.read(cartComboDiscountProvider);
    final totalDiscount = comboDiscount;
    final finalTotal = (subtotal - totalDiscount).clamp(0.0, 99999.0);

    final appSettings = ref.read(appSettingsProvider).settings;
    if (!appSettings.isUpiEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('UPI payment is temporarily paused by admin. Please contact support.'),
          backgroundColor: AppColors.crimsonRed,
        ),
      );
      return;
    }

    _showUpiPaymentSheet(
      userId: userId,
      deliveryAddress: deliveryAddress,
      subtotal: subtotal,
      totalDiscount: totalDiscount,
      finalTotal: finalTotal,
      cartItems: cartItems,
      appSettings: appSettings,
    );
  }

  void _showUpiPaymentSheet({
    required String userId,
    required String deliveryAddress,
    required double subtotal,
    required double totalDiscount,
    required double finalTotal,
    required List<CartItemModel> cartItems,
    required AppSettingsModel appSettings,
  }) {
    final upiId = appSettings.upiId;
    final payeeName = appSettings.payeeName;
    final txnRef = 'QR${DateTime.now().millisecondsSinceEpoch}';
    final utrController = TextEditingController();

    // Standard NPCI compliant UPI Intent URI
    final upiUri = Uri.parse(
      'upi://pay?pa=$upiId'
      '&pn=${Uri.encodeComponent(payeeName)}'
      '&am=${finalTotal.toStringAsFixed(2)}'
      '&cu=INR'
      '&tn=${Uri.encodeComponent("QuizRupi Books Order")}'
      '&tr=$txnRef',
    );

    // Launch UPI Intent automatically in the background
    Future.microtask(() async {
      try {
        await launchUrl(upiUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('Auto UPI intent launch error: $e');
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetCtx) {
        bool isSubmittingUpi = false;
        return StatefulBuilder(
          builder: (ctx, setModalState) {

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.account_balance_wallet, color: AppColors.primaryContainer, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pay via UPI',
                              style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.w800, fontSize: 18),
                            ),
                            Text(
                              'Google Pay • PhonePe • Paytm • BHIM • CRED',
                              style: AppTextStyles.bodySm.copyWith(color: AppColors.outline, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(bottomSheetCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Amount & Payee Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryContainer.withOpacity(0.12),
                          AppColors.surfaceContainerLowest,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryContainer.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text('Amount Payable', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text(
                          '₹${finalTotal.toInt()}',
                          style: AppTextStyles.headlineSm.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryContainer,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'UPI ID: $upiId',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: upiId));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('UPI ID copied to clipboard!')),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.copy, size: 12, color: AppColors.primaryContainer),
                                    SizedBox(width: 4),
                                    Text('Copy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryContainer)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Payee: $payeeName',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Open UPI App Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await launchUrl(upiUri, mode: LaunchMode.externalApplication);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Could not open UPI app: $e. You can copy the UPI ID above.')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Open UPI App (GPay / PhonePe / Paytm)', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryContainer),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Optional UTR Entry
                  Text(
                    'UPI Reference / 12-digit UTR No. (Optional)',
                    style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: utrController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 3287xxxxxxxx',
                        prefixIcon: Icon(Icons.tag, size: 18),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Order Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSubmittingUpi
                          ? null
                          : () async {
                              setModalState(() => isSubmittingUpi = true);
                              Navigator.pop(bottomSheetCtx);
                              await _submitOrder(
                                userId: userId,
                                deliveryAddress: deliveryAddress,
                                subtotal: subtotal,
                                totalDiscount: totalDiscount,
                                finalTotal: finalTotal,
                                cartItems: cartItems,
                                paymentMethod: 'UPI',
                                upiRef: utrController.text.trim(),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'I Have Paid • Confirm Order',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(bottomSheetCtx),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

  Future<void> _submitOrder({
    required String userId,
    required String deliveryAddress,
    required double subtotal,
    required double totalDiscount,
    required double finalTotal,
    required List<CartItemModel> cartItems,
    required String paymentMethod,
    String? upiRef,
  }) async {
    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(supabaseServiceProvider);
      final order = await service.placeOrder(
        userId: userId,
        addressId: _selectedAddress?.id,
        deliveryAddress: deliveryAddress,
        subtotal: subtotal,
        deliveryCharge: 0.0,
        discountApplied: totalDiscount,
        coinsRedeemed: 0,
        totalAmount: finalTotal,
        paymentMethod: paymentMethod,
        items: cartItems,
        upiRef: upiRef,
      );

      // Refresh providers
      ref.read(cartRefreshTriggerProvider.notifier).state++;
      ref.read(ordersRefreshTriggerProvider.notifier).state++;
      ref.read(profileRefreshTriggerProvider.notifier).state++;

      if (mounted) {
        context.go('/order-confirmation/${order.id}');
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.crimsonRed, content: Text('Order failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartItemsProvider).value ?? [];
    final addressesAsync = ref.watch(userAddressesProvider);
    final appSettings = ref.watch(appSettingsProvider).settings;

    final subtotal = ref.watch(cartSubtotalProvider);
    final comboDiscount = ref.watch(cartComboDiscountProvider);

    final totalDiscount = comboDiscount;
    final finalPayable = (subtotal - totalDiscount).clamp(0.0, 99999.0);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Checkout',
          style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery Address Card
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.primaryContainer, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Delivery Address',
                            style: AppTextStyles.headlineSm.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _showAddAddressDialog,
                        child: Text(
                          _selectedAddress == null ? '+ Add Address' : 'Change',
                          style: AppTextStyles.labelMd.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  addressesAsync.when(
                    data: (addresses) {
                      if (addresses.isNotEmpty && _selectedAddress == null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _selectedAddress = addresses.first);
                        });
                      }

                      final addr = _selectedAddress ?? (addresses.isNotEmpty ? addresses.first : null);

                      if (addr != null) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    addr.fullName,
                                    style: AppTextStyles.labelLg.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'HOME',
                                      style: AppTextStyles.labelSm.copyWith(
                                        fontSize: 9,
                                        color: AppColors.primaryContainer,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${addr.addressLine1}, ${addr.city}, ${addr.state} - ${addr.pincode}',
                                style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Mobile: ${addr.phoneNumber}',
                                style: AppTextStyles.bodySm.copyWith(color: AppColors.outline),
                              ),
                            ],
                          ),
                        );
                      }

                      // Fallback default address preview
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Rohan Kumar', style: AppTextStyles.labelLg.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('123, Green Park, Hauz Khas, New Delhi - 110016',
                                style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Text('Mobile: +91 98765 43210', style: AppTextStyles.bodySm.copyWith(color: AppColors.outline)),
                          ],
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Text('Could not load addresses'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment Method Selector
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
                    'Payment Method',
                    style: AppTextStyles.headlineSm.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption(
                    'UPI',
                    appSettings.isUpiEnabled
                        ? 'Google Pay / PhonePe / Paytm • ${appSettings.upiId}'
                        : 'UPI Payments Temporarily Paused',
                    Icons.account_balance_wallet,
                    isRecommended: appSettings.isUpiEnabled,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Order Summary & Bill
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
                    'Order Summary',
                    style: AppTextStyles.headlineSm.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  ...cartItems.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Text('${item.quantity}x ', style: AppTextStyles.labelMd.copyWith(color: AppColors.primaryContainer)),
                            Expanded(
                              child: Text(
                                item.book?.title ?? 'Quiz Book',
                                style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurface),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '₹${((item.book?.price ?? 199.0) * item.quantity).toInt()}',
                              style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      )),
                  const Divider(height: 20, color: AppColors.outlineVariant),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal', style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                      Text('₹${subtotal.toInt()}', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (comboDiscount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Mega Combo Discount', style: AppTextStyles.bodyMd.copyWith(color: AppColors.emeraldGreen)),
                        Text('-₹${comboDiscount.toInt()}', style: AppTextStyles.bodyMd.copyWith(color: AppColors.emeraldGreen, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Delivery', style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                      Text('FREE', style: AppTextStyles.bodyMd.copyWith(color: AppColors.emeraldGreen, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const Divider(height: 20, color: AppColors.outlineVariant),
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
                          fontSize: 20,
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
      bottomNavigationBar: Container(
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
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handlePlaceOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryContainer,
              foregroundColor: AppColors.onSecondaryFixed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: AppColors.onSecondaryFixed, strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Place Order • ₹${finalPayable.toInt()}',
                        style: AppTextStyles.labelLg.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSecondaryFixed,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String methodKey, String label, IconData icon, {bool isRecommended = false}) {
    final isSelected = _selectedPaymentMethod == methodKey;

    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = methodKey),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer.withOpacity(0.12) : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryContainer : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primaryContainer : AppColors.outline,
              size: 20,
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 20, color: isSelected ? AppColors.primaryContainer : AppColors.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        methodKey,
                        style: AppTextStyles.labelMd.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.primaryContainer : AppColors.onSurface,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'RECOMMENDED',
                            style: AppTextStyles.labelSm.copyWith(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: AppColors.emeraldGreen,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    label,
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
