import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../data/models/question_model.dart';
import '../../data/models/badge_model.dart';

class LiveQuizSessionScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final String mode; // 'solo', 'daily_challenge', 'mega_contest', 'topic_rush'
  final String title;

  const LiveQuizSessionScreen({
    super.key,
    required this.categoryId,
    this.mode = 'solo',
    this.title = 'Quiz Session',
  });

  @override
  ConsumerState<LiveQuizSessionScreen> createState() =>
      _LiveQuizSessionScreenState();
}

class _LiveQuizSessionScreenState extends ConsumerState<LiveQuizSessionScreen> {
  int _currentIndex = 0;
  String? _selectedOption;
  bool _answered = false;
  int _score = 0;
  int _correctCount = 0;
  int _coinsEarned = 0;
  int _xpEarned = 0;

  Timer? _countdownTimer;
  late int _secondsLeft;
  final List<Map<String, dynamic>> _recordedAnswers = [];

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.mode == 'topic_rush' ? 8 : 15;
  }

  void _startTimer(int limit) {
    _countdownTimer?.cancel();
    _secondsLeft = limit;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
        _handleTimeOut();
      }
    });
  }

  void _handleTimeOut() {
    if (_answered) return;
    _onOptionSelected('TIMEOUT', const []);
  }

  void _onOptionSelected(String optionKey, List<QuestionModel> questions) {
    if (_answered) return;
    _countdownTimer?.cancel();

    final currentQuestion = questions[_currentIndex];
    final isCorrect = optionKey.toUpperCase() == currentQuestion.correctOption.toUpperCase();

    final coinMultiplier = widget.mode == 'mega_contest' ? 20 : 10;
    final xpMultiplier = widget.mode == 'mega_contest' ? 30 : 15;

    setState(() {
      _selectedOption = optionKey;
      _answered = true;

      if (isCorrect) {
        _score += 10;
        _correctCount++;
        _coinsEarned += coinMultiplier;
        _xpEarned += xpMultiplier;
      }

      _recordedAnswers.add({
        'question_id': currentQuestion.id,
        'selected_option': optionKey,
        'is_correct': isCorrect,
        'time_taken_seconds': currentQuestion.timeLimitSeconds - _secondsLeft,
      });
    });
  }

  void _nextQuestion(List<QuestionModel> questions) {
    if (_currentIndex < questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _answered = false;
      });
      final limit = widget.mode == 'topic_rush'
          ? 8
          : questions[_currentIndex].timeLimitSeconds;
      _startTimer(limit);
    } else {
      _finishQuiz(questions.length);
    }
  }

  Future<void> _finishQuiz(int totalQuestions) async {
    _countdownTimer?.cancel();
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final service = ref.read(supabaseServiceProvider);

    // If Daily Challenge, add bonus coins!
    int finalCoins = _coinsEarned;
    if (widget.mode == 'daily_challenge') {
      final challenge = await service.getTodayChallenge();
      if (challenge != null) {
        finalCoins += challenge.bonusCoins;
        await service.updateChallengeProgress(
          userId: userId,
          challengeId: challenge.id,
          completedCount: _correctCount,
          isFinished: true,
        );
      }
    }

    // Submit attempt to Supabase
    await service.submitQuizAttempt(
      userId: userId,
      categoryId: widget.categoryId,
      mode: widget.mode,
      score: _score,
      correctCount: _correctCount,
      totalQuestions: totalQuestions,
      coinsEarned: finalCoins,
      xpEarned: _xpEarned,
      answers: _recordedAnswers,
    );

    // Check newly unlocked badges
    List<BadgeModel> newBadges = [];
    try {
      newBadges = await service.checkAndUnlockBadges(userId);
    } catch (_) {}

    // Refresh profile state
    ref.read(profileRefreshTriggerProvider.notifier).state++;
    ref.invalidate(todayChallengeProvider);
    ref.invalidate(dailyChallengeProgressProvider);

    if (mounted) {
      context.pushReplacement(
        '/quiz-result?score=$_score&correct=$_correctCount&total=$totalQuestions&coins=$finalCoins&xp=$_xpEarned',
        extra: newBadges,
      );
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(
      questionsFamilyProvider((
        categoryId: widget.categoryId,
        limit: widget.mode == 'topic_rush' ? 6 : 10,
      )),
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: CustomAppBar(
        title: widget.title,
        showBackButton: true,
      ),
      body: questionsAsync.when(
        data: (questions) {
          if (questions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.quiz_outlined, size: 56, color: AppColors.outline),
                  const SizedBox(height: 16),
                  Text('No questions found for this topic.', style: AppTextStyles.bodyLg),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Back to Arena'),
                  ),
                ],
              ),
            );
          }

          // Start timer for initial question if not running
          if (_countdownTimer == null && !_answered) {
            final limit = widget.mode == 'topic_rush'
                ? 8
                : questions[_currentIndex].timeLimitSeconds;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _startTimer(limit);
            });
          }

          final currentQ = questions[_currentIndex];
          final progress = (_currentIndex + 1) / questions.length;

          return Column(
            children: [
              // Top Strip Progress Bar
              LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: AppColors.surfaceContainerHighest,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.tertiary,
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meta Info Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.account_balance,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.title.toUpperCase(),
                                    style: AppTextStyles.labelSm.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Question ${_currentIndex + 1}',
                                      style: AppTextStyles.headlineSm.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' / ${questions.length}',
                                      style: AppTextStyles.bodySm.copyWith(
                                        color: AppColors.outline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // Timer Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _secondsLeft <= 4
                                      ? AppColors.errorContainer
                                      : AppColors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.timer,
                                      size: 15,
                                      color: _secondsLeft <= 4
                                          ? AppColors.error
                                          : AppColors.onSurface,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_secondsLeft}s',
                                      style: AppTextStyles.labelMd.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: _secondsLeft <= 4
                                            ? AppColors.error
                                            : AppColors.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Points Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryFixed,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.local_fire_department,
                                      size: 15,
                                      color: AppColors.onSecondaryFixed,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '+10 Pts',
                                      style: AppTextStyles.labelSm.copyWith(
                                        color: AppColors.onSecondaryFixed,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Question Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.outlineVariant.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                currentQ.difficulty.toUpperCase(),
                                style: AppTextStyles.labelSm.copyWith(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              currentQ.questionText,
                              style: AppTextStyles.headlineMd.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                            if (currentQ.imageUrl != null &&
                                currentQ.imageUrl!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: currentQ.imageUrl!,
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Options (A, B, C, D)
                      _buildOptionTile('A', currentQ.optionA, currentQ, questions),
                      const SizedBox(height: 10),
                      _buildOptionTile('B', currentQ.optionB, currentQ, questions),
                      const SizedBox(height: 10),
                      _buildOptionTile('C', currentQ.optionC, currentQ, questions),
                      const SizedBox(height: 10),
                      _buildOptionTile('D', currentQ.optionD, currentQ, questions),
                      const SizedBox(height: 18),

                      // Immediate Feedback Banner & Explanation
                      if (_answered) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _selectedOption?.toUpperCase() ==
                                    currentQ.correctOption.toUpperCase()
                                ? AppColors.tertiaryFixed.withOpacity(0.18)
                                : AppColors.errorContainer.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedOption?.toUpperCase() ==
                                      currentQ.correctOption.toUpperCase()
                                  ? AppColors.tertiaryFixed
                                  : AppColors.error,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _selectedOption?.toUpperCase() ==
                                            currentQ.correctOption.toUpperCase()
                                        ? Icons.celebration
                                        : Icons.cancel,
                                    color: _selectedOption?.toUpperCase() ==
                                            currentQ.correctOption.toUpperCase()
                                        ? AppColors.tertiary
                                        : AppColors.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedOption?.toUpperCase() ==
                                            currentQ.correctOption.toUpperCase()
                                        ? 'Correct Answer! (+10 Pts)'
                                        : 'Incorrect. Correct: Option ${currentQ.correctOption}',
                                    style: AppTextStyles.labelLg.copyWith(
                                      color: _selectedOption?.toUpperCase() ==
                                              currentQ.correctOption.toUpperCase()
                                          ? AppColors.tertiaryFixed
                                          : AppColors.error,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              if (currentQ.explanationText != null &&
                                  currentQ.explanationText!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  currentQ.explanationText!,
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.onSurface,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Next Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => _nextQuestion(questions),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentIndex == questions.length - 1
                                      ? 'Finish Quiz'
                                      : 'Next Question',
                                  style: AppTextStyles.labelLg.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, _) => Center(
          child: Text('Error loading questions: $err'),
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    String optionKey,
    String optionText,
    QuestionModel q,
    List<QuestionModel> allQuestions,
  ) {
    final isSelected = _selectedOption == optionKey;
    final isCorrectOption = q.correctOption.toUpperCase() == optionKey.toUpperCase();

    Color bgColor = AppColors.surfaceContainerLowest;
    Color borderColor = AppColors.outlineVariant.withOpacity(0.3);
    Color chipBg = AppColors.surfaceContainer;
    Color chipTextColor = AppColors.onSurfaceVariant;
    Widget trailingIndicator = const SizedBox();

    if (_answered) {
      if (isCorrectOption) {
        bgColor = AppColors.tertiaryFixed.withOpacity(0.2);
        borderColor = AppColors.tertiary;
        chipBg = AppColors.tertiary;
        chipTextColor = AppColors.onTertiary;
        trailingIndicator = const Icon(Icons.check_circle, color: AppColors.tertiary, size: 22);
      } else if (isSelected) {
        bgColor = AppColors.errorContainer.withOpacity(0.25);
        borderColor = AppColors.error;
        chipBg = AppColors.error;
        chipTextColor = AppColors.onError;
        trailingIndicator = const Icon(Icons.cancel, color: AppColors.error, size: 22);
      }
    }

    return GestureDetector(
      onTap: _answered ? null : () => _onOptionSelected(optionKey, allQuestions),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected || isCorrectOption && _answered ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  optionKey,
                  style: AppTextStyles.labelLg.copyWith(
                    color: chipTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                optionText,
                style: AppTextStyles.bodyLg.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            trailingIndicator,
          ],
        ),
      ),
    );
  }
}
