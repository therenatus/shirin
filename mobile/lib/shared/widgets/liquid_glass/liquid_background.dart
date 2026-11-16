import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Soft "liquid" backdrop: a warm rose wash with slowly drifting color blobs.
/// Glass needs something behind it to refract; on plain white it looks flat.
///
/// The drift is very slow (one cycle ≈ 24 s) and repaints in isolation, so it
/// costs little. Pass [animate] = false for static screens or tests.
class LiquidBackground extends StatefulWidget {
  final Widget child;
  final bool animate;

  /// Lower intensity for content-heavy screens (lists, forms).
  final double intensity;

  const LiquidBackground({
    super.key,
    required this.child,
    this.animate = true,
    this.intensity = 1,
  });

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(LiquidBackground old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: _BlobsPainter(
              animation: _controller,
              intensity: widget.intensity,
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Blob {
  final Color color;
  final Offset anchor; // fraction of size
  final double radius; // fraction of shortest side
  final double phase;
  final Offset drift; // fraction of size

  const _Blob(this.color, this.anchor, this.radius, this.phase, this.drift);
}

class _BlobsPainter extends CustomPainter {
  final Animation<double> animation;
  final double intensity;

  _BlobsPainter({required this.animation, required this.intensity})
      : super(repaint: animation);

  static const _blobs = [
    _Blob(AppColors.liquidRose, Offset(0.92, 0.04), 0.95, 0.0, Offset(0.06, 0.04)),
    _Blob(AppColors.liquidPeach, Offset(0.02, 0.30), 0.80, 0.33, Offset(0.08, 0.05)),
    _Blob(AppColors.liquidLilac, Offset(0.95, 0.58), 0.85, 0.66, Offset(0.05, 0.07)),
    _Blob(AppColors.liquidRaspberry, Offset(0.10, 0.92), 0.75, 0.15, Offset(0.07, 0.04)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = AppColors.background);

    final t = animation.value * 2 * math.pi;
    final side = size.shortestSide;
    for (final b in _blobs) {
      final dx = math.sin(t + b.phase * 2 * math.pi) * b.drift.dx * size.width;
      final dy = math.cos(t + b.phase * 2 * math.pi) * b.drift.dy * size.height;
      final center = Offset(b.anchor.dx * size.width + dx, b.anchor.dy * size.height + dy);
      final radius = b.radius * side;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            b.color.withValues(alpha: b.color.a * intensity),
            b.color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_BlobsPainter old) => old.intensity != intensity;
}
