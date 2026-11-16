import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Type scale for the Shirin app.
///
/// One family (Manrope, geometric and bold, full Cyrillic) carries the whole
/// app; weight and size do the hierarchy. Headings sit tight, body breathes.
class AppTextStyles {
  AppTextStyles._();

  // Display and headings
  static TextStyle display = GoogleFonts.manrope(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static TextStyle heading1 = GoogleFonts.manrope(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  static TextStyle heading2 = GoogleFonts.manrope(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.25,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static TextStyle heading3 = GoogleFonts.manrope(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // Body
  static TextStyle bodyLarge = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium = GoogleFonts.manrope(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: AppColors.textPrimary,
  );

  static TextStyle bodySmall = GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  // Controls
  static TextStyle button = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.1,
    color: AppColors.textOnPrimary,
  );

  static TextStyle label = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// Small uppercase eyebrow, e.g. section markers. Letter-spaced on purpose.
  static TextStyle overline = GoogleFonts.manrope(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
    color: AppColors.textSecondary,
  );

  static TextStyle caption = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  /// Prices and counters: tabular digits so columns line up.
  static TextStyle price = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
