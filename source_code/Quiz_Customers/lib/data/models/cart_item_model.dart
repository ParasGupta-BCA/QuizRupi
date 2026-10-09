import 'book_model.dart';

class CartItemModel {
  final String id;
  final String userId;
  final String bookId;
  final int quantity;
  final BookModel? book;

  CartItemModel({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.quantity,
    this.book,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    BookModel? b;
    if (json['books'] != null && json['books'] is Map<String, dynamic>) {
      b = BookModel.fromJson(json['books'] as Map<String, dynamic>);
    }
    return CartItemModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bookId: json['book_id'] as String,
      quantity: json['quantity'] as int? ?? 1,
      book: b,
    );
  }
}
