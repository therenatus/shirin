import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary - Pink/Raspberry from logo
  static const Color primary = Color(0xFFE91E63);
  static const Color primaryDark = Color(0xFFC2185B);
  static const Color primaryLight = Color(0xFFF48FB1);
  static const Color primarySoft = Color(0xFFFCE4EC);

  // Secondary - Purple accent
  static const Color secondary = Color(0xFF9C27B0);
  static const Color secondaryLight = Color(0xFFCE93D8);

  // Purple theme colors for header
  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleDark = Color(0xFF7C3AED);
  static const Color purpleLight = Color(0xFFA78BFA);
  static const Color purpleSoft = Color(0xFFEDE9FE);

  // Background
  static const Color background = Color(0xFFFFF8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color secondaryBackground = Color(0xFFFCE4EC);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Accent
  static const Color accent = Color(0xFFE91E63);

  // Utility
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // Liquid Glass / Glassmorphism
  static final Color glassFill = Colors.white.withValues(alpha: 0.75);
  static final Color glassFillLight = Colors.white.withValues(alpha: 0.50);
  static final Color glassBorder = Colors.white.withValues(alpha: 0.60);
  static final Color glassBorderLight = Colors.white.withValues(alpha: 0.30);
  static final Color glassShadow = primary.withValues(alpha: 0.12);
  static final Color glassInnerGlow = Colors.white.withValues(alpha: 0.70);

  // Gradient Background - Purple theme
  static const Color gradientStart = Color(0xFFE8D5F0);
  static const Color gradientMiddle = Color(0xFFD8C5E8);
  static const Color gradientEnd = Color(0xFFC4B5DC);

  // Category Card Colors - matching design
  static const Color cardTeal = Color(0xFFCCE5E0);
  static const Color cardPink = Color(0xFFF5D5E0);
  static const Color cardTurquoise = Color(0xFFD0E8E8);
  static const Color cardBlue = Color(0xFFD5E5F5);
  static const Color cardOrange = Color(0xFFFFF0D5);
  static const Color cardYellow = Color(0xFFFFF5CC);
  static const Color cardLavender = Color(0xFFE8E0F5);

  // Decorative Orbs for background
  static final Color orbPink = primary.withValues(alpha: 0.20);
  static final Color orbPurple = secondary.withValues(alpha: 0.15);
  static final Color orbLavender = const Color(0xFFCE93D8).withValues(alpha: 0.20);
  static final Color orbPeach = const Color(0xFFFFAB91).withValues(alpha: 0.15);

  // Category Card Colors - matching second image style
  static const List<Color> categoryColors = [
    Color(0xFFFCE4EC), // Light Pink
    Color(0xFFF3E5F5), // Light Purple
    Color(0xFFE3F2FD), // Light Blue
    Color(0xFFFFF3E0), // Light Orange
    Color(0xFFE8F5E9), // Light Green
    Color(0xFFFFF8E1), // Light Yellow
    Color(0xFFEDE7F6), // Light Violet
    Color(0xFFFFEBEE), // Light Rose
  ];

  static const List<Color> categoryGradients = [
    Color(0xFFF8BBD9), // Pink gradient end
    Color(0xFFE1BEE7), // Purple gradient end
    Color(0xFFBBDEFB), // Blue gradient end
    Color(0xFFFFE0B2), // Orange gradient end
    Color(0xFFC8E6C9), // Green gradient end
    Color(0xFFFFECB3), // Yellow gradient end
    Color(0xFFD1C4E9), // Violet gradient end
    Color(0xFFFFCDD2), // Rose gradient end
  ];

  static const List<Color> categoryIconColors = [
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFF1976D2), // Blue
    Color(0xFFFF9800), // Orange
    Color(0xFF4CAF50), // Green
    Color(0xFFFFC107), // Yellow
    Color(0xFF673AB7), // Violet
    Color(0xFFF44336), // Rose
  ];

  // Bonus Card Gradient
  static const List<Color> bonusCardGradient = [
    Color(0xFFE91E63),
    Color(0xFFD81B60),
    Color(0xFFC2185B),
  ];

  // Navigation Bar
  static const Color navBarBackground = Color(0xFFE8D5E7);
  static final Color navBarSelected = primary;
  static final Color navBarUnselected = const Color(0xFF9E9E9E);
}
