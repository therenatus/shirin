import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Visual recipe for a Liquid Glass surface.
///
/// Liquid Glass is a material for the *control layer* (bars, buttons, sheets,
/// fields) floating above content. Content itself (photos, text, lists) stays
/// solid for legibility.
@immutable
class GlassStyle {
  /// Backdrop blur radius.
  final double blur;

  /// Backdrop saturation boost (1 = unchanged). Gives glass its "vibrancy".
  final double saturation;

  /// Tint laid over the blurred backdrop.
  final Color tint;

  /// Strength of the specular rim and top sheen (0..1).
  final double highlight;

  /// Soft drop shadow under the surface.
  final double shadowOpacity;

  /// Color used for the shadow.
  final Color shadowColor;

  /// Foreground color recommended for icons/text on this glass.
  final Color foreground;

  const GlassStyle({
    this.blur = 18,
    this.saturation = 1.8,
    this.tint = const Color(0xA6FFFFFF),
    this.highlight = 1,
    this.shadowOpacity = 0.12,
    this.shadowColor = const Color(0xFF8E1546),
    this.foreground = AppColors.textPrimary,
  });

  /// Default glass for bars and controls.
  static const GlassStyle regular = GlassStyle();

  /// Thinner, more transparent glass for elements over rich content
  /// (photos, maps). Shows more of what is behind it.
  static const GlassStyle clear = GlassStyle(
    blur: 10,
    saturation: 1.6,
    tint: Color(0x40FFFFFF),
    highlight: 1,
    shadowOpacity: 0.16,
  );

  /// Heavier glass for large surfaces (sheets, dialogs) where text must read well.
  static const GlassStyle thick = GlassStyle(
    blur: 30,
    saturation: 1.9,
    tint: Color(0xD9FFFFFF),
    highlight: 0.8,
    shadowOpacity: 0.14,
  );

  /// Brand-tinted glass for the one primary action on a screen.
  static const GlassStyle prominent = GlassStyle(
    blur: 16,
    saturation: 1.6,
    tint: Color(0xE6D81B60),
    highlight: 0.9,
    shadowOpacity: 0.28,
    shadowColor: AppColors.primary,
    foreground: Colors.white,
  );

  /// Dark smoked glass for controls over photos and video (stories, gallery).
  static const GlassStyle dark = GlassStyle(
    blur: 14,
    saturation: 1.4,
    tint: Color(0x59200C16),
    highlight: 0.55,
    shadowOpacity: 0.2,
    shadowColor: Colors.black,
    foreground: Colors.white,
  );

  GlassStyle copyWith({
    double? blur,
    double? saturation,
    Color? tint,
    double? highlight,
    double? shadowOpacity,
    Color? shadowColor,
    Color? foreground,
  }) {
    return GlassStyle(
      blur: blur ?? this.blur,
      saturation: saturation ?? this.saturation,
      tint: tint ?? this.tint,
      highlight: highlight ?? this.highlight,
      shadowOpacity: shadowOpacity ?? this.shadowOpacity,
      shadowColor: shadowColor ?? this.shadowColor,
      foreground: foreground ?? this.foreground,
    );
  }

  /// Blur + saturation filter applied to the backdrop.
  ImageFilter get backdropFilter => ImageFilter.compose(
        outer: ColorFilter.matrix(_saturationMatrix(saturation)),
        inner: ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
          tileMode: TileMode.mirror,
        ),
      );

  static List<double> _saturationMatrix(double s) {
    const r = 0.2126, g = 0.7152, b = 0.0722;
    final i = 1 - s;
    return [
      r * i + s, g * i, b * i, 0, 0, //
      r * i, g * i + s, b * i, 0, 0, //
      r * i, g * i, b * i + s, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
  }
}
