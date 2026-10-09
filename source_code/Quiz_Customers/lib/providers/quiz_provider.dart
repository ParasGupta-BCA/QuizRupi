import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/state_provider_compat.dart';
import '../data/models/quiz_category_model.dart';
import '../data/models/question_model.dart';
import '../data/models/daily_challenge_model.dart';
import '../data/models/leaderboard_entry_model.dart';
import '../data/models/badge_model.dart';
import 'auth_provider.dart';

final quizCategoriesProvider = FutureProvider<List<QuizCategoryModel>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  return await service.getCategories();
});

final selectedCategoryFilterProvider = StateProvider<String?>((ref) => null);

final todayChallengeProvider = FutureProvider<DailyChallengeModel?>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  return await service.getTodayChallenge();
});

final dailyChallengeProgressProvider =
    FutureProvider<DailyChallengeProgressModel?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final challenge = await ref.watch(todayChallengeProvider.future);
  if (userId == null || challenge == null) return null;
  final service = ref.watch(supabaseServiceProvider);
  return await service.getDailyChallengeProgress(userId, challenge.id);
});

final todayChampionsProvider = FutureProvider<List<LeaderboardEntryModel>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  return await service.getTodayChampions();
});

final userBadgesProvider = FutureProvider<List<BadgeModel>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  final service = ref.watch(supabaseServiceProvider);
  return await service.getBadgesWithUserStatus(userId);
});

final questionsFamilyProvider =
    FutureProvider.family<List<QuestionModel>, ({String categoryId, int limit})>(
        (ref, arg) async {
  final service = ref.watch(supabaseServiceProvider);
  return await service.getQuestionsForCategory(arg.categoryId, limit: arg.limit);
});
