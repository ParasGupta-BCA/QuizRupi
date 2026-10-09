import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/coin_badge.dart';
import '../../core/widgets/book_product_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/quiz_provider.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categoryFilters = [
    'All Books',
    'General Knowledge',
    'Current Affairs',
    'Maths & Logic',
    'History',
    'Science',
  ];

  String _selectedCategory = 'All Books';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });

    if (category == 'All Books') {
      ref.read(shopCategoryFilterProvider.notifier).state = null;
    } else {
      // Find category id from quiz categories provider if possible, or filter by title match
      final categoriesAsync = ref.read(quizCategoriesProvider);
      categoriesAsync.whenData((categories) {
        final match = categories.where((c) =>
            c.name.toLowerCase().contains(category.toLowerCase()) ||
            category.toLowerCase().contains(c.name.toLowerCase()));
        if (match.isNotEmpty) {
          ref.read(shopCategoryFilterProvider.notifier).state = match.first.id;
        } else {
          ref.read(shopCategoryFilterProvider.notifier).state = null;
        }
      });
    }
  }

  Future<void> _handleAddToCart(String bookId, String title) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      context.push('/login');
      return;
    }

    try {
      final service = ref.read(supabaseServiceProvider);
      await service.addToCart(userId: userId, bookId: bookId);
      ref.read(cartRefreshTriggerProvider.notifier).state++;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceContainerHigh,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.emeraldGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Added "$title" to Cart',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'View Cart',
              textColor: AppColors.secondary,
              onPressed: () => context.push('/cart'),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.crimsonRed,
            behavior: SnackBarBehavior.floating,
            content: Text('Failed to add to cart: $e'),
          ),
        );
      }
    }
  }

  Future<void> _handleBuyNow(String bookId, String title) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      context.push('/login');
      return;
    }

    try {
      final service = ref.read(supabaseServiceProvider);
      await service.addToCart(userId: userId, bookId: bookId);
      ref.read(cartRefreshTriggerProvider.notifier).state++;
      if (mounted) {
        context.push('/checkout');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.crimsonRed,
            content: Text('Error: $e'),
          ),
        );
      }
    }
  }

  Future<void> _claimComboDeal() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      context.push('/login');
      return;
    }

    // Add first 3 books to cart
    final booksAsync = ref.read(booksProvider);
    booksAsync.whenData((books) async {
      if (books.length >= 3) {
        final service = ref.read(supabaseServiceProvider);
        for (int i = 0; i < 3; i++) {
          await service.addToCart(userId: userId, bookId: books[i].id);
        }
        ref.read(cartRefreshTriggerProvider.notifier).state++;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.surfaceContainerHigh,
              behavior: SnackBarBehavior.floating,
              content: const Row(
                children: [
                  Icon(Icons.bolt, color: AppColors.secondary, size: 20),
                  SizedBox(width: 8),
                  Text('3 Books Combo added! Discount applied.'),
                ],
              ),
              action: SnackBarAction(
                label: 'Go to Cart',
                textColor: AppColors.secondary,
                onPressed: () => context.push('/cart'),
              ),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final booksAsync = ref.watch(booksProvider);
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryContainer,
          backgroundColor: AppColors.surfaceContainer,
          onRefresh: () async {
            ref.invalidate(booksProvider);
            ref.read(cartRefreshTriggerProvider.notifier).state++;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Header App Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo & Shop Tag
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryContainer.withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.lightbulb,
                              color: AppColors.secondary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                'QuizRupi',
                                style: AppTextStyles.headlineSm.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'SHOP',
                                  style: AppTextStyles.labelSm.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryContainer,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Coins & Profile
                      Row(
                        children: [
                          CoinBadge(
                            coins: profileAsync.value?.coinsBalance ?? 0,
                            onTap: () => context.push('/wallet'),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => context.go('/profile'),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.outlineVariant.withOpacity(0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: ClipOval(
                                child: profileAsync.value?.avatarUrl != null &&
                                        profileAsync.value!.avatarUrl!.isNotEmpty
                                    ? Image.network(
                                        profileAsync.value!.avatarUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(
                                          Icons.person,
                                          color: AppColors.outline,
                                          size: 20,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person,
                                        color: AppColors.outline,
                                        size: 20,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar & Cart Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      // Search Input
                      Expanded(
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.outlineVariant.withOpacity(0.2),
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              ref.read(shopSearchQueryProvider.notifier).state = val;
                            },
                            style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurface),
                            decoration: InputDecoration(
                              hintText: 'Search 1000+ MCQ quiz books...',
                              hintStyle: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.outline,
                                fontSize: 13,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColors.outline,
                                size: 20,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        ref.read(shopSearchQueryProvider.notifier).state = '';
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Cart Icon Button with Counter Badge
                      GestureDetector(
                        onTap: () => context.push('/cart'),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.outlineVariant.withOpacity(0.2),
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                Icons.shopping_bag_outlined,
                                color: AppColors.onSurface,
                                size: 22,
                              ),
                              if (cartCount > 0)
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryContainer,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.secondaryContainer.withOpacity(0.5),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$cartCount',
                                        style: AppTextStyles.labelSm.copyWith(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.onSecondaryFixed,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Horizontal Category Filters
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 12),
                  child: SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categoryFilters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = _categoryFilters[index];
                        final isSelected = cat == _selectedCategory;

                        return GestureDetector(
                          onTap: () => _onCategorySelected(cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryContainer
                                  : AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryContainer
                                    : AppColors.outlineVariant.withOpacity(0.2),
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primaryContainer.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                cat,
                                style: AppTextStyles.labelMd.copyWith(
                                  color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Mega Combo Deal Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFB95F), Color(0xFFEE9800)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEE9800).withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Background decorative icon
                        Positioned(
                          right: -10,
                          bottom: -15,
                          child: Opacity(
                            opacity: 0.15,
                            child: Icon(
                              Icons.menu_book,
                              size: 110,
                              color: AppColors.onSecondaryFixed,
                            ),
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top tags
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerLowest.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.bolt, color: AppColors.secondary, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          'MEGA COMBO DEAL',
                                          style: AppTextStyles.labelSm.copyWith(
                                            color: AppColors.secondary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.local_shipping,
                                        size: 14,
                                        color: AppColors.onSecondaryFixed.withOpacity(0.9),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'FREE DELIVERY',
                                        style: AppTextStyles.labelSm.copyWith(
                                          color: AppColors.onSecondaryFixed.withOpacity(0.9),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Title & Subtitle
                              Text(
                                'Get Any 3 Books at ₹499',
                                style: AppTextStyles.headlineSm.copyWith(
                                  color: AppColors.onSecondaryFixed,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Physical books delivered to your doorstep + 150 Quiz Points',
                                style: AppTextStyles.bodySm.copyWith(
                                  color: AppColors.onSecondaryFixed.withOpacity(0.85),
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Claim CTA
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: _claimComboDeal,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.surfaceContainerLowest,
                                    foregroundColor: AppColors.secondary,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Claim Now',
                                        style: AppTextStyles.labelMd.copyWith(
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.chevron_right, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Title Section: "Recommended for You"
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Recommended for You',
                            style: AppTextStyles.headlineSm.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          booksAsync.maybeWhen(
                            data: (books) => Text(
                              '(${books.length} titles)',
                              style: AppTextStyles.bodySm.copyWith(color: AppColors.outline),
                            ),
                            orElse: () => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.tune, size: 16, color: AppColors.primaryContainer),
                          const SizedBox(width: 4),
                          Text(
                            'Filter',
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.primaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Books Grid
              booksAsync.when(
                data: (books) {
                  if (books.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.menu_book, size: 48, color: AppColors.outline),
                              const SizedBox(height: 12),
                              Text(
                                'No books found',
                                style: AppTextStyles.headlineSm.copyWith(color: AppColors.onSurface),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Try changing your search or category filter',
                                style: AppTextStyles.bodySm.copyWith(color: AppColors.outline),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.48,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final book = books[index];
                          return BookProductCard(
                            book: book,
                            onAddToCart: () => _handleAddToCart(book.id, book.title),
                            onBuyNow: () => _handleBuyNow(book.id, book.title),
                          );
                        },
                        childCount: books.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(60),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primaryContainer),
                    ),
                  ),
                ),
                error: (err, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Center(
                      child: Text(
                        'Failed to load books: $err',
                        style: const TextStyle(color: AppColors.crimsonRed),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
