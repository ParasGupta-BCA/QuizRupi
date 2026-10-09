import 'book_model.dart';

class OrderItemModel {
  final String id;
  final String orderId;
  final String bookId;
  final int quantity;
  final double priceAtPurchase;
  final BookModel? book;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.bookId,
    required this.quantity,
    required this.priceAtPurchase,
    this.book,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    BookModel? b;
    if (json['books'] != null && json['books'] is Map<String, dynamic>) {
      b = BookModel.fromJson(json['books'] as Map<String, dynamic>);
    }
    return OrderItemModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      bookId: json['book_id'] as String,
      quantity: json['quantity'] as int? ?? 1,
      priceAtPurchase: (json['price_at_purchase'] as num?)?.toDouble() ?? 0.0,
      book: b,
    );
  }
}

class OrderModel {
  final String id;
  final String userId;
  final String? addressId;
  final String? deliveryAddress;
  final double subtotal;
  final double deliveryCharge;
  final double discountApplied;
  final int coinsRedeemed;
  final double totalAmount;
  final String paymentMethod;
  final String status; // Placed, Shipped, Out for Delivery, Delivered
  final String trackingId;
  final DateTime? estimatedDeliveryDate;
  final DateTime createdAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.userId,
    this.addressId,
    this.deliveryAddress,
    required this.subtotal,
    this.deliveryCharge = 0.0,
    this.discountApplied = 0.0,
    this.coinsRedeemed = 0,
    required this.totalAmount,
    this.paymentMethod = 'UPI',
    this.status = 'Placed',
    required this.trackingId,
    this.estimatedDeliveryDate,
    required this.createdAt,
    this.items = const [],
  });

  int get statusStep {
    switch (status.toLowerCase()) {
      case 'placed':
        return 0;
      case 'shipped':
        return 1;
      case 'out for delivery':
        return 2;
      case 'delivered':
        return 3;
      default:
        return 0;
    }
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    List<OrderItemModel> orderItems = [];
    if (json['order_items'] != null && json['order_items'] is List) {
      orderItems = (json['order_items'] as List)
          .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return OrderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      addressId: json['address_id'] as String?,
      deliveryAddress: json['delivery_address'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryCharge: (json['delivery_charge'] as num?)?.toDouble() ?? 0.0,
      discountApplied: (json['discount_applied'] as num?)?.toDouble() ?? 0.0,
      coinsRedeemed: json['coins_redeemed'] as int? ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'UPI',
      status: json['status'] as String? ?? 'Placed',
      trackingId: json['tracking_id'] as String? ?? 'EK-000000IN',
      estimatedDeliveryDate: json['estimated_delivery_date'] != null
          ? DateTime.parse(json['estimated_delivery_date'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      items: orderItems,
    );
  }
}
