// Data models for QuizRupi Admin App

class AppSettingsModel {
  final int id;
  final bool showWebsite;
  final String? websiteUrl;
  final String? websiteTitle;
  final String upiId;
  final String payeeName;
  final bool isUpiEnabled;
  final String? merchantCode;
  final DateTime? updatedAt;
  final String? updatedBy;

  const AppSettingsModel({
    this.id = 1,
    this.showWebsite = false,
    this.websiteUrl,
    this.websiteTitle,
    this.upiId = 'quizrupi@upi',
    this.payeeName = 'QuizRupi Store',
    this.isUpiEnabled = true,
    this.merchantCode = '5499',
    this.updatedAt,
    this.updatedBy,
  });

  bool get isWebsiteModeValid {
    if (!showWebsite) return false;
    final url = websiteUrl?.trim() ?? '';
    if (url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      id: json['id'] as int? ?? 1,
      showWebsite: json['show_website'] as bool? ?? false,
      websiteUrl: json['website_url'] as String?,
      websiteTitle: json['website_title'] as String?,
      upiId: json['upi_id'] as String? ?? 'quizrupi@upi',
      payeeName: json['payee_name'] as String? ?? 'QuizRupi Store',
      isUpiEnabled: json['is_upi_enabled'] as bool? ?? true,
      merchantCode: json['merchant_code'] as String? ?? '5499',
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      updatedBy: json['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'show_website': showWebsite,
      'website_url': websiteUrl,
      'website_title': websiteTitle,
      'upi_id': upiId,
      'payee_name': payeeName,
      'is_upi_enabled': isUpiEnabled,
      'merchant_code': merchantCode,
      'updated_at': updatedAt?.toIso8601String(),
      'updated_by': updatedBy,
    };
  }

  AppSettingsModel copyWith({
    int? id,
    bool? showWebsite,
    String? websiteUrl,
    String? websiteTitle,
    String? upiId,
    String? payeeName,
    bool? isUpiEnabled,
    String? merchantCode,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return AppSettingsModel(
      id: id ?? this.id,
      showWebsite: showWebsite ?? this.showWebsite,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      websiteTitle: websiteTitle ?? this.websiteTitle,
      upiId: upiId ?? this.upiId,
      payeeName: payeeName ?? this.payeeName,
      isUpiEnabled: isUpiEnabled ?? this.isUpiEnabled,
      merchantCode: merchantCode ?? this.merchantCode,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

class PaymentSettingsModel {
  final int id;
  final String upiId;
  final String payeeName;
  final bool isUpiEnabled;
  final String? merchantCode;
  final String? qrCodeUrl;
  final DateTime? updatedAt;
  final String? updatedBy;

  const PaymentSettingsModel({
    this.id = 1,
    this.upiId = 'quizrupi@upi',
    this.payeeName = 'QuizRupi Store',
    this.isUpiEnabled = true,
    this.merchantCode = '5499',
    this.qrCodeUrl,
    this.updatedAt,
    this.updatedBy,
  });

  factory PaymentSettingsModel.fromJson(Map<String, dynamic> json) {
    return PaymentSettingsModel(
      id: json['id'] as int? ?? 1,
      upiId: json['upi_id'] as String? ?? 'quizrupi@upi',
      payeeName: json['payee_name'] as String? ?? 'QuizRupi Store',
      isUpiEnabled: json['is_upi_enabled'] as bool? ?? true,
      merchantCode: json['merchant_code'] as String? ?? '5499',
      qrCodeUrl: json['qr_code_url'] as String?,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      updatedBy: json['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'upi_id': upiId,
      'payee_name': payeeName,
      'is_upi_enabled': isUpiEnabled,
      'merchant_code': merchantCode,
      'qr_code_url': qrCodeUrl,
      'updated_at': updatedAt?.toIso8601String(),
      'updated_by': updatedBy,
    };
  }
}

class AppSettingsHistoryModel {
  final String id;
  final String? changedBy;
  final bool? oldShowWebsite;
  final bool? newShowWebsite;
  final String? oldWebsiteUrl;
  final String? newWebsiteUrl;
  final DateTime changedAt;

  const AppSettingsHistoryModel({
    required this.id,
    this.changedBy,
    this.oldShowWebsite,
    this.newShowWebsite,
    this.oldWebsiteUrl,
    this.newWebsiteUrl,
    required this.changedAt,
  });

  factory AppSettingsHistoryModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsHistoryModel(
      id: json['id'] as String,
      changedBy: json['changed_by'] as String?,
      oldShowWebsite: json['old_show_website'] as bool?,
      newShowWebsite: json['new_show_website'] as bool?,
      oldWebsiteUrl: json['old_website_url'] as String?,
      newWebsiteUrl: json['new_website_url'] as String?,
      changedAt: DateTime.tryParse(json['changed_at'].toString()) ?? DateTime.now(),
    );
  }
}

class AdminUserModel {
  final String userId;
  final String email;
  final String role;
  final DateTime createdAt;

  const AdminUserModel({
    required this.userId,
    required this.email,
    this.role = 'admin',
    required this.createdAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      userId: json['user_id'] as String? ?? json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'admin',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class BookModel {
  final String id;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final double price;
  final double mrp;
  final int discountPercent;
  final String? categoryId;
  final int mcqCount;
  final String editionInfo;
  final double ratingAvg;
  final int ratingCount;
  final String stockStatus;
  final bool isBestseller;
  final bool isNew;
  final String? tag;
  final bool isActive;
  final DateTime createdAt;
  final List<String> highlights;

  const BookModel({
    required this.id,
    required this.title,
    this.description,
    this.coverImageUrl,
    required this.price,
    required this.mrp,
    this.discountPercent = 0,
    this.categoryId,
    this.mcqCount = 1000,
    this.editionInfo = '2026 Edition',
    this.ratingAvg = 4.8,
    this.ratingCount = 120,
    this.stockStatus = 'In Stock',
    this.isBestseller = false,
    this.isNew = false,
    this.tag,
    this.isActive = true,
    required this.createdAt,
    this.highlights = const [],
  });

  factory BookModel.fromJson(Map<String, dynamic> json, {List<String>? highlights}) {
    return BookModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled Book',
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      mrp: (json['mrp'] as num?)?.toDouble() ?? 0.0,
      discountPercent: json['discount_percent'] as int? ?? 0,
      categoryId: json['category_id'] as String?,
      mcqCount: json['mcq_count'] as int? ?? 1000,
      editionInfo: json['edition_info'] as String? ?? '2026 Edition',
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 4.8,
      ratingCount: json['rating_count'] as int? ?? 120,
      stockStatus: json['stock_status'] as String? ?? 'In Stock',
      isBestseller: json['is_bestseller'] as bool? ?? false,
      isNew: json['is_new'] as bool? ?? false,
      tag: json['tag'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      highlights: highlights ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'cover_image_url': coverImageUrl,
      'price': price,
      'mrp': mrp,
      'discount_percent': discountPercent,
      'category_id': categoryId,
      'mcq_count': mcqCount,
      'edition_info': editionInfo,
      'rating_avg': ratingAvg,
      'rating_count': ratingCount,
      'stock_status': stockStatus,
      'is_bestseller': isBestseller,
      'is_new': isNew,
      'tag': tag,
      'is_active': isActive,
    };
  }

  BookModel copyWith({
    String? id,
    String? title,
    String? description,
    String? coverImageUrl,
    double? price,
    double? mrp,
    int? discountPercent,
    String? categoryId,
    int? mcqCount,
    String? editionInfo,
    double? ratingAvg,
    int? ratingCount,
    String? stockStatus,
    bool? isBestseller,
    bool? isNew,
    String? tag,
    bool? isActive,
    DateTime? createdAt,
    List<String>? highlights,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      price: price ?? this.price,
      mrp: mrp ?? this.mrp,
      discountPercent: discountPercent ?? this.discountPercent,
      categoryId: categoryId ?? this.categoryId,
      mcqCount: mcqCount ?? this.mcqCount,
      editionInfo: editionInfo ?? this.editionInfo,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      ratingCount: ratingCount ?? this.ratingCount,
      stockStatus: stockStatus ?? this.stockStatus,
      isBestseller: isBestseller ?? this.isBestseller,
      isNew: isNew ?? this.isNew,
      tag: tag ?? this.tag,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      highlights: highlights ?? this.highlights,
    );
  }
}

class OrderModel {
  final String id;
  final String userId;
  final String? customerName;
  final String? customerEmail;
  final String? deliveryAddress;
  final double subtotal;
  final double deliveryCharge;
  final double discountApplied;
  final int coinsRedeemed;
  final double totalAmount;
  final String paymentMethod;
  final String status;
  final String? trackingId;
  final DateTime? estimatedDeliveryDate;
  final DateTime createdAt;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id,
    required this.userId,
    this.customerName,
    this.customerEmail,
    this.deliveryAddress,
    required this.subtotal,
    this.deliveryCharge = 0.0,
    this.discountApplied = 0.0,
    this.coinsRedeemed = 0,
    required this.totalAmount,
    this.paymentMethod = 'UPI',
    this.status = 'Placed',
    this.trackingId,
    this.estimatedDeliveryDate,
    required this.createdAt,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json, {List<OrderItemModel>? items}) {
    return OrderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      customerName: json['profiles']?['full_name'] as String?,
      customerEmail: json['profiles']?['email'] as String?,
      deliveryAddress: json['delivery_address'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryCharge: (json['delivery_charge'] as num?)?.toDouble() ?? 0.0,
      discountApplied: (json['discount_applied'] as num?)?.toDouble() ?? 0.0,
      coinsRedeemed: json['coins_redeemed'] as int? ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'UPI',
      status: json['status'] as String? ?? 'Placed',
      trackingId: json['tracking_id'] as String?,
      estimatedDeliveryDate: json['estimated_delivery_date'] != null
          ? DateTime.tryParse(json['estimated_delivery_date'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      items: items ?? const [],
    );
  }
}

class OrderItemModel {
  final String id;
  final String orderId;
  final String bookId;
  final String? bookTitle;
  final String? bookCover;
  final int quantity;
  final double priceAtPurchase;

  const OrderItemModel({
    required this.id,
    required this.orderId,
    required this.bookId,
    this.bookTitle,
    this.bookCover,
    required this.quantity,
    required this.priceAtPurchase,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      bookId: json['book_id'] as String,
      bookTitle: json['books']?['title'] as String?,
      bookCover: json['books']?['cover_image_url'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      priceAtPurchase: (json['price_at_purchase'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class UserModel {
  final String id;
  final String? fullName;
  final String? email;
  final String? avatarUrl;
  final String? userCode;
  final int level;
  final int xp;
  final int coinsBalance;
  final int quizzesPlayed;
  final int correctAnswers;
  final int totalAnswers;
  final bool isBlocked;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    this.fullName,
    this.email,
    this.avatarUrl,
    this.userCode,
    this.level = 1,
    this.xp = 0,
    this.coinsBalance = 0,
    this.quizzesPlayed = 0,
    this.correctAnswers = 0,
    this.totalAnswers = 0,
    this.isBlocked = false,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      userCode: json['user_code'] as String?,
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
      coinsBalance: json['coins_balance'] as int? ?? 0,
      quizzesPlayed: json['quizzes_played'] as int? ?? 0,
      correctAnswers: json['correct_answers'] as int? ?? 0,
      totalAnswers: json['total_answers'] as int? ?? 0,
      isBlocked: json['is_blocked'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class QuizCategoryModel {
  final String id;
  final String name;
  final String? iconKey;
  final String? colorHex;
  final String difficulty;
  final int mcqCount;
  final bool isNew;
  final DateTime createdAt;

  const QuizCategoryModel({
    required this.id,
    required this.name,
    this.iconKey,
    this.colorHex,
    this.difficulty = 'Medium',
    this.mcqCount = 1000,
    this.isNew = false,
    required this.createdAt,
  });

  factory QuizCategoryModel.fromJson(Map<String, dynamic> json) {
    return QuizCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconKey: json['icon_key'] as String?,
      colorHex: json['color_hex'] as String?,
      difficulty: json['difficulty'] as String? ?? 'Medium',
      mcqCount: json['mcq_count'] as int? ?? 1000,
      isNew: json['is_new'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon_key': iconKey,
      'color_hex': colorHex,
      'difficulty': difficulty,
      'mcq_count': mcqCount,
      'is_new': isNew,
    };
  }
}

class QuestionModel {
  final String id;
  final String categoryId;
  final String? categoryName;
  final String questionText;
  final String? imageUrl;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption; // 'A', 'B', 'C', 'D'
  final String? explanationText;
  final String difficulty;
  final int timeLimitSeconds;
  final DateTime createdAt;

  const QuestionModel({
    required this.id,
    required this.categoryId,
    this.categoryName,
    required this.questionText,
    this.imageUrl,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOption,
    this.explanationText,
    this.difficulty = 'Medium',
    this.timeLimitSeconds = 15,
    required this.createdAt,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      categoryName: json['quiz_categories']?['name'] as String?,
      questionText: json['question_text'] as String,
      imageUrl: json['image_url'] as String?,
      optionA: json['option_a'] as String,
      optionB: json['option_b'] as String,
      optionC: json['option_c'] as String,
      optionD: json['option_d'] as String,
      correctOption: (json['correct_option'] as String?)?.toUpperCase() ?? 'A',
      explanationText: json['explanation_text'] as String?,
      difficulty: json['difficulty'] as String? ?? 'Medium',
      timeLimitSeconds: json['time_limit_seconds'] as int? ?? 15,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'question_text': questionText,
      'image_url': imageUrl,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
      'correct_option': correctOption.toUpperCase(),
      'explanation_text': explanationText,
      'difficulty': difficulty,
      'time_limit_seconds': timeLimitSeconds,
    };
  }
}

class BannerModel {
  final String id;
  final String? title;
  final String imageUrl;
  final String? actionUrl;
  final bool isActive;
  final int displayOrder;
  final DateTime createdAt;

  const BannerModel({
    required this.id,
    this.title,
    required this.imageUrl,
    this.actionUrl,
    this.isActive = true,
    this.displayOrder = 0,
    required this.createdAt,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as String,
      title: json['title'] as String?,
      imageUrl: json['image_url'] as String,
      actionUrl: json['action_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: json['display_order'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'image_url': imageUrl,
      'action_url': actionUrl,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }
}

class AnnouncementModel {
  final String id;
  final String message;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AnnouncementModel({
    required this.id,
    required this.message,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as String,
      message: json['message'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class PromotionModel {
  final String id;
  final String title;
  final String? description;
  final double? price;
  final bool isActive;
  final String? bannerUrl;
  final DateTime updatedAt;

  const PromotionModel({
    required this.id,
    required this.title,
    this.description,
    this.price,
    this.isActive = false,
    this.bannerUrl,
    required this.updatedAt,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      isActive: json['is_active'] as bool? ?? false,
      bannerUrl: json['banner_url'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class VoucherModel {
  final String id;
  final String code;
  final String discountType; // 'flat' or 'percent'
  final double discountValue;
  final int usageLimit;
  final int usedCount;
  final bool isActive;
  final DateTime? expiresAt;

  const VoucherModel({
    required this.id,
    required this.code,
    this.discountType = 'flat',
    required this.discountValue,
    this.usageLimit = 100,
    this.usedCount = 0,
    this.isActive = true,
    this.expiresAt,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      id: json['id'] as String,
      code: json['code'] as String,
      discountType: json['discount_type'] as String? ?? 'flat',
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0.0,
      usageLimit: json['usage_limit'] as int? ?? 100,
      usedCount: json['used_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code.toUpperCase(),
      'discount_type': discountType,
      'discount_value': discountValue,
      'usage_limit': usageLimit,
      'used_count': usedCount,
      'is_active': isActive,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }
}

class DashboardStatsModel {
  final int totalUsers;
  final int activeToday;
  final int quizzesPlayedToday;
  final int totalOrders;
  final int ordersPending;
  final double revenueToday;
  final double revenueThisMonth;
  final int coinsGivenToday;
  final bool isWebsiteMode;
  final String? websiteUrl;

  const DashboardStatsModel({
    this.totalUsers = 0,
    this.activeToday = 0,
    this.quizzesPlayedToday = 0,
    this.totalOrders = 0,
    this.ordersPending = 0,
    this.revenueToday = 0.0,
    this.revenueThisMonth = 0.0,
    this.coinsGivenToday = 0,
    this.isWebsiteMode = false,
    this.websiteUrl,
  });
}
