import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/stat_card.dart';
import '../../providers/profile_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../data/models/quiz_category_model.dart';

class QuizArenaScreen extends ConsumerWidget {
  const QuizArenaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.value;
    final categoriesAsync = ref.watch(quizCategoriesProvider);
    final championsAsync = ref.watch(todayChampionsProvider);
    final challengeAsync = ref.watch(todayChallengeProvider);

    final streak = profile?.currentStreak ?? 0;
    final stateRank = profile?.stateRank ?? 142;
    final accuracy = profile != null ? profile.accuracyRate.toStringAsFixed(0) : '85';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header & Quick Match
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PLAY & LEARN',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      'Quiz Arena',
                      style: AppTextStyles.headlineLg.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _openModeCategoryPicker(
                      context,
                      categoriesAsync.value ?? [],
                      '1v1',
                      'Quick Match 1v1',
                    );
                  },
                  icon: const Icon(Icons.bolt, size: 18),
                  label: const Text('Quick Match'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Live User Stats Cards Strip (3 cards)
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.local_fire_department,
                    iconColor: AppColors.secondary,
                    iconBgColor: AppColors.secondaryFixed.withOpacity(0.3),
                    label: 'Streak',
                    value: '$streak Days',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    icon: Icons.military_tech,
                    iconColor: AppColors.primary,
                    iconBgColor: AppColors.surfaceContainerHigh,
                    label: 'State Rank',
                    value: '#$stateRank',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    icon: Icons.verified,
                    iconColor: AppColors.tertiary,
                    iconBgColor: AppColors.tertiaryFixed.withOpacity(0.2),
                    label: 'Accuracy',
                    value: '$accuracy%',
                    valueColor: AppColors.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 1. Daily Challenge Hero Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.superQuizGradient,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.22),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryContainer.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'DAILY CHALLENGE',
                              style: AppTextStyles.labelSm.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: AppColors.goldButtonGradient,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stars_rounded,
                                size: 14, color: AppColors.onSecondaryFixed),
                            const SizedBox(width: 4),
                            Text(
                              '+100 Points',
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.onSecondaryFixed,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Today's Super Quiz: Daily GK & Current Affairs",
                              style: AppTextStyles.headlineSm.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Win 100 Quiz Points and boost your streak on the leaderboard!',
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.primaryFixed.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl:
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuCmBJuLJio1BBp2_steJkbTMlj1A8K0gy4A1Cw3a3tieJHcerbGC40Zh6ppElKKe4Tg8hFhfzjSQNRp12KEPb_kgtUBXmMq-QepRuxtWwBqkVjcAw5UOx6KNKpJjFpQHOfdGi5piunnk5MBDUH4f-MyQs7unMuRA3S5KLvDZChbp9JF_HNZrs0OwB5HwZ4R8n5Eb2yX7n04j44wKdJYg7ycUgr3YEFGP841agiXGRSSgfxUZdCXLX-3OQ',
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      final catId = challengeAsync.value?.categoryId ??
                          '22222222-2222-2222-2222-222222222222';
                      context.push(
                        '/quiz-session?categoryId=$catId&mode=daily_challenge&title=Daily GK Challenge',
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldButtonGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow,
                              color: AppColors.onSecondaryFixed, size: 22),
                          const SizedBox(width: 6),
                          Text(
                            'Play Daily Challenge',
                            style: AppTextStyles.labelLg.copyWith(
                              color: AppColors.onSecondaryFixed,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Game Formats Section (4 modes)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Game Modes',
                  style: AppTextStyles.headlineSm.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Select your play style',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.35,
              children: [
                _buildGameModeCard(
                  icon: Icons.psychology,
                  iconBg: AppColors.primaryFixed,
                  iconColor: AppColors.primaryContainer,
                  badgeText: 'Untimed',
                  title: 'Solo Practice',
                  subtitle: 'Sharpen at your pace',
                  onTap: () {
                    _openModeCategoryPicker(
                      context,
                      categoriesAsync.value ?? [],
                      'solo',
                      'Solo Practice',
                    );
                  },
                ),
                _buildGameModeCard(
                  icon: Icons.sports_kabaddi,
                  iconBg: AppColors.secondaryFixed,
                  iconColor: AppColors.secondaryContainer,
                  badgeText: 'LIVE',
                  badgeColor: AppColors.crimsonRed,
                  title: '1 vs 1 Battle',
                  subtitle: 'Challenge peers online',
                  onTap: () {
                    _openModeCategoryPicker(
                      context,
                      categoriesAsync.value ?? [],
                      '1v1',
                      '1 vs 1 Live Battle',
                    );
                  },
                ),
                _buildGameModeCard(
                  icon: Icons.emoji_events,
                  iconBg: AppColors.tertiaryFixed,
                  iconColor: AppColors.tertiaryContainer,
                  badgeText: '₹10K Pool',
                  title: 'Mega Contest',
                  subtitle: 'Win book bundles',
                  onTap: () {
                    _openModeCategoryPicker(
                      context,
                      categoriesAsync.value ?? [],
                      'mega_contest',
                      'Mega Contest League',
                    );
                  },
                ),
                _buildGameModeCard(
                  icon: Icons.timer,
                  iconBg: AppColors.surfaceContainerHigh,
                  iconColor: AppColors.onSurface,
                  badgeText: 'Speed',
                  title: 'Topic Rush',
                  subtitle: '60-sec rapid fire',
                  onTap: () {
                    _openModeCategoryPicker(
                      context,
                      categoriesAsync.value ?? [],
                      'topic_rush',
                      '60s Topic Rush',
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Explore Categories
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explore Categories',
                      style: AppTextStyles.headlineSm.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Over 8,000 verified MCQs',
                      style: AppTextStyles.bodySm,
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '7 Subjects',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Categories List
            categoriesAsync.when(
              data: (categories) {
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return GestureDetector(
                      onTap: () => _openQuizModal(context, cat),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.outlineVariant.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.secondaryFixed.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getCategoryIcon(cat.iconKey),
                                color: AppColors.secondary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        cat.name,
                                        style: AppTextStyles.labelLg.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceContainer,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          cat.difficulty,
                                          style: AppTextStyles.labelSm.copyWith(
                                            fontSize: 9,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${cat.mcqCount}+ MCQs • Practice & Tests',
                                    style: AppTextStyles.bodySm.copyWith(
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error loading categories: $err'),
            ),
            const SizedBox(height: 24),

            // 4. Today's Champions Leaderboard
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Champions",
                      style: AppTextStyles.headlineSm.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Daily points leaderboard',
                      style: AppTextStyles.bodySm,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Daily',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            championsAsync.when(
              data: (champions) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.outlineVariant.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: champions.map((champ) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.surfaceContainer,
                                  ),
                                  child: ClipOval(
                                    child: champ.avatarUrl != null &&
                                            champ.avatarUrl!.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: champ.avatarUrl!,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) =>
                                                const Icon(Icons.person, size: 20),
                                          )
                                        : const Icon(Icons.person, size: 20),
                                  ),
                                ),
                                Positioned(
                                  top: -2,
                                  left: -2,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: champ.rank == 1
                                          ? AppColors.secondaryContainer
                                          : AppColors.surfaceContainerHigh,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${champ.rank}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    champ.userName,
                                    style: AppTextStyles.labelMd.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${champ.accuracy.toInt()}% Accuracy',
                                    style: AppTextStyles.bodySm.copyWith(
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryContainer
                                    .withOpacity(0.18),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.secondary.withOpacity(0.4),
                                ),
                              ),
                              child: Text(
                                '+${champ.pointsEarned} pts',
                                style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error loading leaderboard: $err'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGameModeCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String badgeText,
    Color? badgeColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.outlineVariant.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor ?? AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: badgeColor != null ? Colors.white : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLg.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySm.copyWith(
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openQuizModal(BuildContext context, QuizCategoryModel category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getCategoryIcon(category.iconKey),
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: AppTextStyles.headlineSm.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${category.mcqCount}+ Questions • ${category.difficulty}',
                          style: AppTextStyles.bodySm,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildModalStat(Icons.timer, '15s', 'Per MCQ'),
                  _buildModalStat(Icons.stars, '+10 Pts', 'Per Correct'),
                  _buildModalStat(Icons.quiz, '10 MCQs', 'Total'),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Test your knowledge against thousands of aspirants. Get instant score, detailed explanation notes, and earn quiz points to climb the leaderboard!',
                style: AppTextStyles.bodySm.copyWith(height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.surfaceContainer,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurface),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push(
                          '/quiz-session?categoryId=${category.id}&mode=solo&title=${Uri.encodeComponent(category.name)}',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_circle_filled, size: 20),
                          const SizedBox(width: 8),
                          Text('Start Quiz', style: AppTextStyles.labelLg),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _openModeCategoryPicker(
    BuildContext context,
    List<QuizCategoryModel> categories,
    String mode,
    String title,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: 480,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Subject for $title',
                style: AppTextStyles.headlineSm.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text('Pick a category to begin immediately', style: AppTextStyles.bodySm),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return ListTile(
                      tileColor: AppColors.surfaceContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      leading: Icon(
                        _getCategoryIcon(cat.iconKey),
                        color: AppColors.secondary,
                      ),
                      title: Text(
                        cat.name,
                        style: AppTextStyles.labelMd.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${cat.mcqCount}+ MCQs • ${cat.difficulty}',
                        style: AppTextStyles.bodySm.copyWith(fontSize: 11),
                      ),
                      trailing: const Icon(
                        Icons.play_arrow,
                        color: AppColors.primary,
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        if (mode == '1v1') {
                          context.push(
                            '/live-battle?categoryId=${cat.id}&categoryName=${Uri.encodeComponent(cat.name)}',
                          );
                        } else {
                          context.push(
                            '/quiz-session?categoryId=${cat.id}&mode=$mode&title=${Uri.encodeComponent(cat.name)}',
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalStat(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.labelLg.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.bodySm.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String? key) {
    switch (key) {
      case 'account_balance':
        return Icons.account_balance;
      case 'stars':
        return Icons.stars;
      case 'science':
        return Icons.science;
      case 'newspaper':
        return Icons.newspaper;
      case 'calculate':
        return Icons.calculate;
      case 'public':
        return Icons.public;
      case 'functions':
        return Icons.functions;
      default:
        return Icons.extension;
    }
  }
}
