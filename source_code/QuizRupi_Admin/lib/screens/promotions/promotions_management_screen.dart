import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/supabase_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../data/models/admin_models.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/promotions_admin_provider.dart';

class PromotionsManagementScreen extends ConsumerWidget {
  const PromotionsManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bannersAsync = ref.watch(bannersListProvider);
    final comboAsync = ref.watch(megaComboDealProvider);
    final vouchersAsync = ref.watch(vouchersListProvider);
    final announcementsAsync = ref.watch(announcementsListProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            const Text(
              'Promotions, Banners & Vouchers',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            Text(
              'Manage storefront banners, special combo packages, discount coupon codes, and announcements',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // ==================== SECTION 1: MEGA COMBO DEAL ====================
            comboAsync.when(
              loading: () => const SkeletonListLoader(count: 1),
              error: (err, _) => Text('Error: $err'),
              data: (combo) => _buildMegaComboCard(context, ref, combo, isDark),
            ),
            const SizedBox(height: 28),

            // ==================== SECTION 2: ANNOUNCEMENTS ====================
            _buildAnnouncementSection(context, ref, announcementsAsync, isDark),
            const SizedBox(height: 28),

            // ==================== SECTION 3: HOME BANNERS ====================
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                const Text('Home Storefront Banners', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => _openBannerUploader(context, ref),
                  icon: const Icon(Icons.add_photo_alternate, size: 18),
                  label: const Text('Add Banner'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            bannersAsync.when(
              loading: () => const SkeletonListLoader(count: 2),
              error: (err, _) => Text('Error: $err'),
              data: (banners) {
                if (banners.isEmpty) {
                  return EmptyState(
                    icon: Icons.view_carousel_outlined,
                    title: 'No Banners Configured',
                    message: 'Upload promotional banners to display on the Customer App home screen.',
                    actionLabel: 'Upload Banner',
                    onAction: () => _openBannerUploader(context, ref),
                  );
                }

                return Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(8),
                    itemCount: banners.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final b = banners[idx];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 65,
                            height: 40,
                            child: CachedNetworkImage(
                              imageUrl: b.imageUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                        title: Text(
                          b.title ?? 'Promotional Banner',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          b.actionUrl != null && b.actionUrl!.isNotEmpty ? 'Target: ${b.actionUrl}' : 'No action link',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch.adaptive(
                              value: b.isActive,
                              onChanged: (val) async {
                                await ref.read(adminServiceProvider).toggleBanner(b.id, val);
                                ref.invalidate(bannersListProvider);
                              },
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () async {
                                await ref.read(adminServiceProvider).deleteBanner(b.id);
                                ref.invalidate(bannersListProvider);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            // ==================== SECTION 4: VOUCHERS / COUPONS ====================
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                const Text('Discount Vouchers & Coupons', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => _openVoucherCreator(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create Voucher'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            vouchersAsync.when(
              loading: () => const SkeletonListLoader(count: 3),
              error: (err, _) => Text('Error: $err'),
              data: (vouchers) {
                if (vouchers.isEmpty) {
                  return EmptyState(
                    icon: Icons.confirmation_number_outlined,
                    title: 'No Vouchers Created',
                    message: 'Generate coupon codes (flat or percent discounts) for your customers.',
                    actionLabel: 'Create Voucher',
                    onAction: () => _openVoucherCreator(context, ref),
                  );
                }

                return Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(8),
                    itemCount: vouchers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final v = vouchers[idx];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                          child: const Icon(Icons.discount, color: AppColors.secondaryDark, size: 18),
                        ),
                        title: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              v.code,
                              style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                v.discountType == 'percent'
                                    ? '${v.discountValue.toInt()}% OFF'
                                    : '₹${v.discountValue.toInt()} FLAT OFF',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'Usage: ${v.usedCount} / ${v.usageLimit} redeemed',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch.adaptive(
                              value: v.isActive,
                              onChanged: (val) async {
                                await ref.read(adminServiceProvider).toggleVoucher(v.id, val);
                                ref.invalidate(vouchersListProvider);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () async {
                                await ref.read(adminServiceProvider).deleteVoucher(v.id);
                                ref.invalidate(vouchersListProvider);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMegaComboCard(BuildContext context, WidgetRef ref, PromotionModel combo, bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.secondary, width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department, color: AppColors.secondary, size: 24),
                    SizedBox(width: 8),
                    Text('Mega Combo Deal Offer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                Switch.adaptive(
                  value: combo.isActive,
                  activeColor: AppColors.secondary,
                  onChanged: (val) async {
                    await ref.read(adminServiceProvider).updatePromotion(
                          combo.copyWith(isActive: val),
                        );
                    ref.invalidate(megaComboDealProvider);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              combo.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              combo.description ?? 'Special discount deal displayed on user home screen',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  'Offer Price: ₹${combo.price?.toInt() ?? 1499}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Offer'),
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () => _editMegaCombo(context, ref, combo),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<AnnouncementModel>> announcementsAsync,
    bool isDark,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.campaign, color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text('Global In-App Announcement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _postNewAnnouncement(context, ref),
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Update Announcement'),
                  style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
            const SizedBox(height: 10),
            announcementsAsync.maybeWhen(
              data: (list) {
                if (list.isEmpty) return const Text('No announcement currently active.', style: TextStyle(color: Colors.grey));
                final first = list.first;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(first.message, style: const TextStyle(fontWeight: FontWeight.w600))),
                    ],
                  ),
                );
              },
              orElse: () => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  void _editMegaCombo(BuildContext context, WidgetRef ref, PromotionModel combo) {
    final titleCtrl = TextEditingController(text: combo.title);
    final descCtrl = TextEditingController(text: combo.description ?? '');
    final priceCtrl = TextEditingController(text: combo.price?.toInt().toString() ?? '1499');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Mega Combo Deal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 10),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 10),
            TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (₹)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(priceCtrl.text) ?? 1499;
              await ref.read(adminServiceProvider).updatePromotion(
                    combo.copyWith(
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      price: price,
                    ),
                  );
              ref.invalidate(megaComboDealProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _postNewAnnouncement(BuildContext context, WidgetRef ref) {
    final msgCtrl = TextEditingController();
    bool isActive = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('Post In-App Announcement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: msgCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Announcement Message',
                  hintText: 'e.g. Mega UPSC Mock Test tomorrow at 10 AM! Win free books.',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(value: isActive, onChanged: (v) => setDState(() => isActive = v ?? true)),
                  const Text('Active (Show immediately)'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (msgCtrl.text.trim().isEmpty) return;
                await ref.read(adminServiceProvider).saveAnnouncement(msgCtrl.text.trim(), isActive);
                ref.invalidate(announcementsListProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openBannerUploader(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result.isNotEmpty) {
      final file = result.first;
      final bytes = await file.readAsBytes();
      final titleCtrl = TextEditingController(text: 'Offer Banner');
      final actionUrlCtrl = TextEditingController();

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Save Home Banner'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Banner Title')),
              const SizedBox(height: 10),
              TextField(controller: actionUrlCtrl, decoration: const InputDecoration(labelText: 'Action / Redirect Link (Optional)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final url = await ref.read(adminServiceProvider).uploadImage(
                      bytes,
                      file.name,
                      SupabaseConstants.bucketBanners,
                    );
                await ref.read(adminServiceProvider).createBanner(BannerModel(
                      id: '',
                      title: titleCtrl.text.trim(),
                      imageUrl: url,
                      actionUrl: actionUrlCtrl.text.trim().isNotEmpty ? actionUrlCtrl.text.trim() : null,
                      isActive: true,
                      createdAt: DateTime.now(),
                    ));
                ref.invalidate(bannersListProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Upload & Publish'),
            ),
          ],
        ),
      );
    }
  }

  void _openVoucherCreator(BuildContext context, WidgetRef ref) {
    final codeCtrl = TextEditingController();
    final valueCtrl = TextEditingController(text: '100');
    final limitCtrl = TextEditingController(text: '100');
    String type = 'flat';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('Create Discount Voucher'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Coupon Code (e.g. RUPI100)'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Discount Type'),
                items: const [
                  DropdownMenuItem(value: 'flat', child: Text('Flat Rupees Off (₹)')),
                  DropdownMenuItem(value: 'percent', child: Text('Percentage Off (%)')),
                ],
                onChanged: (v) => setDState(() => type = v ?? 'flat'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: valueCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Discount Value (₹ or %)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: limitCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Usage Limit'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final code = codeCtrl.text.trim().toUpperCase();
                final val = double.tryParse(valueCtrl.text) ?? 100;
                final limit = int.tryParse(limitCtrl.text) ?? 100;
                if (code.isEmpty) return;

                await ref.read(adminServiceProvider).createVoucher(VoucherModel(
                      id: '',
                      code: code,
                      discountType: type,
                      discountValue: val,
                      usageLimit: limit,
                      isActive: true,
                    ));
                ref.invalidate(vouchersListProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

extension PromotionModelExtension on PromotionModel {
  PromotionModel copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    bool? isActive,
    String? bannerUrl,
    DateTime? updatedAt,
  }) {
    return PromotionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      isActive: isActive ?? this.isActive,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
