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
