import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/wallet_provider.dart';

class QuizHistoryScreen extends ConsumerWidget {
  const QuizHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(userQuizHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Quiz History & Scorecard',
          style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: historyAsync.when(
        data: (attempts) {
          if (attempts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history_edu, size: 56, color: AppColors.outline),
                    const SizedBox(height: 16),
                    Text(
                      'No Quiz Attempts Yet',
                      style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Jump into the Quiz Arena and test your knowledge to earn points!',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.outline),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/quiz'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.bolt, color: Colors.white),
                      label: const Text('Play a Quiz Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: attempts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final attempt = attempts[index];
              final total = attempt.totalQuestions > 0 ? attempt.totalQuestions : 10;
              final score = attempt.score;
              final accuracy = ((score / total) * 100).clamp(0, 100).toInt();
              final dateStr = DateFormat('d MMM yyyy, h:mm a').format(attempt.startedAt);

              Color accColor = AppColors.crimsonRed;
              if (accuracy >= 80) {
                accColor = AppColors.emeraldGreen;
              } else if (accuracy >= 50) {
                accColor = AppColors.secondary;
              }

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    // Accuracy badge circle
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: accColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: accColor.withOpacity(0.4), width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          '$accuracy%',
                          style: AppTextStyles.labelMd.copyWith(
                            fontWeight: FontWeight.w900,
                            color: accColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            attempt.mode == 'daily_challenge'
                                ? 'Daily Streak Challenge'
                                : 'General Knowledge Quiz',
                            style: AppTextStyles.labelLg.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Score: $score / $total • Duration: ${attempt.timeTakenSeconds}s',
                            style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            style: AppTextStyles.bodySm.copyWith(color: AppColors.outline, fontSize: 10),
                          ),
                        ],
                      ),
                    ),

                    // Coins earned
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '+${attempt.coinsEarned} PTS',
                          style: AppTextStyles.priceDisplay.copyWith(
                            fontSize: 16,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '+${attempt.xpEarned} XP',
                          style: AppTextStyles.labelSm.copyWith(
                            fontSize: 10,
                            color: AppColors.primaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryContainer)),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
