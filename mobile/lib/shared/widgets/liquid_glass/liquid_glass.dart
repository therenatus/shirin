import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'glass_style.dart';

/// A Liquid Glass surface: blurred and saturated backdrop, a light tint,
/// a specular rim that catches light on the top-left edge, a soft top sheen
/// and a floating shadow.
///
/// When [onTap] is set the glass reacts to touch like iOS: it gently grows,
/// lights up from the touch point and springs back on release.
class LiquidGlass extends StatelessWidget {
  final Widget? child;
  final GlassStyle style;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Haptic tick on tap. On by default for interactive glass.
  final bool haptics;

  /// Draws the drop shadow. Turn off for glass nested inside other glass.
  final bool shadow;

  const LiquidGlass({
    super.key,
    this.child,
    this.style = GlassStyle.regular,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.padding,
    this.width,
    this.height,
    this.onTap,
    this.onLongPress,
    this.haptics = true,
    this.shadow = true,
  });

  /// Pill shape: fully rounded ends.
  const LiquidGlass.capsule({
    super.key,
    this.child,
    this.style = GlassStyle.regular,
    this.padding,
    this.width,
    this.height,
    this.onTap,
    this.onLongPress,
    this.haptics = true,
    this.shadow = true,
  }) : borderRadius = const BorderRadius.all(Radius.circular(999));

  @override
  Widget build(BuildContext context) {
    final surface = _GlassSurface(
      style: style,
      borderRadius: borderRadius,
      padding: padding,
      width: width,
      height: height,
      shadow: shadow,
      child: child,
    );

    if (onTap == null && onLongPress == null) return surface;

    return GlassPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      haptics: haptics,
      borderRadius: borderRadius,
      glowColor: style.foreground == Colors.white
          ? Colors.white.withValues(alpha: 0.35)
          : Colors.white.withValues(alpha: 0.7),
      child: surface,
    );
  }
}

class _GlassSurface extends StatelessWidget {
  final Widget? child;
  final GlassStyle style;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final bool shadow;

  const _GlassSurface({
    required this.child,
    required this.style,
    required this.borderRadius,
    required this.padding,
    required this.width,
    required this.height,
    required this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: IconTheme.merge(
        data: IconThemeData(color: style.foreground),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: style.foreground),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );

    Widget glass = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: style.backdropFilter,
        child: CustomPaint(
          painter: _TintPainter(style: style, borderRadius: borderRadius),
          foregroundPainter:
              _RimPainter(highlight: style.highlight, borderRadius: borderRadius),
          child: content,
        ),
      ),
    );

    if (shadow && style.shadowOpacity > 0) {
      glass = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: style.shadowColor.withValues(alpha: style.shadowOpacity),
              blurRadius: 24,
              spreadRadius: -6,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: style.shadowColor.withValues(alpha: style.shadowOpacity * 0.5),
              blurRadius: 4,
              spreadRadius: -2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: glass,
      );
    }

    if (width != null || height != null) {
      glass = SizedBox(width: width, height: height, child: glass);
    }
    return RepaintBoundary(child: glass);
  }
}

/// Tint layer: base tint plus a vertical gradient that makes the glass look
/// thicker at the bottom edge, like light passing through a lens.
class _TintPainter extends CustomPainter {
  final GlassStyle style;
  final BorderRadius borderRadius;

  _TintPainter({required this.style, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    canvas.drawRRect(rrect, Paint()..color = style.tint);

    if (style.highlight > 0) {
      // Top sheen: light falling onto the upper half of the surface.
      final sheen = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [
            Colors.white.withValues(alpha: 0.30 * style.highlight),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(rect);
      canvas.drawRRect(rrect, sheen);

      // Bottom depth: a whisper of shade at the lower edge.
      final depth = Paint()
        ..shader = LinearGradient(
          begin: Alignment.center,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            style.shadowColor.withValues(alpha: 0.05 * style.highlight),
          ],
        ).createShader(rect);
      canvas.drawRRect(rrect, depth);
    }
  }

  @override
  bool shouldRepaint(_TintPainter old) =>
      old.style != style || old.borderRadius != borderRadius;
}

/// Specular rim: a bright edge on the top-left that fades around the shape,
/// with a softer echo on the bottom-right, plus a faint inner glow line.
class _RimPainter extends CustomPainter {
  final double highlight;
  final BorderRadius borderRadius;

