import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/supabase_constants.dart';
import '../models/profile_model.dart';
import '../models/quiz_category_model.dart';
import '../models/question_model.dart';
import '../models/quiz_attempt_model.dart';
import '../models/daily_challenge_model.dart';
import '../models/live_battle_model.dart';
import '../models/leaderboard_entry_model.dart';
import '../models/badge_model.dart';
import '../models/book_model.dart';
import '../models/address_model.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../models/coin_transaction_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  SupabaseClient get client => _client;

  User? get currentUser => _client.auth.currentUser;
  String? get currentUserId => _client.auth.currentUser?.id;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String fullName,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
      },
    );


    if (response.user != null) {
      final userId = response.user!.id;
      // Allow trigger to fire, or ensure profile row exists
      try {
        final profileRes = await _client
            .from(SupabaseConstants.tableProfiles)
            .select()
            .eq('id', userId)
            .maybeSingle();

        if (profileRes == null) {
          // Manual fallback if trigger was delayed
          final username =
              '${fullName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}_${DateTime.now().millisecondsSinceEpoch % 1000}';
          final userCode = 'QZ-${DateTime.now().millisecondsSinceEpoch % 90000 + 10000}';
          final newRefCode = 'QR${userId.substring(0, 6).toUpperCase()}';

          await _client.from(SupabaseConstants.tableProfiles).insert({
            'id': userId,
            'full_name': fullName.trim(),
            'email': email.trim(),
            'username': username,
            'user_code': userCode,
            'referral_code': newRefCode,
            'coins_balance': 250,
            'level': 1,
            'xp': 0,
            'state_rank': 142,
            'daily_reminder': true,
          });

          await _client.from(SupabaseConstants.tableCoinTransactions).insert({
            'user_id': userId,
            'type': 'earned',
            'amount': 250,
            'source': 'signup_bonus',
            'description': 'Welcome signup bonus 🪙',
          });
        }

        // Apply referral code if provided
        if (referralCode != null && referralCode.trim().isNotEmpty) {
          try {
            await _client.rpc('process_referral_signup', params: {
              'new_user_id': userId,
              'ref_code': referralCode.trim(),
            });
          } catch (e) {
            debugPrint('Referral RPC error: $e');
          }
        }
      } catch (e) {
        debugPrint('Post signup profile setup notice: $e');
      }
    }

    // Auto-login immediately since email confirmation is disabled/auto-confirmed
    if (_client.auth.currentSession == null) {
      try {
        final loginRes = await _client.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );
        return loginRes;
      } catch (e) {
        debugPrint('Auto login after signup: $e');
      }
    }

    return response;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ---------------- PROFILES ----------------
  Future<ProfileModel?> getProfile(String userId) async {
    try {
      final res = await _client
          .from(SupabaseConstants.tableProfiles)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (res == null) return null;
      return ProfileModel.fromJson(res);
    } catch (e) {
      debugPrint('Error getting profile: $e');
      return null;
    }
  }

  Future<void> updateProfile(ProfileModel profile) async {
    await _client
        .from(SupabaseConstants.tableProfiles)
        .update(profile.toJson())
        .eq('id', profile.id);
  }

  Future<void> updateProfileData(String userId, Map<String, dynamic> data) async {
    await _client
        .from(SupabaseConstants.tableProfiles)
        .update(data)
        .eq('id', userId);
  }

  Future<void> updateDailyReminder(String userId, bool enabled) async {
    await _client
        .from(SupabaseConstants.tableProfiles)
        .update({'daily_reminder': enabled})
        .eq('id', userId);
  }

  Future<bool> checkReferralCodeValid(String code) async {
    try {
      final res = await _client
          .from(SupabaseConstants.tableProfiles)
          .select('id')
          .eq('referral_code', code.trim().toUpperCase())
          .maybeSingle();
      return res != null;
    } catch (_) {
      return false;
    }
  }

  // ---------------- CATEGORIES & QUESTIONS ----------------
  Future<List<QuizCategoryModel>> getCategories() async {
    try {
      final List<dynamic> res = await _client
          .from(SupabaseConstants.tableQuizCategories)
          .select()
          .order('name');
      return res.map((item) => QuizCategoryModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [];
    }
  }

  Future<List<QuestionModel>> getQuestionsForCategory(String categoryId, {int limit = 10}) async {
    try {
      final List<dynamic> res = await _client
          .from(SupabaseConstants.tableQuestions)
          .select()
          .eq('category_id', categoryId)
          .limit(limit);

      return res.map((item) => QuestionModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching questions: $e');
      return [];
    }
  }

  // ---------------- DAILY CHALLENGE ----------------
  Future<DailyChallengeModel?> getTodayChallenge() async {
    try {
      final res = await _client
          .from(SupabaseConstants.tableDailyChallenges)
          .select()
          .order('date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res == null) return null;
      return DailyChallengeModel.fromJson(res);
    } catch (e) {
      debugPrint('Error fetching daily challenge: $e');
      return null;
    }
  }

  Future<DailyChallengeProgressModel?> getDailyChallengeProgress(
      String userId, String challengeId) async {
    try {
      final res = await _client
          .from(SupabaseConstants.tableDailyChallengeProgress)
          .select()
          .eq('user_id', userId)
          .eq('challenge_id', challengeId)
          .maybeSingle();

      if (res == null) return null;
      return DailyChallengeProgressModel.fromJson(res);
    } catch (e) {
      debugPrint('Error fetching challenge progress: $e');
      return null;
    }
  }

  Future<void> updateChallengeProgress({
    required String userId,
    required String challengeId,
    required int completedCount,
    required bool isFinished,
  }) async {
    await _client.from(SupabaseConstants.tableDailyChallengeProgress).upsert({
      'user_id': userId,
      'challenge_id': challengeId,
      'questions_completed': completedCount,
      'completed': isFinished,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ---------------- QUIZ ATTEMPTS & REWARDS ----------------
  Future<String> submitQuizAttempt({
    required String userId,
    required String categoryId,
    required String mode,
    required int score,
    required int correctCount,
    required int totalQuestions,
    required int coinsEarned,
    required int xpEarned,
    required List<Map<String, dynamic>> answers,
  }) async {
    // 1. Insert quiz attempt
    final attemptRes = await _client
        .from(SupabaseConstants.tableQuizAttempts)
        .insert({
          'user_id': userId,
          'category_id': categoryId,
          'mode': mode,
          'score': score,
          'correct_count': correctCount,
          'total_questions': totalQuestions,
          'coins_earned': coinsEarned,
          'xp_earned': xpEarned,
          'completed_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();

    final String attemptId = attemptRes['id'] as String;

    // 2. Insert attempt answers
    if (answers.isNotEmpty) {
      final answersData = answers.map((ans) {
        return {
          'attempt_id': attemptId,
          'question_id': ans['question_id'],
          'selected_option': ans['selected_option'],
          'is_correct': ans['is_correct'],
          'time_taken_seconds': ans['time_taken_seconds'] ?? 0,
        };
      }).toList();

      await _client.from(SupabaseConstants.tableQuizAttemptAnswers).insert(answersData);
    }

    // 3. Update user profile stats & coins
    final profile = await getProfile(userId);
    if (profile != null) {
      final newStreak = profile.currentStreak + 1;
      final bestStreak = newStreak > profile.bestStreak ? newStreak : profile.bestStreak;
      final newCoins = profile.coinsBalance + coinsEarned;
      final newXp = profile.xp + xpEarned;
      final newLevel = (newXp ~/ 500) + 1;

      await _client.from(SupabaseConstants.tableProfiles).update({
        'coins_balance': newCoins,
        'xp': newXp,
        'level': newLevel,
        'current_streak': newStreak,
        'best_streak': bestStreak,
        'quizzes_played': profile.quizzesPlayed + 1,
        'correct_answers': profile.correctAnswers + correctCount,
        'total_answers': profile.totalAnswers + totalQuestions,
      }).eq('id', userId);

      // Record coin transaction
      if (coinsEarned > 0) {
        await _client.from(SupabaseConstants.tableCoinTransactions).insert({
          'user_id': userId,
          'type': 'earned',
          'amount': coinsEarned,
          'source': mode == 'daily_challenge' ? 'daily_challenge' : 'quiz',
          'description': 'Earned from $mode quiz ($correctCount/$totalQuestions correct)',
        });
      }

      // Upsert daily leaderboard entry
      await _client.from(SupabaseConstants.tableLeaderboardDaily).upsert({
        'user_id': userId,
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'points_earned': score,
        'rank': 1,
      }, onConflict: 'user_id,date');
    }

    return attemptId;
  }

  // ---------------- LEADERBOARD & BADGES ----------------
  Future<List<LeaderboardEntryModel>> getTodayChampions() async {
    try {
      final List<dynamic> res = await _client
          .from(SupabaseConstants.tableLeaderboardDaily)
          .select('id, user_id, points_earned, rank, profiles(full_name, avatar_url)')
          .order('points_earned', ascending: false)
          .limit(10);

      return res.map((item) => LeaderboardEntryModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      return [];
    }
  }

  Future<List<BadgeModel>> getBadgesWithUserStatus(String userId) async {
    try {
      final List<dynamic> allBadges =
          await _client.from(SupabaseConstants.tableBadges).select().order('name');

      final List<dynamic> userBadges = await _client
          .from(SupabaseConstants.tableUserBadges)
          .select('badge_id, unlocked_at')
          .eq('user_id', userId);

      final Map<String, DateTime> unlockedMap = {};
      for (final ub in userBadges) {
        unlockedMap[ub['badge_id'] as String] =
            DateTime.tryParse(ub['unlocked_at']?.toString() ?? '') ?? DateTime.now();
      }

      return allBadges.map((badgeJson) {
        final bId = badgeJson['id'] as String;
        final isUnlocked = unlockedMap.containsKey(bId);
        return BadgeModel.fromJson(
          badgeJson as Map<String, dynamic>,
          isUnlocked: isUnlocked,
          unlockedAt: unlockedMap[bId],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching badges: $e');
      return [];
    }
  }

  Future<List<BadgeModel>> checkAndUnlockBadges(String userId) async {
    final List<BadgeModel> newlyUnlocked = [];
    try {
      final profile = await getProfile(userId);
      if (profile == null) return [];

      final badges = await getBadgesWithUserStatus(userId);
      for (final badge in badges) {
        if (!badge.isUnlocked) {
          bool qualify = false;
          if (badge.name == 'GK Champ' && profile.accuracyRate >= 80 && profile.quizzesPlayed >= 1) {
            qualify = true;
          } else if (badge.name == 'Streak Master' && profile.currentStreak >= 3) {
            qualify = true;
          } else if (badge.name == 'Speed Demon' && profile.quizzesPlayed >= 2) {
            qualify = true;
          }

          if (qualify) {
            await _client.from(SupabaseConstants.tableUserBadges).insert({
              'user_id': userId,
              'badge_id': badge.id,
            });
            newlyUnlocked.add(badge);
          }
        }
      }
    } catch (e) {
      debugPrint('Badge unlock check notice: $e');
    }
    return newlyUnlocked;
  }

  // ---------------- 1v1 LIVE BATTLES ----------------
  Future<LiveBattleModel> findOrCreateBattle(String userId, String categoryId) async {
    // 1. Look for waiting battle created by another player
    final waiting = await _client
        .from(SupabaseConstants.tableLiveBattles)
        .select()
        .eq('category_id', categoryId)
        .eq('status', 'waiting')
        .neq('player1_id', userId)
        .limit(1)
        .maybeSingle();

    if (waiting != null) {
      // Join as player 2
      final joined = await _client
          .from(SupabaseConstants.tableLiveBattles)
          .update({
            'player2_id': userId,
            'status': 'live',
          })
          .eq('id', waiting['id'])
          .select()
          .single();

      return LiveBattleModel.fromJson(joined);
    }

    // 2. Otherwise create a new waiting battle with questions attached
    final questions = await getQuestionsForCategory(categoryId, limit: 5);
    final questionsJson = questions.map((q) => q.toJson()).toList();

    final created = await _client
        .from(SupabaseConstants.tableLiveBattles)
        .insert({
          'player1_id': userId,
          'category_id': categoryId,
          'status': 'waiting',
          'player1_score': 0,
          'player2_score': 0,
          'current_question_index': 0,
          'questions': questionsJson,
        })
        .select()
        .single();

    return LiveBattleModel.fromJson(created);
  }

  RealtimeChannel subscribeToBattle({
    required String battleId,
    required Function(LiveBattleModel) onUpdate,
  }) {
    final channel = _client.channel('public:live_battles:$battleId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConstants.tableLiveBattles,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: battleId,
          ),
          callback: (payload) {
            if (payload.newRecord.isNotEmpty) {
              onUpdate(LiveBattleModel.fromJson(payload.newRecord));
            }
          },
        )
        .subscribe();
    return channel;
  }

  Future<void> updateBattleScore({
    required String battleId,
    required bool isPlayer1,
    required int addedScore,
    required int nextIndex,
    bool finish = false,
    String? winnerId,
  }) async {
    final Map<String, dynamic> updateData = {
      'current_question_index': nextIndex,
    };
    if (isPlayer1) {
      updateData['player1_score'] = addedScore;
    } else {
      updateData['player2_score'] = addedScore;
    }
    if (finish) {
      updateData['status'] = 'completed';
      updateData['winner_id'] = winnerId;
    }
    await _client
        .from(SupabaseConstants.tableLiveBattles)
        .update(updateData)
        .eq('id', battleId);
  }

  // ---------------- BOOKS & SHOP ----------------
  Future<List<BookModel>> getBooks({String? categoryId, String? search}) async {
    try {
      var query = _client.from(SupabaseConstants.tableBooks).select();

      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }
      if (search != null && search.trim().isNotEmpty) {
        query = query.ilike('title', '%${search.trim()}%');
      }

      final List<dynamic> res = await query.order('created_at');
      return res.map((item) => BookModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching books: $e');
      return [];
    }
  }

  Future<BookModel?> getBookById(String bookId) async {
    try {
      final res = await _client
          .from(SupabaseConstants.tableBooks)
          .select('*, book_highlights(*)')
          .eq('id', bookId)
          .maybeSingle();

      if (res == null) return null;
      return BookModel.fromJson(res);
    } catch (e) {
      debugPrint('Error getting book: $e');
      return null;
    }
  }

  // ---------------- CART ----------------
  Future<List<CartItemModel>> getCartItems(String userId) async {
    try {
      final List<dynamic> res = await _client
          .from(SupabaseConstants.tableCartItems)
          .select('*, books(*)')
          .eq('user_id', userId)
          .order('created_at');

      return res.map((item) => CartItemModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching cart items: $e');
      return [];
    }
  }

  Future<void> addToCart({
    required String userId,
    required String bookId,
    int quantity = 1,
  }) async {
    // Check if item already exists
    final existing = await _client
        .from(SupabaseConstants.tableCartItems)
        .select()
        .eq('user_id', userId)
        .eq('book_id', bookId)
        .maybeSingle();

    if (existing != null) {
      final curQty = existing['quantity'] as int? ?? 1;
      await _client
          .from(SupabaseConstants.tableCartItems)
          .update({'quantity': curQty + quantity})
          .eq('id', existing['id']);
    } else {
      await _client.from(SupabaseConstants.tableCartItems).insert({
        'user_id': userId,
        'book_id': bookId,
        'quantity': quantity,
      });
    }
  }

  Future<void> updateCartItemQuantity(String cartItemId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(cartItemId);
    } else {
      await _client
          .from(SupabaseConstants.tableCartItems)
          .update({'quantity': quantity})
          .eq('id', cartItemId);
    }
  }

  Future<void> removeFromCart(String cartItemId) async {
    await _client.from(SupabaseConstants.tableCartItems).delete().eq('id', cartItemId);
  }

  Future<void> clearCart(String userId) async {
    await _client.from(SupabaseConstants.tableCartItems).delete().eq('user_id', userId);
  }

  // ---------------- ADDRESSES ----------------
  Future<List<AddressModel>> getAddresses(String userId) async {
    try {
      final List<dynamic> res = await _client
          .from(SupabaseConstants.tableAddresses)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return res.map((item) => AddressModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching addresses: $e');
      return [];
    }
  }

  Future<AddressModel> addAddress(AddressModel address) async {
    final res = await _client
        .from(SupabaseConstants.tableAddresses)
        .insert(address.toJson())
        .select()
        .single();
    return AddressModel.fromJson(res);
  }

  // ---------------- ORDERS & CHECKOUT ----------------
  Future<OrderModel> placeOrder({
    required String userId,
    String? addressId,
    required String deliveryAddress,
    required double subtotal,
    required double deliveryCharge,
    required double discountApplied,
    required int coinsRedeemed,
    required double totalAmount,
    required String paymentMethod,
    required List<CartItemModel> items,
    String? upiRef,
  }) async {
    final trackingId = 'EK-${DateTime.now().millisecondsSinceEpoch % 900000 + 100000}IN';
    final estDelivery = DateTime.now().add(const Duration(days: 4));

    final orderPayload = {
      'user_id': userId,
      'address_id': addressId,
      'delivery_address': deliveryAddress,
      'subtotal': subtotal,
      'delivery_charge': deliveryCharge,
      'discount_applied': discountApplied,
      'coins_redeemed': coinsRedeemed,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'status': paymentMethod == 'UPI' ? 'Confirmed' : 'Placed',
      'tracking_id': trackingId,
      'estimated_delivery_date': estDelivery.toIso8601String(),
    };

    if (upiRef != null && upiRef.trim().isNotEmpty) {
      orderPayload['upi_ref'] = upiRef.trim();
    }

    // 1. Create order
    final orderRes = await _client
        .from(SupabaseConstants.tableOrders)
        .insert(orderPayload)
        .select()
        .single();

    final orderId = orderRes['id'] as String;

    // 2. Create order items
    final List<Map<String, dynamic>> orderItemsData = items.map((cartItem) {
      return {
        'order_id': orderId,
        'book_id': cartItem.bookId,
        'quantity': cartItem.quantity,
        'price_at_purchase': cartItem.book?.price ?? 199.0,
      };
    }).toList();

    if (orderItemsData.isNotEmpty) {
      await _client.from(SupabaseConstants.tableOrderItems).insert(orderItemsData);
    }

    // 3. Clear cart
    await clearCart(userId);

    // 4. Decrement redeemed coins from user profile
    if (coinsRedeemed > 0) {
      final profile = await getProfile(userId);
      if (profile != null) {
        final newBalance = (profile.coinsBalance - coinsRedeemed).clamp(0, 9999999);
        await _client
            .from(SupabaseConstants.tableProfiles)
            .update({'coins_balance': newBalance})
            .eq('id', userId);

        await _client.from(SupabaseConstants.tableCoinTransactions).insert({
          'user_id': userId,
          'type': 'redeemed',
          'amount': coinsRedeemed,
          'source': 'order_redeem',
          'description': 'Redeemed ₹${coinsRedeemed ~/ 5} discount on order #$trackingId',
        });
      }
    }

    return OrderModel.fromJson(orderRes);
  }

  Future<List<OrderModel>> getUserOrders(String userId) async {
    try {
      final List<dynamic> res = await _client
          .from(SupabaseConstants.tableOrders)
          .select('*, order_items(*, books(*))')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return res.map((item) => OrderModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error getting user orders: $e');
      return [];
    }
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final res = await _client
          .from(SupabaseConstants.tableOrders)
          .select('*, order_items(*, books(*))')
          .eq('id', orderId)
          .maybeSingle();

      if (res == null) return null;
      return OrderModel.fromJson(res);
    } catch (e) {
      debugPrint('Error getting order: $e');
      return null;
    }
  }

  // ---------------- WALLET / TRANSACTIONS ----------------
  Future<List<CoinTransactionModel>> getCoinTransactions(String userId) async {
    try {
      final List<dynamic> res = await _client
          .from(SupabaseConstants.tableCoinTransactions)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return res.map((item) => CoinTransactionModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error getting transactions: $e');
      return [];
    }
  }

  Future<List<QuizAttemptModel>> getUserQuizHistory(String userId) async {
    try {
      final List<dynamic> res = await _client
          .from(SupabaseConstants.tableQuizAttempts)
          .select()
          .eq('user_id', userId)
          .order('started_at', ascending: false);

      return res.map((item) => QuizAttemptModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error getting quiz history: $e');
      return [];
    }
  }
}
