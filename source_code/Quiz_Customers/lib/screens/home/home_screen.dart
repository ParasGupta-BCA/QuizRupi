import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/coin_badge.dart';
import '../../core/widgets/book_product_card.dart';
import '../../providers/profile_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.value;
    final categoriesAsync = ref.watch(quizCategoriesProvider);
    final booksAsync = ref.watch(booksProvider);
    final challengeAsync = ref.watch(todayChallengeProvider);
    final challengeProgressAsync = ref.watch(dailyChallengeProgressProvider);

    final completedCount = challengeProgressAsync.value?.questionsCompleted ?? 0;
    final totalQuestions = challengeAsync.value?.totalQuestions ?? 10;
    final progressPercent = (completedCount / totalQuestions).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const CustomAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(profileRefreshTriggerProvider.notifier).state++;
          ref.invalidate(booksProvider);
          ref.invalidate(todayChallengeProvider);
          ref.invalidate(dailyChallengeProgressProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Greeting & Profile Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: profile?.avatarUrl != null &&
                                      profile!.avatarUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: profile.avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) =>
                                          const Icon(Icons.person, size: 24),
                                    )
                                  : const Icon(Icons.person, size: 24),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.tertiary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.surface,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Hello, ${profile?.fullName.split(' ').first ?? 'Quizzer'}!',
                                style: AppTextStyles.headlineSm.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text('👋', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Play quizzes, earn points & shop books',
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  CoinBadge(coins: profile?.coinsBalance ?? 250),
                ],
              ),
              const SizedBox(height: 18),

              // 2. Hero Play Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.heroPlayGradient,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
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
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      top: 0,
                      child: Icon(
                        Icons.psychology,
                        size: 90,
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Glass badge
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
                              const Icon(
                                Icons.bolt,
                                size: 14,
                                color: AppColors.tertiaryFixed,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'PLAY QUIZ',
                                style: AppTextStyles.labelSm.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 240),
                          child: Text(
                            'Test Your Knowledge & Win Rewards',
                            style: AppTextStyles.headlineMd.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 260),
                          child: Text(
                            'Compete in live arenas, rack up quiz points & climb the leaderboards!',
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.primaryFixed.withOpacity(0.9),
                            ),
                          ),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: AppColors.goldButtonGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondaryContainer
                                      .withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.play_arrow,
                                  color: AppColors.onSecondaryFixed,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Start Daily Quiz',
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
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 3. Daily Challenge Progress Card
              GestureDetector(
                onTap: () {
                  final catId = challengeAsync.value?.categoryId ??
                      '22222222-2222-2222-2222-222222222222';
                  context.push(
                    '/quiz-session?categoryId=$catId&mode=daily_challenge&title=Daily GK Challenge',
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.outlineVariant.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryFixed.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.emoji_events,
                                  color: AppColors.secondary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Daily GK Challenge',
                                    style: AppTextStyles.headlineSm.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  RichText(
                                    text: TextSpan(
                                      style: AppTextStyles.bodySm,
                                      children: [
                                        TextSpan(
                                          text: '$totalQuestions MCQs for ',
                                        ),
                                        const TextSpan(
                                          text: '+50 bonus pts',
                                          style: TextStyle(
                                            color: AppColors.tertiary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Progress Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daily Progress',
                            style: AppTextStyles.labelSm,
                          ),
                          Text(
                            '$completedCount / $totalQuestions Completed',
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progressPercent,
                          minHeight: 8,
                          backgroundColor: AppColors.surfaceContainer,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // 4. Trending Categories Horizontal Filter Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trending Categories',
                    style: AppTextStyles.headlineSm.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Tap to filter',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              categoriesAsync.when(
                data: (categories) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryPill(
                          title: 'All',
                          icon: Icons.stars,
                          isSelected: _selectedCategoryId == null,
                          onTap: () {
                            setState(() => _selectedCategoryId = null);
                            ref.read(shopCategoryFilterProvider.notifier).state = null;
                          },
                        ),
                        ...categories.map((cat) {
                          final isSelected = _selectedCategoryId == cat.id;
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _buildCategoryPill(
                              title: cat.name,
                              icon: _getCategoryIcon(cat.iconKey),
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  _selectedCategoryId = isSelected ? null : cat.id;
                                });
                                ref.read(shopCategoryFilterProvider.notifier).state =
                                    _selectedCategoryId;
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 24),

              // 5. Quiz Book Store Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Quiz Book Store',
                        style: AppTextStyles.headlineSm.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.go('/shop'),
                    child: Row(
                      children: [
                        Text(
                          'View All',
                          style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Carousel of Books
              booksAsync.when(
                data: (books) {
                  if (books.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: Text(
                        'No books found in this category.',
                        style: AppTextStyles.bodyMd,
                      ),
                    );
                  }
                  return SizedBox(
                    height: 358,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: books.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final book = books[index];
                        return BookProductCard(
                          book: book,
                          compact: true,
                          onAddToCart: () async {
                            final userId = ref.read(currentUserIdProvider);
                            if (userId != null) {
                              await ref
                                  .read(supabaseServiceProvider)
                                  .addToCart(userId: userId, bookId: book.id);
                              ref
                                  .read(cartRefreshTriggerProvider.notifier)
                                  .state++;
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${book.title} added to cart!'),
                                    duration: const Duration(seconds: 2),
                                    action: SnackBarAction(
                                      label: 'View Cart',
                                      onPressed: () => context.push('/cart'),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          onBuyNow: () {
                            context.push('/book/${book.id}');
                          },
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (err, _) => Text(
                  'Error loading books: $err',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              const SizedBox(height: 24),

              // 6. Quick Stats Community Proof Banner
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.outlineVariant.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_stories,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '1,200+',
                              style: AppTextStyles.headlineSm.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Books Sold',
                              style: AppTextStyles.bodySm.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: AppColors.outlineVariant.withOpacity(0.4),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.secondaryFixed.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.group,
                            color: AppColors.secondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '50k+',
                              style: AppTextStyles.headlineSm.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Active Quizzers',
                              style: AppTextStyles.bodySm.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPill({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.onSurface
              : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.15),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.surface : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: AppTextStyles.labelMd.copyWith(
                color: isSelected ? AppColors.surface : AppColors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
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
