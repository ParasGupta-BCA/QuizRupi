import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/address_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';

class SavedAddressesScreen extends ConsumerStatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  ConsumerState<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends ConsumerState<SavedAddressesScreen> {
  void _openAddAddressModal() {
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
                    'Add New Address',
                    style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildField(nameCtrl, 'Full Name', Icons.person),
              const SizedBox(height: 10),
              _buildField(phoneCtrl, '10-Digit Mobile Number', Icons.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 10),
              _buildField(line1Ctrl, 'House / Flat No, Street, Landmark', Icons.home),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildField(cityCtrl, 'City', Icons.location_city)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildField(stateCtrl, 'State', Icons.map)),
                ],
              ),
              const SizedBox(height: 10),
              _buildField(pinCtrl, '6-Digit PIN Code', Icons.pin_drop, keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty || line1Ctrl.text.isEmpty || pinCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all mandatory fields')),
                      );
                      return;
                    }

                    final userId = ref.read(currentUserIdProvider);
                    if (userId == null) return;

                    final address = AddressModel(
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
                    await service.addAddress(address);
                    ref.invalidate(userAddressesProvider);

                    if (mounted) Navigator.pop(ctx);
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

  Widget _buildField(
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

  @override
  Widget build(BuildContext context) {
    final addressesAsync = ref.watch(userAddressesProvider);

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
          'Saved Delivery Addresses',
          style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primaryContainer),
            onPressed: _openAddAddressModal,
          ),
        ],
      ),
      body: addressesAsync.when(
        data: (addresses) {
          if (addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off, size: 48, color: AppColors.outline),
                  const SizedBox(height: 12),
                  Text('No saved addresses yet', style: AppTextStyles.headlineSm),
                  const SizedBox(height: 6),
                  Text(
                    'Add your shipping address for fast book checkout',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.outline),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _openAddAddressModal,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryContainer),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Add Address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final addr = addresses[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              addr.fullName,
                              style: AppTextStyles.labelLg.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 8),
                            if (addr.isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'DEFAULT',
                                  style: AppTextStyles.labelSm.copyWith(
                                    fontSize: 9,
                                    color: AppColors.primaryContainer,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const Icon(Icons.check_circle, color: AppColors.primaryContainer, size: 20),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${addr.addressLine1}, ${addr.city}, ${addr.state} - ${addr.pincode}',
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Phone: ${addr.phoneNumber}',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.outline),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryContainer)),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddAddressModal,
        backgroundColor: AppColors.primaryContainer,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add New Address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
