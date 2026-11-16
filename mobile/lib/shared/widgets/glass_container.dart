import 'package:flutter/material.dart';

import 'liquid_glass/liquid_glass_kit.dart';

/// Legacy name for a glass panel. Prefer [LiquidGlass] / [GlassCard].
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
    final style = (isLight ? GlassStyle.clear : GlassStyle.regular)
        .copyWith(blur: enableBlur ? blurStrength : 0.01);
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: LiquidGlass(
        style: style,
        borderRadius: BorderRadius.circular(borderRadius),
        padding: padding,
        child: child,
      ),
    );
  }
}
