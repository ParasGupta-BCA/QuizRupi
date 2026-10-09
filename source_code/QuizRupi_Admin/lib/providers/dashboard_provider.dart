import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/admin_models.dart';
import 'admin_auth_provider.dart';

final dashboardStatsProvider = FutureProvider<DashboardStatsModel>((ref) async {
  final service = ref.watch(adminServiceProvider);
  return await service.getDashboardStats();
});
