import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/supabase_constants.dart';
import '../models/admin_models.dart';

class AdminSupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  SupabaseClient get client => _client;
  User? get currentUser => _client.auth.currentUser;
  String? get currentUserId => _client.auth.currentUser?.id;

  // ==================== AUTH ====================

  Future<AuthResponse> signInWithPassword(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    // Verify admin privileges immediately
    final isAdmin = await checkIsAdmin();
    if (!isAdmin) {
      await _client.auth.signOut();
      throw Exception('Access denied: Your account does not have administrator privileges.');
    }

    return response;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<bool> checkIsAdmin() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      final res = await _client.rpc('is_admin');
      if (res is bool) return res;
    } catch (_) {}

    try {
      final res = await _client
          .from(SupabaseConstants.tableAdminUsers)
          .select('user_id')
          .eq('user_id', user.id)
          .maybeSingle();
      return res != null;
    } catch (e) {
      debugPrint('Admin check error: $e');
      return false;
    }
  }

  Future<void> changePassword(String newPassword) async {
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // ==================== APP CONTROL ====================

  Future<AppSettingsModel> getAppSettings() async {
    final data = await _client
        .from(SupabaseConstants.tableAppSettings)
        .select()
        .eq('id', 1)
        .maybeSingle();

    if (data == null) return const AppSettingsModel();
    return AppSettingsModel.fromJson(data);
  }

  Stream<AppSettingsModel> streamAppSettings() {
    return _client
        .from(SupabaseConstants.tableAppSettings)
        .stream(primaryKey: ['id'])
        .eq('id', 1)
        .map((list) => list.isNotEmpty
            ? AppSettingsModel.fromJson(list.first)
            : const AppSettingsModel());
  }

  Future<void> updateAppSettings({
    required bool showWebsite,
    String? websiteUrl,
    String? websiteTitle,
  }) async {
    final user = _client.auth.currentUser;
    final now = DateTime.now().toIso8601String();

    final payload = {
      'show_website': showWebsite,
      'website_url': websiteUrl?.trim(),
      'website_title': websiteTitle?.trim(),
      'updated_at': now,
      'updated_by': user?.id,
    };

    try {
      final res = await _client
          .from(SupabaseConstants.tableAppSettings)
          .update(payload)
          .eq('id', 1)
          .select();

      if ((res as List).isEmpty) {
        await _client.from(SupabaseConstants.tableAppSettings).upsert({
          'id': 1,
          ...payload,
        });
      }
    } catch (_) {
      // Direct upsert attempt
      await _client.from(SupabaseConstants.tableAppSettings).upsert({
        'id': 1,
        ...payload,
      });
    }
  }

  Future<void> updatePaymentSettings({
    required String upiId,
    required String payeeName,
    required bool isUpiEnabled,
    String? merchantCode,
  }) async {
    final user = _client.auth.currentUser;
    final now = DateTime.now().toIso8601String();

    final payload = {
      'upi_id': upiId.trim(),
      'payee_name': payeeName.trim(),
      'is_upi_enabled': isUpiEnabled,
      'merchant_code': merchantCode?.trim() ?? '5499',
      'updated_at': now,
      'updated_by': user?.id,
    };

    try {
      await _client
          .from('payment_settings')
          .update(payload)
          .eq('id', 1);
    } catch (e) {
      debugPrint('Error updating payment_settings: $e');
    }

    try {
      await _client
          .from(SupabaseConstants.tableAppSettings)
          .update({
            'upi_id': upiId.trim(),
            'payee_name': payeeName.trim(),
            'is_upi_enabled': isUpiEnabled,
            'updated_at': now,
            'updated_by': user?.id,
          })
          .eq('id', 1);
    } catch (e) {
      debugPrint('Error updating app_settings with upi info: $e');
    }
  }

  Future<List<AppSettingsHistoryModel>> getAppSettingsHistory() async {
    final data = await _client
        .from(SupabaseConstants.tableAppSettingsHistory)
        .select()
        .order('changed_at', ascending: false)
        .limit(20);

    return (data as List)
        .map((item) => AppSettingsHistoryModel.fromJson(item))
        .toList();
  }

  // ==================== DASHBOARD ====================

  Future<DashboardStatsModel> getDashboardStats() async {
    try {
      // 1. Total users
      final usersRes = await _client.from(SupabaseConstants.tableProfiles).select('id');
      final totalUsers = (usersRes as List).length;

      // 2. Orders
      final ordersRes = await _client.from(SupabaseConstants.tableOrders).select('id, status, total_amount, created_at');
      final ordersList = ordersRes as List;
      final totalOrders = ordersList.length;
      final pendingOrders = ordersList.where((o) => o['status'] == 'Placed' || o['status'] == 'Shipped').length;

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final monthStart = DateTime(now.year, now.month, 1);

      double revToday = 0;
      double revMonth = 0;
      for (final o in ordersList) {
        final amount = (o['total_amount'] as num?)?.toDouble() ?? 0.0;
        final createdAt = DateTime.tryParse(o['created_at'].toString()) ?? now;
        if (createdAt.isAfter(todayStart)) revToday += amount;
        if (createdAt.isAfter(monthStart)) revMonth += amount;
      }

      // 3. Quizzes played today
      final quizzesRes = await _client
          .from(SupabaseConstants.tableQuizAttempts)
          .select('id, started_at')
          .gte('started_at', todayStart.toIso8601String());
      final quizzesToday = (quizzesRes as List).length;

      // 4. Coins given today
      final coinsRes = await _client
          .from(SupabaseConstants.tableCoinTransactions)
          .select('amount, type')
          .eq('type', 'credit')
          .gte('created_at', todayStart.toIso8601String());
      int coinsToday = 0;
      for (final c in (coinsRes as List)) {
        coinsToday += (c['amount'] as int? ?? 0);
      }

      // 5. Remote app settings
      final appSettings = await getAppSettings();

      return DashboardStatsModel(
        totalUsers: totalUsers,
        activeToday: (totalUsers * 0.4).ceil(), // Active estimate based on userbase
        quizzesPlayedToday: quizzesToday,
        totalOrders: totalOrders,
        ordersPending: pendingOrders,
        revenueToday: revToday,
        revenueThisMonth: revMonth,
        coinsGivenToday: coinsToday,
        isWebsiteMode: appSettings.showWebsite,
        websiteUrl: appSettings.websiteUrl,
      );
    } catch (e) {
      debugPrint('Error loading dashboard stats: $e');
      return const DashboardStatsModel();
    }
  }

  // ==================== BOOKS ====================

  Future<List<BookModel>> getBooks({String? search, String? categoryId}) async {
    var query = _client.from(SupabaseConstants.tableBooks).select('*, book_highlights(highlight_text)');

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.eq('category_id', categoryId);
    }

    final data = await query.order('created_at', ascending: false);

    var list = (data as List).map((item) {
      final highlightsList = (item['book_highlights'] as List?)
              ?.map((h) => h['highlight_text'] as String)
              .toList() ??
          <String>[];
      return BookModel.fromJson(item, highlights: highlightsList);
    }).toList();

    if (search != null && search.trim().isNotEmpty) {
      final s = search.toLowerCase().trim();
      list = list.where((b) => b.title.toLowerCase().contains(s)).toList();
    }

    return list;
  }

  Future<void> createBook(BookModel book, List<String> highlights) async {
    final bookData = book.toJson();
    final res = await _client.from(SupabaseConstants.tableBooks).insert(bookData).select().single();
    final newId = res['id'] as String;

    if (highlights.isNotEmpty) {
      final hList = highlights
          .where((h) => h.trim().isNotEmpty)
          .map((h) => {'book_id': newId, 'highlight_text': h.trim()})
          .toList();
      if (hList.isNotEmpty) {
        await _client.from(SupabaseConstants.tableBookHighlights).insert(hList);
      }
    }
  }

  Future<void> updateBook(BookModel book, List<String> highlights) async {
    await _client.from(SupabaseConstants.tableBooks).update(book.toJson()).eq('id', book.id);

    // Replace highlights
    await _client.from(SupabaseConstants.tableBookHighlights).delete().eq('book_id', book.id);
    if (highlights.isNotEmpty) {
      final hList = highlights
          .where((h) => h.trim().isNotEmpty)
          .map((h) => {'book_id': book.id, 'highlight_text': h.trim()})
          .toList();
      if (hList.isNotEmpty) {
        await _client.from(SupabaseConstants.tableBookHighlights).insert(hList);
      }
    }
  }

  Future<void> deleteBook(String bookId) async {
    await _client.from(SupabaseConstants.tableBookHighlights).delete().eq('book_id', bookId);
    await _client.from(SupabaseConstants.tableBooks).delete().eq('id', bookId);
  }

  Future<void> toggleBookActive(String bookId, bool isActive) async {
    await _client.from(SupabaseConstants.tableBooks).update({'is_active': isActive}).eq('id', bookId);
  }

  // ==================== ORDERS ====================

  Future<List<OrderModel>> getOrders({String? status, String? search}) async {
    var query = _client.from(SupabaseConstants.tableOrders).select('''
      *,
      profiles(full_name, email),
      order_items(id, order_id, book_id, quantity, price_at_purchase, books(title, cover_image_url))
    ''');

    if (status != null && status != 'All' && status.isNotEmpty) {
      query = query.eq('status', status);
    }

    final data = await query.order('created_at', ascending: false);

    var list = (data as List).map((item) {
      final itemsRaw = item['order_items'] as List?;
      final items = itemsRaw != null
          ? itemsRaw.map((oi) => OrderItemModel.fromJson(oi)).toList()
          : <OrderItemModel>[];
      return OrderModel.fromJson(item, items: items);
    }).toList();

    if (search != null && search.trim().isNotEmpty) {
      final s = search.toLowerCase().trim();
      list = list.where((o) =>
          o.id.toLowerCase().contains(s) ||
          (o.customerName?.toLowerCase().contains(s) ?? false) ||
          (o.customerEmail?.toLowerCase().contains(s) ?? false)).toList();
    }

    return list;
  }

  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    String? trackingId,
    DateTime? estimatedDeliveryDate,
  }) async {
    final Map<String, dynamic> updateData = {'status': status};
    if (trackingId != null) updateData['tracking_id'] = trackingId.trim();
    if (estimatedDeliveryDate != null) {
      updateData['estimated_delivery_date'] = estimatedDeliveryDate.toIso8601String();
    }
    await _client.from(SupabaseConstants.tableOrders).update(updateData).eq('id', orderId);
  }

  // ==================== USERS ====================

  Future<List<UserModel>> getUsers({String? search}) async {
    final data = await _client.from(SupabaseConstants.tableProfiles).select().order('created_at', ascending: false);
    var list = (data as List).map((item) => UserModel.fromJson(item)).toList();

    if (search != null && search.trim().isNotEmpty) {
      final s = search.toLowerCase().trim();
      list = list.where((u) =>
          (u.fullName?.toLowerCase().contains(s) ?? false) ||
          (u.email?.toLowerCase().contains(s) ?? false) ||
          (u.userCode?.toLowerCase().contains(s) ?? false)).toList();
    }

    return list;
  }

  Future<void> toggleUserBlock(String userId, bool isBlocked) async {
    await _client.from(SupabaseConstants.tableProfiles).update({'is_blocked': isBlocked}).eq('id', userId);
  }

  Future<void> adjustCoins(String userId, int amount, String type, String description) async {
    // 1. Insert coin transaction
    await _client.from(SupabaseConstants.tableCoinTransactions).insert({
      'user_id': userId,
      'amount': amount,
      'type': type, // 'credit' or 'debit'
      'source': 'Admin Adjustment',
      'description': description,
    });

    // 2. Update user profile balance
    final profile = await _client.from(SupabaseConstants.tableProfiles).select('coins_balance').eq('id', userId).single();
    final currentBal = profile['coins_balance'] as int? ?? 0;
    final newBal = type == 'credit' ? currentBal + amount : (currentBal - amount).clamp(0, 9999999);

    await _client.from(SupabaseConstants.tableProfiles).update({'coins_balance': newBal}).eq('id', userId);
  }

  Future<List<Map<String, dynamic>>> getUserCoinHistory(String userId) async {
    final data = await _client
        .from(SupabaseConstants.tableCoinTransactions)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(20);
    return List<Map<String, dynamic>>.from(data);
  }

  // ==================== QUIZ CONTENT ====================

  Future<List<QuizCategoryModel>> getCategories() async {
    final data = await _client.from(SupabaseConstants.tableQuizCategories).select().order('name');
    return (data as List).map((item) => QuizCategoryModel.fromJson(item)).toList();
  }

  Future<void> createCategory(QuizCategoryModel category) async {
    await _client.from(SupabaseConstants.tableQuizCategories).insert(category.toJson());
  }

  Future<void> updateCategory(QuizCategoryModel category) async {
    await _client.from(SupabaseConstants.tableQuizCategories).update(category.toJson()).eq('id', category.id);
  }

  Future<void> deleteCategory(String categoryId) async {
    await _client.from(SupabaseConstants.tableQuestions).delete().eq('category_id', categoryId);
    await _client.from(SupabaseConstants.tableQuizCategories).delete().eq('id', categoryId);
  }

  Future<List<QuestionModel>> getQuestions({String? categoryId, String? search}) async {
    var query = _client.from(SupabaseConstants.tableQuestions).select('*, quiz_categories(name)');

    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'All') {
      query = query.eq('category_id', categoryId);
    }

    final data = await query.order('created_at', ascending: false).limit(200);

    var list = (data as List).map((item) => QuestionModel.fromJson(item)).toList();

    if (search != null && search.trim().isNotEmpty) {
      final s = search.toLowerCase().trim();
      list = list.where((q) => q.questionText.toLowerCase().contains(s)).toList();
    }

    return list;
  }

  Future<void> createQuestion(QuestionModel question) async {
    await _client.from(SupabaseConstants.tableQuestions).insert(question.toJson());
  }

  Future<void> updateQuestion(QuestionModel question) async {
    await _client.from(SupabaseConstants.tableQuestions).update(question.toJson()).eq('id', question.id);
  }

  Future<void> deleteQuestion(String questionId) async {
    await _client.from(SupabaseConstants.tableQuestions).delete().eq('id', questionId);
  }

  Future<int> bulkImportQuestions(List<QuestionModel> questions) async {
    if (questions.isEmpty) return 0;
    final data = questions.map((q) => q.toJson()).toList();
    await _client.from(SupabaseConstants.tableQuestions).insert(data);
    return questions.length;
  }

  Future<List<Map<String, dynamic>>> getDailyChallenges() async {
    final data = await _client
        .from(SupabaseConstants.tableDailyChallenges)
        .select('*, quiz_categories(name)')
        .order('date', ascending: false)
        .limit(30);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> setDailyChallenge(DateTime date, String categoryId, int bonusCoins, int totalQuestions) async {
    final dateStr = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    await _client.from(SupabaseConstants.tableDailyChallenges).upsert({
      'date': dateStr,
      'category_id': categoryId,
      'bonus_coins': bonusCoins,
      'total_questions': totalQuestions,
    }, onConflict: 'date');
  }

  // ==================== PROMOTIONS & BANNERS ====================

  Future<List<BannerModel>> getBanners() async {
    final data = await _client.from(SupabaseConstants.tableBanners).select().order('display_order');
    return (data as List).map((item) => BannerModel.fromJson(item)).toList();
  }

  Future<void> createBanner(BannerModel banner) async {
    await _client.from(SupabaseConstants.tableBanners).insert(banner.toJson());
  }

  Future<void> toggleBanner(String bannerId, bool isActive) async {
    await _client.from(SupabaseConstants.tableBanners).update({'is_active': isActive}).eq('id', bannerId);
  }

  Future<void> deleteBanner(String bannerId) async {
    await _client.from(SupabaseConstants.tableBanners).delete().eq('id', bannerId);
  }

  Future<PromotionModel> getPromotion(String id) async {
    final data = await _client.from(SupabaseConstants.tablePromotions).select().eq('id', id).maybeSingle();
    if (data == null) {
      return PromotionModel(
        id: id,
        title: 'Mega Combo Deal',
        isActive: false,
        updatedAt: DateTime.now(),
      );
    }
    return PromotionModel.fromJson(data);
  }

  Future<void> updatePromotion(PromotionModel promo) async {
    await _client.from(SupabaseConstants.tablePromotions).upsert({
      'id': promo.id,
      'title': promo.title,
      'description': promo.description,
      'price': promo.price,
      'is_active': promo.isActive,
      'banner_url': promo.bannerUrl,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<AnnouncementModel>> getAnnouncements() async {
    final data = await _client.from(SupabaseConstants.tableAnnouncements).select().order('created_at', ascending: false);
    return (data as List).map((item) => AnnouncementModel.fromJson(item)).toList();
  }

  Future<void> saveAnnouncement(String message, bool isActive) async {
    await _client.from(SupabaseConstants.tableAnnouncements).insert({
      'message': message.trim(),
      'is_active': isActive,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<VoucherModel>> getVouchers() async {
    final data = await _client.from(SupabaseConstants.tableVouchers).select().order('created_at', ascending: false);
    return (data as List).map((item) => VoucherModel.fromJson(item)).toList();
  }

  Future<void> createVoucher(VoucherModel voucher) async {
    await _client.from(SupabaseConstants.tableVouchers).insert(voucher.toJson());
  }

  Future<void> toggleVoucher(String voucherId, bool isActive) async {
    await _client.from(SupabaseConstants.tableVouchers).update({'is_active': isActive}).eq('id', voucherId);
  }

  Future<void> deleteVoucher(String voucherId) async {
    await _client.from(SupabaseConstants.tableVouchers).delete().eq('id', voucherId);
  }

  // ==================== STORAGE ====================

  Future<String> uploadImage(Uint8List bytes, String fileName, String bucket) async {
    final path = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage.from(bucket).uploadBinary(path, bytes);
    final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
    return publicUrl;
  }

  // ==================== ADMINS MANAGEMENT ====================

  Future<List<AdminUserModel>> getAdminUsers() async {
    try {
      final res = await _client.rpc('get_admin_users');
      return (res as List).map((item) => AdminUserModel.fromJson(item)).toList();
    } catch (_) {
      final data = await _client.from(SupabaseConstants.tableAdminUsers).select();
      return (data as List).map((item) => AdminUserModel.fromJson(item)).toList();
    }
  }

  Future<Map<String, dynamic>> addAdminByEmail(String email) async {
    final res = await _client.rpc('add_admin_by_email', params: {'email_input': email.trim()});
    return Map<String, dynamic>.from(res as Map);
  }

  Future<void> removeAdmin(String userId) async {
    await _client.from(SupabaseConstants.tableAdminUsers).delete().eq('user_id', userId);
  }
}
