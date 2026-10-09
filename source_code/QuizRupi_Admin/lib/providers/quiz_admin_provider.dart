import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/state_provider_compat.dart';
import '../data/models/admin_models.dart';
import 'admin_auth_provider.dart';

final quizCategoriesProvider = FutureProvider<List<QuizCategoryModel>>((ref) async {
  final service = ref.watch(adminServiceProvider);
  return await service.getCategories();
});

final questionCategoryFilterProvider = StateProvider<String>((ref) => 'All');
final questionSearchProvider = StateProvider<String>((ref) => '');

final questionsAdminListProvider = FutureProvider<List<QuestionModel>>((ref) async {
  final service = ref.watch(adminServiceProvider);
  final cat = ref.watch(questionCategoryFilterProvider);
  final search = ref.watch(questionSearchProvider);
  return await service.getQuestions(categoryId: cat, search: search);
});

final dailyChallengesAdminProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(adminServiceProvider);
  return await service.getDailyChallenges();
});
