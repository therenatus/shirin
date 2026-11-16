import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'glass_style.dart';
import 'liquid_glass.dart';

/// Geometry of the floating tab bar, shared with pages so their content can
/// scroll under the bar without being hidden behind it at the end.
class GlassTabBarMetrics {
  GlassTabBarMetrics._();

  static const double height = 66;
  static const double horizontalMargin = 16;

  static double bottomMargin(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    return inset > 0 ? math.max(inset - 10, 8) : 14;
  }

  /// Space a scrollable needs at its end to clear the floating bar.
  static double clearance(BuildContext context) =>
      height + bottomMargin(context) + 16;
}

/// Floating Liquid Glass tab bar with a glass "droplet" that slides to the
/// selected tab, stretching while it travels and settling with a spring.
class GlassTabBar extends StatefulWidget {
  final int currentIndex;
  final int itemCount;
  final ValueChanged<int> onTap;

  /// Builds one tab's content (icon + label) for the given selection state.
  final Widget Function(BuildContext context, int index, bool selected) itemBuilder;

  /// Optional keys for each tab's hit area (used by integration tests).
  final List<Key?>? itemKeys;

  const GlassTabBar({
    super.key,
    required this.currentIndex,
    required this.itemCount,
    required this.onTap,
    required this.itemBuilder,
    this.itemKeys,
  });

  @override
  State<GlassTabBar> createState() => _GlassTabBarState();
}

class _GlassTabBarState extends State<GlassTabBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late double _from = widget.currentIndex.toDouble();
  late double _to = widget.currentIndex.toDouble();

  @override
  void didUpdateWidget(GlassTabBar old) {
    super.didUpdateWidget(old);
    if (widget.currentIndex != old.currentIndex) {
      _from = _position;
      _to = widget.currentIndex.toDouble();
      _controller.forward(from: 0);
    }
  }

  double get _position {
    final t = _SpringCurve().transform(_controller.value);
    return _from + (_to - _from) * t;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        GlassTabBarMetrics.horizontalMargin,
        0,
        GlassTabBarMetrics.horizontalMargin,
        GlassTabBarMetrics.bottomMargin(context),
      ),
      child: LiquidGlass.capsule(
        height: GlassTabBarMetrics.height,
        style: GlassStyle.regular.copyWith(shadowOpacity: 0.16),
        padding: const EdgeInsets.all(5),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / widget.itemCount;
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final pos = _position;
                // Stretch mid-flight, proportional to the distance travelled.
                final travel = (_to - _from).abs().clamp(0.0, 2.0);
                final pulse = math.sin(_controller.value * math.pi);
                final stretch = pulse * (0.18 + 0.12 * travel) * itemWidth;
                final squash = 1 - pulse * 0.08;
                final dropletWidth = itemWidth + stretch;
                final left = pos * itemWidth - stretch / 2;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: left,
                      top: constraints.maxHeight * (1 - squash) / 2,
                      width: dropletWidth,
                      height: constraints.maxHeight * squash,
                      child: const _Droplet(),
                    ),
                    Row(
                      children: List.generate(widget.itemCount, (i) {
                        final selected = i == widget.currentIndex;
                        return Expanded(
                          child: GestureDetector(
                            key: widget.itemKeys?[i],
                            behavior: HitTestBehavior.opaque,
                            onTap: () => widget.onTap(i),
                            child: widget.itemBuilder(context, i, selected),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// The selection lens: a brighter glass capsule nested in the bar.
class _Droplet extends StatelessWidget {
  const _Droplet();

  @override
  Widget build(BuildContext context) {
    return LiquidGlass.capsule(
      shadow: false,
      style: GlassStyle(
        blur: 4,
        saturation: 1.2,
        tint: Color.alphaBlend(
          AppColors.primary.withValues(alpha: 0.07),
          Colors.white.withValues(alpha: 0.62),
        ),
        highlight: 1,
        shadowOpacity: 0,
      ),
    );
  }
}

/// Underdamped spring: overshoots slightly and settles, like iOS glass.
class _SpringCurve extends Curve {
  @override
  double transformInternal(double t) {
    const damping = 6.5;
    const frequency = 9.0;
    return 1 - math.exp(-damping * t) * math.cos(frequency * t);
  }
}
