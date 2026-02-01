import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final bool enableBlur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool isLight;
  final double blurStrength;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.enableBlur = true,
    this.padding,
    this.margin,
    this.isLight = false,
    this.blurStrength = 20,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor = isLight ? AppColors.glassFillLight : AppColors.glassFill;
    final borderColor = isLight ? AppColors.glassBorderLight : AppColors.glassBorder;

    final container = Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            fillColor,
            fillColor.withValues(alpha: fillColor.a * 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.glassShadow,
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: AppColors.glassInnerGlow,
            blurRadius: 1,
            offset: const Offset(-1, -1),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );

    if (!enableBlur) return container;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
        child: container,
      ),
    );
  }
}

class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final List<Color>? gradientColors;
  final VoidCallback? onTap;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.gradientColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          gradient: gradientColors != null
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors!,
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    backgroundColor ?? AppColors.glassFill,
                    (backgroundColor ?? AppColors.glassFill)
                        .withValues(alpha: 0.85),
                  ],
                ),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: AppColors.glassBorder,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (backgroundColor ?? AppColors.primary).withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: -5,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.50),
              blurRadius: 1,
              offset: const Offset(-1, -1),
            ),
          ],
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}
