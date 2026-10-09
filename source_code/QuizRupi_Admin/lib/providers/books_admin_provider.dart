import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/state_provider_compat.dart';
import '../data/models/admin_models.dart';
import 'admin_auth_provider.dart';

final bookSearchProvider = StateProvider<String>((ref) => '');
final bookCategoryFilterProvider = StateProvider<String?>((ref) => null);

final booksAdminListProvider = FutureProvider<List<BookModel>>((ref) async {
  final service = ref.watch(adminServiceProvider);
  final search = ref.watch(bookSearchProvider);
  final cat = ref.watch(bookCategoryFilterProvider);
  return await service.getBooks(search: search, categoryId: cat);
});