  _RimPainter({required this.highlight, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    if (highlight <= 0 || size.isEmpty) return;
    final rect = Offset.zero & size;

    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0, 0.32, 0.68, 1],
        colors: [
          Colors.white.withValues(alpha: 0.95 * highlight),
          Colors.white.withValues(alpha: 0.18 * highlight),
          Colors.white.withValues(alpha: 0.10 * highlight),
          Colors.white.withValues(alpha: 0.55 * highlight),
        ],
      ).createShader(rect);
    canvas.drawRRect(borderRadius.toRRect(rect.deflate(0.6)), rim);

    // Inner glow: light refracting just inside the edge.
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.45 * highlight),
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.20 * highlight),
        ],
      ).createShader(rect);
    final inset = math.min(3.0, size.shortestSide / 6);
    canvas.drawRRect(
      _deflateRadius(borderRadius, inset).toRRect(rect.deflate(inset)),
      glow,
    );
  }

  BorderRadius _deflateRadius(BorderRadius r, double d) {
    Radius s(Radius x) =>
        Radius.elliptical(math.max(0, x.x - d), math.max(0, x.y - d));
    return BorderRadius.only(
      topLeft: s(r.topLeft),
      topRight: s(r.topRight),
      bottomLeft: s(r.bottomLeft),
      bottomRight: s(r.bottomRight),
    );
  }

  @override
  bool shouldRepaint(_RimPainter old) =>
      old.highlight != highlight || old.borderRadius != borderRadius;
}

/// Touch response for glass: grows slightly while pressed, lights up from the
/// touch point and springs back with a little overshoot on release.
class GlassPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius borderRadius;
  final Color glowColor;
  final bool haptics;

  /// Scale while pressed. iOS glass grows rather than shrinks.
  final double pressedScale;

  const GlassPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.glowColor = const Color(0xB3FFFFFF),
    this.haptics = true,
    this.pressedScale = 1.04,
  });

  @override
  State<GlassPressable> createState() => _GlassPressableState();
}

class _GlassPressableState extends State<GlassPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
    reverseDuration: const Duration(milliseconds: 420),
  );
  Offset? _touch;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _down(TapDownDetails d) {
    setState(() => _touch = d.localPosition);
    _controller.forward();
  }

  void _up([_]) => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _down,
        onTapUp: _up,
        onTapCancel: _up,
        onTap: widget.onTap == null
            ? null
            : () {
                if (widget.haptics) HapticFeedback.selectionClick();
                widget.onTap!();
              },
        onLongPress: widget.onLongPress,
        child: AnimatedBuilder(
          animation: _controller,
          child: widget.child,
          builder: (context, child) {
            final t = _controller.status == AnimationStatus.reverse
                ? Curves.easeOutBack.transform(_controller.value)
                : Curves.easeOut.transform(_controller.value);
            final scale = 1 + (widget.pressedScale - 1) * t;
            return Transform.scale(
              scale: scale,
              child: Stack(
                children: [
                  child!,
                  if (_controller.value > 0 && _touch != null)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ClipRRect(
                          borderRadius: widget.borderRadius,
                          child: CustomPaint(
                            painter: _TouchGlowPainter(
                              center: _touch!,
                              color: widget.glowColor,
                              strength: _controller.value,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TouchGlowPainter extends CustomPainter {
  final Offset center;
  final Color color;
  final double strength;

  _TouchGlowPainter({
    required this.center,
    required this.color,
    required this.strength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.max(size.width, size.height) * 0.9;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: color.a * 0.55 * strength),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_TouchGlowPainter old) =>
      old.center != center || old.strength != strength || old.color != color;
}
