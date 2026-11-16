import 'package:flutter/material.dart';

import 'liquid_glass/liquid_background.dart';

/// Legacy name for the page backdrop. Prefer [LiquidBackground].
class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool showOrbs;

  const GradientBackground({
    super.key,
    required this.child,
    this.showOrbs = true,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidBackground(
      intensity: showOrbs ? 1 : 0.4,
      child: child,
    );
  }
}
