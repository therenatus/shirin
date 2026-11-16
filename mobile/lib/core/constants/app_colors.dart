import 'package:flutter/material.dart';

/// Design tokens for the Shirin app.
///
/// Palette: one brand accent (raspberry from the logo), rose-tinted neutrals,
/// and pastel surfaces for categories. No second accent hue competes with it.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Brand accent - raspberry from the Shirin logo
  // ---------------------------------------------------------------------------
  static const Color primary = Color(0xFFD81B60);
  static const Color primaryDark = Color(0xFFB0154D);
  static const Color primaryLight = Color(0xFFFF5C8D);
  static const Color primarySoft = Color(0xFFFDE4EC);
  static const Color primaryTint = Color(0xFFFFF0F4);

  /// Deep berry for strong surfaces (loyalty card, dark banners).
  static const Color secondary = Color(0xFF8E1546);
  static const Color secondaryLight = Color(0xFFF48FB1);

  // Legacy names kept for compatibility. They now point at the brand accent so
  // every screen reads as one system. Prefer `primary*` in new code.
  static const Color purple = primary;
  static const Color purpleDark = primaryDark;
  static const Color purpleLight = primaryLight;
  static const Color purpleSoft = primarySoft;

  // ---------------------------------------------------------------------------
  // Surfaces
  // ---------------------------------------------------------------------------
  static const Color background = Color(0xFFFAF6F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF3ECEF);
  /// Tile behind product photos (Drinkit-style isolated object on a pastel).
  static const Color productTile = Color(0xFFF6F0F2);
  static const Color secondaryBackground = primarySoft;

  // ---------------------------------------------------------------------------
  // Text - neutrals carry a slight rose bias so greys do not look borrowed
  // ---------------------------------------------------------------------------
  static const Color textPrimary = Color(0xFF2A1620);
  static const Color textSecondary = Color(0xFF7A6470);
  static const Color textLight = Color(0xFFA9969F);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color accent = primary;

  // ---------------------------------------------------------------------------
  // Semantic - separate from the accent hue
  // ---------------------------------------------------------------------------
  static const Color error = Color(0xFFD93A3A);
  static const Color success = Color(0xFF2E9E6B);
  static const Color warning = Color(0xFFE59A1F);
  static const Color divider = Color(0xFFEDE3E7);
  static const Color shimmerBase = Color(0xFFF3E2E8);
  static const Color shimmerHighlight = Color(0xFFFFF8FA);

  // ---------------------------------------------------------------------------
  // Glass surfaces
  // ---------------------------------------------------------------------------
  static final Color glassFill = Colors.white.withValues(alpha: 0.78);
  static final Color glassFillLight = Colors.white.withValues(alpha: 0.55);
  static final Color glassBorder = Colors.white.withValues(alpha: 0.65);
  static final Color glassBorderLight = Colors.white.withValues(alpha: 0.35);
  static final Color glassShadow = primary.withValues(alpha: 0.10);
  static final Color glassInnerGlow = Colors.white.withValues(alpha: 0.70);

  // Liquid background blobs (behind glass). Alpha is baked in.
  static const Color liquidRose = Color(0x73FFB3C9);
  static const Color liquidPeach = Color(0x59FFC9A8);
  static const Color liquidLilac = Color(0x4DD9B8F0);
  static const Color liquidRaspberry = Color(0x40FF5C8D);

  // Soft page gradient (top to bottom)
  static const Color gradientStart = Color(0xFFFFE4EC);
  static const Color gradientMiddle = Color(0xFFFFEFF3);
  static const Color gradientEnd = Color(0xFFFFF5F7);

  // Pastel card fills
  static const Color cardTeal = Color(0xFFD6ECE6);
  static const Color cardPink = Color(0xFFFBDCE6);
  static const Color cardTurquoise = Color(0xFFD5EBEC);
  static const Color cardBlue = Color(0xFFDCE6F6);
  static const Color cardOrange = Color(0xFFFFEBD6);
  static const Color cardYellow = Color(0xFFFFF4CF);
  static const Color cardLavender = Color(0xFFEDE3F4);

  // Decorative orbs for backgrounds
  static final Color orbPink = primary.withValues(alpha: 0.16);
  static final Color orbPurple = secondary.withValues(alpha: 0.10);
  static final Color orbLavender = primaryLight.withValues(alpha: 0.14);
  static final Color orbPeach = const Color(0xFFFFB08A).withValues(alpha: 0.16);

  // Category tiles: pastel fill, deeper gradient end, saturated icon
  static const List<Color> categoryColors = [
    Color(0xFFFDE4EC), // rose
    Color(0xFFFFEBD6), // apricot
    Color(0xFFF3E6D3), // caramel
    Color(0xFFE3F2E8), // pistachio
    Color(0xFFDFEAF8), // blueberry
    Color(0xFFFFF4CF), // vanilla
    Color(0xFFEDE3F4), // lavender
    Color(0xFFFBE0DC), // strawberry
  ];

  static const List<Color> categoryGradients = [
    Color(0xFFF9C4D4),
    Color(0xFFFFD6B3),
    Color(0xFFE8D2B4),
    Color(0xFFC6E4D1),
    Color(0xFFBFD6F2),
    Color(0xFFFFE9A8),
    Color(0xFFD8C6E8),
    Color(0xFFF6C2BC),
  ];

  static const List<Color> categoryIconColors = [
    Color(0xFFD81B60),
    Color(0xFFE2772B),
    Color(0xFFA06A2C),
    Color(0xFF2E9E6B),
    Color(0xFF3B6FD6),
    Color(0xFFD9A400),
    Color(0xFF7A4BB8),
    Color(0xFFD94A3A),
  ];

  // Loyalty card gradient
  static const List<Color> bonusCardGradient = [
    Color(0xFFFF5C8D),
    Color(0xFFD81B60),
    Color(0xFF8E1546),
  ];

  // Navigation bar
  static const Color navBarBackground = Color(0xFFFFE9EF);
  static final Color navBarSelected = primary;
  static final Color navBarUnselected = textLight;
}
