import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/state_provider_compat.dart';
import '../data/models/coin_transaction_model.dart';
import '../data/models/quiz_attempt_model.dart';
import 'auth_provider.dart';

final walletFilterProvider = StateProvider<String>((ref) => 'all'); // all, earned, redeemed

final coinTransactionsProvider =
    FutureProvider<List<CoinTransactionModel>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  final service = ref.watch(supabaseServiceProvider);
  final all = await service.getCoinTransactions(userId);
  final filter = ref.watch(walletFilterProvider);

  if (filter == 'earned') {
    return all.where((t) => t.isEarned).toList();
  } else if (filter == 'redeemed') {
    return all.where((t) => !t.isEarned).toList();
  }
  return all;
});

final userQuizHistoryProvider =
    FutureProvider<List<QuizAttemptModel>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  final service = ref.watch(supabaseServiceProvider);
  return await service.getUserQuizHistory(userId);
});
