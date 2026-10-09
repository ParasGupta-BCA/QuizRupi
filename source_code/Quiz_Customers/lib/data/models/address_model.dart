class AddressModel {
  final String id;
  final String userId;
  final String label; // Home, Work, Other
  final String fullAddress;
  final String pincode;
  final String city;
  final String state;
  final String phone;
  final bool isDefault;
  final String? recipientName;

  AddressModel({
    this.id = '',
    required this.userId,
    this.label = 'Home',
    String? fullAddress,
    String? addressLine1,
    required this.pincode,
    required this.city,
    required this.state,
    String? phone,
    String? phoneNumber,
    String? fullName,
    this.isDefault = false,
    String? recipientName,
  })  : fullAddress = fullAddress ?? addressLine1 ?? '',
        phone = phone ?? phoneNumber ?? '',
        recipientName = recipientName ?? fullName;

  String get fullName => recipientName ?? (label.isNotEmpty ? label : 'Customer');
  String get phoneNumber => phone;
  String get addressLine1 => fullAddress;

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      label: json['label'] as String? ?? 'Home',
      fullAddress: json['full_address'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
      recipientName: json['label'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'user_id': userId,
      'label': fullName,
      'full_address': fullAddress,
      'pincode': pincode,
      'city': city,
      'state': state,
      'phone': phone,
      'is_default': isDefault,
    };
    if (id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }
}
