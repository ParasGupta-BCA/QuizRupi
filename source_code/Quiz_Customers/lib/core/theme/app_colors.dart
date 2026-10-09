import 'package:flutter/material.dart';

class AppColors {
  // Primary Canvas & Surfaces
  static const Color surface = Color(0xFF0B1326);
  static const Color surfaceDim = Color(0xFF0B1326);
  static const Color surfaceBright = Color(0xFF31394D);
  static const Color surfaceContainerLowest = Color(0xFF060E20);
  static const Color surfaceContainerLow = Color(0xFF131B2E);
  static const Color surfaceContainer = Color(0xFF171F33);
  static const Color surfaceContainerHigh = Color(0xFF222A3D);
  static const Color surfaceContainerHighest = Color(0xFF2D3449);

  // Text & On Surface
  static const Color onSurface = Color(0xFFDAE2FD);
  static const Color onSurfaceVariant = Color(0xFF94A3B8);
  static const Color outline = Color(0xFF8D90A0);
  static const Color outlineVariant = Color(0xFF434655);

  // Primary Action (Royal Blue)
  static const Color primary = Color(0xFFB4C5FF);
  static const Color onPrimary = Color(0xFF002A78);
  static const Color primaryContainer = Color(0xFF2563EB); // Royal Blue CTA
  static const Color onPrimaryContainer = Color(0xFFEEEFFF);
  static const Color primaryFixed = Color(0xFFDBE1FF);

  // Secondary / Points / Streaks (Educational Amber Gold)
  static const Color secondary = Color(0xFFFFB95F);
  static const Color onSecondary = Color(0xFF472A00);
  static const Color secondaryContainer = Color(0xFFEE9800);
  static const Color onSecondaryContainer = Color(0xFF5B3800);
  static const Color secondaryFixed = Color(0xFFFFDDB8);
  static const Color secondaryFixedDim = Color(0xFFFFB95F);
  static const Color onSecondaryFixed = Color(0xFF2A1700);
  static const Color amberGold = Color(0xFFF59E0B);

  // Tertiary / Success / Validated Options (Fresh Emerald Green)
  static const Color tertiary = Color(0xFF4EDEA3);
  static const Color onTertiary = Color(0xFF003824);
  static const Color tertiaryContainer = Color(0xFF007D55);
  static const Color onTertiaryContainer = Color(0xFFBDFFDB);
  static const Color tertiaryFixed = Color(0xFF6FFBBE);
  static const Color emeraldGreen = Color(0xFF10B981);

  // Error / Mistakes
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);
  static const Color crimsonRed = Color(0xFFEF4444);

  // Gradients
  static const LinearGradient heroPlayGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x613B82F6),
      Color(0x382563EB),
      Color(0x2E9333EA),
      Color(0x4006B6D4),
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
      Color(0xFFFFC061),
      Color(0xFFEE9800),
      Color(0xFFCF7B00),
    ],
  );

  static const LinearGradient superQuizGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x6B2563EB),
      Color(0x471E40AF),
      Color(0x527C3AED),
    ],
  );
}
