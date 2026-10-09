import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../data/models/live_battle_model.dart';
import '../../data/models/question_model.dart';

class LiveBattleArenaScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final String categoryName;

  const LiveBattleArenaScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  ConsumerState<LiveBattleArenaScreen> createState() =>
      _LiveBattleArenaScreenState();
}

class _LiveBattleArenaScreenState extends ConsumerState<LiveBattleArenaScreen> {
  LiveBattleModel? _battle;
  RealtimeChannel? _realtimeChannel;
  bool _isSearching = true;
  int _secondsElapsed = 0;
  Timer? _searchTimer;

  // Quiz state
  int _currentQuestionIndex = 0;
  List<QuestionModel> _questions = [];
  String? _selectedOption;
  bool _answered = false;
  int _myScore = 0;
  int _opponentScore = 0;
  bool _isPlayer1 = true;
  Timer? _botTimer;

  @override
  void initState() {
    super.initState();
    _startMatchmaking();
  }

  Future<void> _startMatchmaking() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _secondsElapsed++);
      }
    });

    final service = ref.read(supabaseServiceProvider);
    try {
      final battle = await service.findOrCreateBattle(userId, widget.categoryId);
      if (!mounted) return;

      setState(() {
        _battle = battle;
        _isPlayer1 = battle.player1Id == userId;
        _questions = (battle.questions)
            .map((q) => QuestionModel.fromJson(Map<String, dynamic>.from(q as Map)))
            .toList();
      });

      // Subscribe to Realtime channel
      _realtimeChannel = service.subscribeToBattle(
        battleId: battle.id,
        onUpdate: (updatedBattle) {
          if (mounted) {
            setState(() {
              _battle = updatedBattle;
              if (_isPlayer1) {
                _opponentScore = updatedBattle.player2Score;
              } else {
                _opponentScore = updatedBattle.player1Score;
              }
              if (updatedBattle.status == 'live' && _isSearching) {
                _isSearching = false;
                _searchTimer?.cancel();
              }
            });
          }
        },
      );

      // If already matched immediately
      if (battle.status == 'live') {
        setState(() {
          _isSearching = false;
          _searchTimer?.cancel();
        });
      } else {
        // Fallback: If no opponent joins after 5 seconds, match with a bot opponent
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && _isSearching) {
            setState(() {
              _isSearching = false;
              _searchTimer?.cancel();
            });
            _startBotActivity();
          }
        });
      }
    } catch (e) {
      debugPrint('Error starting battle: $e');
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _startBotActivity() {
    _botTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (!mounted || _currentQuestionIndex >= _questions.length) {
        timer.cancel();
        return;
      }
      setState(() {
        // 75% bot answer accuracy
        _opponentScore += 10;
      });
    });
  }

  Future<void> _handleAnswer(String optionKey) async {
    if (_answered || _questions.isEmpty) return;
    final currentQ = _questions[_currentQuestionIndex];
    final isCorrect = optionKey.toUpperCase() == currentQ.correctOption.toUpperCase();

    setState(() {
      _selectedOption = optionKey;
      _answered = true;
      if (isCorrect) {
        _myScore += 10;
      }
    });

    // Sync score to Supabase
    if (_battle != null) {
      final service = ref.read(supabaseServiceProvider);
      await service.updateBattleScore(
        battleId: _battle!.id,
        isPlayer1: _isPlayer1,
        addedScore: _myScore,
        nextIndex: _currentQuestionIndex + 1,
        finish: _currentQuestionIndex == _questions.length - 1,
        winnerId: _myScore >= _opponentScore
            ? ref.read(currentUserIdProvider)
            : _battle!.player2Id,
      );
    }
  }

  void _advanceQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOption = null;
        _answered = false;
      });
    } else {
      _showBattleFinishedDialog();
    }
  }

  void _showBattleFinishedDialog() {
    final isWon = _myScore > _opponentScore;
    final isTie = _myScore == _opponentScore;
    final coinsWon = isWon ? 50 : (isTie ? 20 : 5);

    final userId = ref.read(currentUserIdProvider);
    if (userId != null) {
      ref.read(supabaseServiceProvider).client.from('coin_transactions').insert({
        'user_id': userId,
        'type': 'earned',
        'amount': coinsWon,
        'source': 'quiz',
        'description': '1v1 Battle Arena ${isWon ? 'Victory' : 'Participation'}',
      });
      ref.read(profileRefreshTriggerProvider.notifier).state++;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            isWon ? 'Victory! 🏆' : (isTie ? 'Tie Game! 🤝' : 'Defeat! 💔'),
            style: AppTextStyles.headlineMd.copyWith(
              color: isWon ? AppColors.tertiary : Colors.white,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Final Score: $_myScore vs $_opponentScore',
                style: AppTextStyles.labelLg.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded, color: AppColors.secondary, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '+$coinsWon Points Added',
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/quiz');
                },
                child: const Text('Back to Arena'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _botTimer?.cancel();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isSearching) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: CustomAppBar(title: '1v1 Matchmaking', showBackButton: true),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondaryFixed.withOpacity(0.2),
                  border: Border.all(color: AppColors.secondary, width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.sports_kabaddi, size: 54, color: AppColors.secondary),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Finding Opponent...',
                style: AppTextStyles.headlineMd.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Subject: ${widget.categoryName}',
                style: AppTextStyles.bodyMd,
              ),
              const SizedBox(height: 12),
              Text(
                'Time: ${_secondsElapsed}s',
                style: AppTextStyles.labelMd.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 36),
              const CircularProgressIndicator(color: AppColors.secondary),
            ],
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const CustomAppBar(title: '1v1 Battle Arena', showBackButton: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentQ = _questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: CustomAppBar(
        title: '1v1 Battle Arena',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Scoreboard (Player 1 vs Player 2)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // You
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.person, color: Colors.white, size: 22),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('You', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '$_myScore pts',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // VS Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  // Opponent
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Opponent', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '$_opponentScore pts',
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryFixed.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.person_pin, color: AppColors.secondary, size: 24),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Question Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                  style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
                Text(
                  widget.categoryName,
                  style: AppTextStyles.labelSm.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Question Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
              ),
              child: Text(
                currentQ.questionText,
                style: AppTextStyles.headlineMd.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Options
            _buildDuelOption('A', currentQ.optionA, currentQ),
            const SizedBox(height: 10),
            _buildDuelOption('B', currentQ.optionB, currentQ),
            const SizedBox(height: 10),
            _buildDuelOption('C', currentQ.optionC, currentQ),
            const SizedBox(height: 10),
            _buildDuelOption('D', currentQ.optionD, currentQ),
            const SizedBox(height: 20),

            if (_answered) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _advanceQuestion,
                  child: Text(
                    _currentQuestionIndex == _questions.length - 1
                        ? 'View Battle Results'
                        : 'Next Round',
                    style: AppTextStyles.labelLg,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDuelOption(String key, String text, QuestionModel q) {
    final isSelected = _selectedOption == key;
    final isCorrect = q.correctOption.toUpperCase() == key.toUpperCase();

    Color bgColor = AppColors.surfaceContainerLowest;
    Color borderColor = AppColors.outlineVariant.withOpacity(0.3);

    if (_answered) {
      if (isCorrect) {
        bgColor = AppColors.tertiaryFixed.withOpacity(0.2);
        borderColor = AppColors.tertiary;
      } else if (isSelected) {
        bgColor = AppColors.errorContainer.withOpacity(0.25);
        borderColor = AppColors.error;
      }
    }

    return GestureDetector(
      onTap: _answered ? null : () => _handleAnswer(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected || isCorrect && _answered ? 2 : 1),
        ),
        child: Row(
          children: [
            Text(
              key,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
