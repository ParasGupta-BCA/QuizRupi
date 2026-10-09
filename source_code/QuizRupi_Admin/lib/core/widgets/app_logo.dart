import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable QuizRupi App Logo Widget
/// Renders the official QuizRupi lightbulb + rupee logo image
/// with fallback to vector design if needed.
class AppLogo extends StatelessWidget {
  final double size;
  final double borderRadius;
  final bool showAdminBadge;
  final bool showShadow;

  const AppLogo({
    super.key,
    this.size = 48,
    this.borderRadius = 14,
    this.showAdminBadge = false,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: showShadow
                ? [
                    BoxShadow(
                      color: const Color(0xFF2979FF).withValues(alpha: 0.35),
                      blurRadius: size * 0.25,
                      offset: Offset(0, size * 0.08),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.asset(
              'assets/images/quizrupi_logo.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // High-fidelity fallback matching QuizRupi Customer app
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2),
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.lightbulb,
                          size: size * 0.55,
                          color: const Color(0xFFFFD54F),
                        ),
                        Positioned(
                          right: size * 0.1,
                          bottom: size * 0.1,
                          child: Container(
                            padding: EdgeInsets.all(size * 0.04),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFA000),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '₹',
                              style: TextStyle(
                                fontSize: size * 0.22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
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
        ),
        if (showAdminBadge)
          Positioned(
            right: -6,
            bottom: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
