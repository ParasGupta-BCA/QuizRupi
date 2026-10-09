import 'package:flutter/material.dart';

class AppColors {
  // Primary Canvas & Surfaces (Deep Midnight Violet from Super Quiz logo background)
  static const Color surface = Color(0xFF0F0826);
  static const Color surfaceDim = Color(0xFF0F0826);
  static const Color surfaceBright = Color(0xFF2E1A57);
  static const Color surfaceContainerLowest = Color(0xFF090417);
  static const Color surfaceContainerLow = Color(0xFF160D33);
  static const Color surfaceContainer = Color(0xFF1E1242);
  static const Color surfaceContainerHigh = Color(0xFF281954);
  static const Color surfaceContainerHighest = Color(0xFF332168);

  // Text & On Surface (Soft crisp lavender-white & purple tints)
  static const Color onSurface = Color(0xFFF5F3FF);
  static const Color onSurfaceVariant = Color(0xFFB8ACD6);
  static const Color outline = Color(0xFF8372A6);
  static const Color outlineVariant = Color(0xFF463768);

  // Primary Action (Electric Purple / Glowing Violet from Super Quiz book & logo)
  static const Color primary = Color(0xFFC4B5FD); // Soft glowing lavender
  static const Color onPrimary = Color(0xFF2E086A);
  static const Color primaryContainer = Color(0xFF7C3AED); // Vivid Electric Purple CTA
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);
  static const Color primaryFixed = Color(0xFFDDD6FE);

  // Secondary / Points / Streaks (Vibrant Golden Amber from the Question Mark thought bubble)
  static const Color secondary = Color(0xFFFBBF24); // Golden Amber
  static const Color onSecondary = Color(0xFF451A03);
  static const Color secondaryContainer = Color(0xFFD97706);
  static const Color onSecondaryContainer = Color(0xFFFFFBEB);
  static const Color secondaryFixed = Color(0xFFFDE68A);
  static const Color secondaryFixedDim = Color(0xFFFBBF24);
  static const Color onSecondaryFixed = Color(0xFF291000);
  static const Color amberGold = Color(0xFFF59E0B);

  // Tertiary / Success / Validated Options (Fresh Emerald Green)
  static const Color tertiary = Color(0xFF34D399);
  static const Color onTertiary = Color(0xFF003824);
  static const Color tertiaryContainer = Color(0xFF059669);
  static const Color onTertiaryContainer = Color(0xFFD1FAE5);
  static const Color tertiaryFixed = Color(0xFF6EE7B7);
  static const Color emeraldGreen = Color(0xFF10B981);

  // Error / Mistakes
  static const Color error = Color(0xFFF87171);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFFB91C1C);
  static const Color onErrorContainer = Color(0xFFFEE2E2);
  static const Color crimsonRed = Color(0xFFEF4444);

  // Gradients
  static const LinearGradient heroPlayGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x997C3AED), // Electric Purple
      Color(0x806D28D9), // Vivid Violet
      Color(0x734C1D95), // Deep Royal Purple
      Color(0x599333EA), // Magenta Purple
    ],
  );

  static const LinearGradient coinBadgeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x2EFFFFFF),
      Color(0x0AFFFFFF),
    ],
  );

  static const LinearGradient goldButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFDE047),
      Color(0xFFF59E0B),
      Color(0xFFD97706),
    ],
  );

  static const LinearGradient superQuizGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF8B5CF6),
      Color(0xFF7C3AED),
      Color(0xFF6D28D9),
    ],
  );
}
