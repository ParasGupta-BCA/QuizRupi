import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/admin_models.dart';
import 'admin_auth_provider.dart';

final bannersListProvider = FutureProvider<List<BannerModel>>((ref) async {
  final service = ref.watch(adminServiceProvider);
  return await service.getBanners();
});

final megaComboDealProvider = FutureProvider<PromotionModel>((ref) async {
  final service = ref.watch(adminServiceProvider);
  return await service.getPromotion('mega_combo_deal');
});

final announcementsListProvider = FutureProvider<List<AnnouncementModel>>((ref) async {
  final service = ref.watch(adminServiceProvider);
  return await service.getAnnouncements();
});

final vouchersListProvider = FutureProvider<List<VoucherModel>>((ref) async {
  final service = ref.watch(adminServiceProvider);
  return await service.getVouchers();
});

final adminUsersListProvider = FutureProvider<List<AdminUserModel>>((ref) async {
  final service = ref.watch(adminServiceProvider);
  return await service.getAdminUsers();
});
