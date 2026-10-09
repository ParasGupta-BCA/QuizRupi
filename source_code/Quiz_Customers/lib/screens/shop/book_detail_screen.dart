import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/coin_badge.dart';
import '../../core/widgets/app_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/cart_provider.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  final String bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  int _quantity = 1;
  final TextEditingController _pincodeController = TextEditingController(text: '110001');
  String? _pincodeStatus;
  bool _isPincodeValid = true;

  @override
  void initState() {
    super.initState();
    _checkPincode('110001');
  }

  @override
  void dispose() {
    _pincodeController.dispose();
    super.dispose();
  }

  void _checkPincode(String pin) {
    if (pin.trim().length == 6 && int.tryParse(pin.trim()) != null) {
      final estDate = DateTime.now().add(const Duration(days: 4));
      final dateStr = DateFormat('EEEE, d MMM').format(estDate);
      setState(() {
        _isPincodeValid = true;
        _pincodeStatus = 'Available for $pin! Estimated delivery by $dateStr';
      });
    } else {
      setState(() {
        _isPincodeValid = false;
        _pincodeStatus = 'Please enter a valid 6-digit Indian PIN code';
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
      await service.addToCart(
        userId: userId,
        bookId: bookId,
        quantity: _quantity,
      );
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
                    'Added $_quantity x "$title" to Cart',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurface),
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'View Cart',
              textColor: AppColors.secondary,
              onPressed: () => context.push('/cart'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.crimsonRed,
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
      await service.addToCart(
        userId: userId,
        bookId: bookId,
        quantity: _quantity,
      );
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

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(bookDetailProvider(widget.bookId));
    final profileAsync = ref.watch(userProfileProvider);
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest.withOpacity(0.95),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Book Details',
          style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CoinBadge(
              coins: profileAsync.value?.coinsBalance ?? 0,
              onTap: () => context.push('/wallet'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => context.go('/profile'),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.outlineVariant.withOpacity(0.4),
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
                            size: 18,
                          ),
                        )
                      : const Icon(Icons.person, color: AppColors.outline, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
      body: bookAsync.when(
        data: (book) {
          if (book == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 48, color: AppColors.outline),
                  const SizedBox(height: 12),
                  Text('Book not found', style: AppTextStyles.headlineSm),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Back to Shop'),
                  ),
                ],
              ),
            );
          }

          final totalPrice = (book.price * _quantity).toInt();

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sub-Header Quick Action Strip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: AppColors.surfaceContainerLowest,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primaryContainer.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.verified,
                                  color: AppColors.primaryContainer,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Official QuizRupi Edition',
                                  style: AppTextStyles.labelSm.copyWith(
                                    color: AppColors.primaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.share, size: 20, color: AppColors.onSurface),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Sharing book details link...')),
                                  );
                                },
                              ),
                              GestureDetector(
                                onTap: () => context.push('/cart'),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainer,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.shopping_bag_outlined,
                                        size: 18,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                    if (cartCount > 0)
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          decoration: const BoxDecoration(
                                            color: AppColors.primaryContainer,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '$cartCount',
                                              style: AppTextStyles.labelSm.copyWith(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Hero Book Showcase
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.surfaceContainerLowest,
                            AppColors.surface,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Tags Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.workspace_premium, size: 14, color: AppColors.onSecondaryContainer),
                                    const SizedBox(width: 4),
                                    Text(
                                      book.tag ?? 'Bestseller Level 01',
                                      style: AppTextStyles.labelSm.copyWith(
                                        color: AppColors.onSecondaryContainer,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.psychology, size: 14, color: AppColors.onSurfaceVariant),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${book.pageCount} Pages • Curated MCQs',
                                      style: AppTextStyles.labelSm.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Curved Backdrop Box for Product Image (Adaptive White Background)
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 280, maxHeight: 330),
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: AppColors.primaryContainer.withOpacity(0.08),
                                  blurRadius: 30,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Center(
                                child: book.coverImageUrl != null && book.coverImageUrl!.isNotEmpty
                                    ? AppNetworkImage(
                                        imageUrl: book.coverImageUrl!,
                                        height: 280,
                                        fit: BoxFit.contain,
                                        fallbackTitle: book.title,
                                      )
                                    : const Icon(
                                        Icons.menu_book,
                                        size: 64,
                                        color: AppColors.outline,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Coin incentive banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryFixed.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.secondary.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.local_fire_department,
                                  color: AppColors.secondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Order now to unlock +50 Quiz Points & 3x streak boost!',
                                    style: AppTextStyles.labelSm.copyWith(
                                      color: AppColors.secondaryFixedDim,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.secondary,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Product Info Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.outlineVariant.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              style: AppTextStyles.headlineSm.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Rating and Stock
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star, color: AppColors.secondary, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        book.ratingAvg.toStringAsFixed(1),
                                        style: AppTextStyles.labelMd.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${book.ratingCount} student reviews)',
                                  style: AppTextStyles.bodySm.copyWith(color: AppColors.outline),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.emeraldGreen.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'In Stock',
                                    style: AppTextStyles.labelSm.copyWith(
                                      color: AppColors.emeraldGreen,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Price Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '₹${book.price.toInt()}',
                                  style: AppTextStyles.headlineXl.copyWith(
                                    color: AppColors.primaryContainer,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                if (book.mrp > book.price) ...[
                                  Text(
                                    '₹${book.mrp.toInt()}',
                                    style: AppTextStyles.headlineSm.copyWith(
                                      color: AppColors.outline,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.emeraldGreen,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${book.discountPercent}% OFF - Save ₹${(book.mrp - book.price).toInt()}',
                                      style: AppTextStyles.labelSm.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Inclusive of all taxes and shipping insurance.',
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Key Highlights Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.outlineVariant.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_stories, color: AppColors.primaryContainer, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Key Highlights',
                                  style: AppTextStyles.headlineSm.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (book.bookHighlights.isNotEmpty)
                              ...book.bookHighlights.map(
                                (hl) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 18,
                                        height: 18,
                                        margin: const EdgeInsets.only(top: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.emeraldGreen.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check, color: AppColors.emeraldGreen, size: 12),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          hl,
                                          style: AppTextStyles.bodyMd.copyWith(
                                            color: AppColors.onSurface,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else ...[
                              _buildDefaultHighlight('Covers Indian GK, World, Science, History, Tech & Sports'),
                              _buildDefaultHighlight('Detailed explanatory answers for every question'),
                              _buildDefaultHighlight('Premium glossy 300 GSM cover & high quality map print'),
                              _buildDefaultHighlight('Free doorstep delivery in 3-5 business days across India'),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Delivery Availability Checker
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.outlineVariant.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.local_shipping, color: AppColors.primaryContainer, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Delivery Availability',
                                  style: AppTextStyles.headlineSm.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 42,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.pin_drop, size: 18, color: AppColors.outline),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: _pincodeController,
                                            keyboardType: TextInputType.number,
                                            style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurface),
                                            decoration: const InputDecoration(
                                              hintText: 'Enter 6-digit PIN code',
                                              border: InputBorder.none,
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _checkPincode(_pincodeController.text),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.surfaceContainerHighest,
                                    foregroundColor: AppColors.onSurface,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Check'),
                                ),
                              ],
                            ),
                            if (_pincodeStatus != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _isPincodeValid ? Icons.verified : Icons.error_outline,
                                      size: 16,
                                      color: _isPincodeValid ? AppColors.emeraldGreen : AppColors.crimsonRed,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _pincodeStatus!,
                                        style: AppTextStyles.bodySm.copyWith(
                                          color: _isPincodeValid ? AppColors.onSurface : AppColors.crimsonRed,
                                          fontWeight: _isPincodeValid ? FontWeight.w600 : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Guarantee Mini Bento Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.outlineVariant.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.sync, color: AppColors.primaryContainer, size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('7-Day Return', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w700)),
                                        Text('No questions asked', style: AppTextStyles.bodySm.copyWith(fontSize: 10, color: AppColors.outline)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.outlineVariant.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.security, color: AppColors.secondary, size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('100% Genuine', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w700)),
                                        Text('Printed directly', style: AppTextStyles.bodySm.copyWith(fontSize: 10, color: AppColors.outline)),
                                      ],
                                    ),
                                  ),
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

              // Sticky Bottom Action Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest.withOpacity(0.97),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.outlineVariant.withOpacity(0.2),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Quantity Stepper
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (_quantity > 1) {
                                  setState(() => _quantity--);
                                }
                              },
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.remove, size: 14, color: AppColors.onSurface),
                              ),
                            ),
                            SizedBox(
                              width: 32,
                              child: Center(
                                child: Text(
                                  '$_quantity',
                                  style: AppTextStyles.labelLg.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (_quantity < 10) {
                                  setState(() => _quantity++);
                                }
                              },
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.add, size: 14, color: AppColors.onSurface),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Add to Cart
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: () => _handleAddToCart(book.id, book.title),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.outlineVariant.withOpacity(0.4)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              foregroundColor: AppColors.onSurface,
                            ),
                            icon: const Icon(Icons.add_shopping_cart, size: 16),
                            label: const Text('Add to Cart'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Buy Now
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () => _handleBuyNow(book.id, book.title),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondaryContainer,
                              foregroundColor: AppColors.onSecondaryFixed,
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.bolt, size: 16),
                            label: Text(
                              'Buy (₹$totalPrice)',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryContainer),
        ),
        error: (err, _) => Center(
          child: Text('Error loading book: $err', style: const TextStyle(color: AppColors.crimsonRed)),
        ),
      ),
    );
  }

  Widget _buildDefaultHighlight(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: AppColors.emeraldGreen.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: AppColors.emeraldGreen, size: 12),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurface, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
