import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable Super Quiz App Logo Widget
/// Renders the official Super Quiz 3D logo asset with smooth squircle styling,
/// ambient glow, and vector fallback.
class AppLogo extends StatelessWidget {
  final double size;
  final double? borderRadius;
  final bool showShadow;

  const AppLogo({
    super.key,
    this.size = 48,
    this.borderRadius,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? (size * 0.22);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(effectiveRadius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.primaryContainer.withValues(alpha: 0.4),
                  blurRadius: size * 0.25,
                  offset: Offset(0, size * 0.08),
                ),
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  blurRadius: size * 0.15,
                  offset: Offset.zero,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // High-fidelity vector fallback matching Super Quiz 3D theme
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF3B1A82),
                    Color(0xFF1D0B40),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(effectiveRadius),
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: size * 0.52,
                      color: Colors.white,
                    ),
                    Positioned(
                      top: size * 0.08,
                      child: Container(
                        padding: EdgeInsets.all(size * 0.03),
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '?',
                          style: TextStyle(
                            fontSize: size * 0.22,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
