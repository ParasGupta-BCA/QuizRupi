class CoinTransactionModel {
  final String id;
  final String userId;
  final String type; // 'earned', 'redeemed'
  final int amount;
  final String source; // 'quiz', 'daily_challenge', 'referral', 'order_redeem', 'signup_bonus'
  final String? description;
  final DateTime createdAt;

  CoinTransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.source,
    this.description,
    required this.createdAt,
  });

  bool get isEarned => type.toLowerCase() == 'earned';

  factory CoinTransactionModel.fromJson(Map<String, dynamic> json) {
    return CoinTransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String? ?? 'earned',
      amount: json['amount'] as int? ?? 0,
      source: json['source'] as String? ?? 'quiz',
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
