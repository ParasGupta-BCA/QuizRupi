import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/state_provider_compat.dart';
import '../data/models/book_model.dart';
import 'auth_provider.dart';

final shopCategoryFilterProvider = StateProvider<String?>((ref) => null);
final shopSearchQueryProvider = StateProvider<String>((ref) => '');

final booksProvider = FutureProvider<List<BookModel>>((ref) async {
  final categoryId = ref.watch(shopCategoryFilterProvider);
  final search = ref.watch(shopSearchQueryProvider);
  final service = ref.watch(supabaseServiceProvider);
  return await service.getBooks(categoryId: categoryId, search: search);
});

final bookDetailProvider =
    FutureProvider.family<BookModel?, String>((ref, bookId) async {
  final service = ref.watch(supabaseServiceProvider);
  return await service.getBookById(bookId);
});
