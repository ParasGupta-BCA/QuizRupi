import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../data/models/book_model.dart';
import 'app_network_image.dart';

class BookProductCard extends StatelessWidget {
  final BookModel book;
  final VoidCallback onAddToCart;
  final VoidCallback? onBuyNow;
  final bool compact;

  const BookProductCard({
    super.key,
    required this.book,
    required this.onAddToCart,
    this.onBuyNow,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/book/${book.id}'),
      child: Container(
        width: compact ? 170 : null,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.outlineVariant.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cover Image expanding to available card height
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: book.coverImageUrl != null && book.coverImageUrl!.isNotEmpty
                        ? AppNetworkImage(
                            imageUrl: book.coverImageUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            fallbackTitle: book.title,
                          )
                        : Container(
                            color: AppColors.surfaceContainerHigh,
                            child: const Icon(Icons.menu_book, color: AppColors.outline),
                          ),
                  ),
                  // Tag / Discount Badge
                  if (book.tag != null || book.discountPercent > 0)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: book.isBestseller
                              ? AppColors.secondaryContainer
                              : AppColors.crimsonRed,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          book.tag ?? '${book.discountPercent}% OFF',
                          style: AppTextStyles.labelSm.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  // Quick Add Floating Button
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: onAddToCart,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryContainer.withOpacity(0.5),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Rating
            Row(
              children: [
                const Icon(Icons.star, size: 13, color: AppColors.secondary),
                const SizedBox(width: 3),
                Text(
                  book.ratingAvg.toStringAsFixed(1),
                  style: AppTextStyles.labelSm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${book.ratingCount})',
                  style: AppTextStyles.bodySm.copyWith(
                    fontSize: 10,
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),

            // Title (2 lines max)
            SizedBox(
              height: 30,
              child: Text(
                book.title,
                style: AppTextStyles.labelLg.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                  height: 1.15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),

            // Price Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '₹${book.price.toInt()}',
                  style: AppTextStyles.priceDisplay.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(width: 6),
                if (book.mrp > book.price)
                  Text(
                    '₹${book.mrp.toInt()}',
                    style: AppTextStyles.bodySm.copyWith(
                      fontSize: 11,
                      decoration: TextDecoration.lineThrough,
                      color: AppColors.outline,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 32,
              child: ElevatedButton(
                onPressed: onBuyNow ?? onAddToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      onBuyNow != null ? Icons.shopping_bag : Icons.shopping_cart,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      onBuyNow != null ? 'Buy Now' : 'Add to Cart',
                      style: AppTextStyles.labelSm.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
