import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import 'glass_style.dart';
import 'liquid_glass.dart';

/// Round glass icon button (back, close, favourite, share). 44 pt by default,
/// the iOS minimum touch target.
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final GlassStyle style;
  final Color? iconColor;
  final String? tooltip;

  /// Small dot/count badge in the corner.
  final Widget? badge;

  const GlassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 44,
    this.iconSize = 22,
    this.style = GlassStyle.regular,
    this.iconColor,
    this.tooltip,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = LiquidGlass(
      style: style,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
      onTap: onTap,
      child: Center(
        child: Icon(icon, size: iconSize, color: iconColor ?? style.foreground),
      ),
    );
    if (badge != null) {
      button = Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(top: -2, right: -2, child: badge!),
        ],
      );
    }
    if (tooltip != null) button = Tooltip(message: tooltip!, child: button);
    return button;
  }
}

/// Capsule glass button with a label. Use [prominent] for the one primary
/// action on a screen (brand-tinted glass); everything else stays neutral.
class GlassButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool prominent;
  final bool expanded;
  final bool loading;
  final double height;

  /// Optional value on the right, e.g. a price: "В корзину ··· 1 200 с".
  final String? trailing;

  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.prominent = false,
    this.expanded = false,
    this.loading = false,
    this.height = 54,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !loading;
    // A disabled prominent button turns into neutral glass instead of a
    // washed-out pink; the brand tint appears once the action is available.
    final style = prominent && (enabled || loading)
        ? GlassStyle.prominent
        : GlassStyle.regular;
    final fg = enabled || loading ? style.foreground : AppColors.textLight;
    final textStyle = AppTextStyles.button.copyWith(color: fg);

    Widget content;
    if (loading) {
      content = SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
      );
    } else {
      final labelGroup = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: fg),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
      content = trailing == null
          ? labelGroup
          : Row(
              children: [
                // Label shrinks with an ellipsis; the value always stays whole.
                Expanded(child: labelGroup),
                const SizedBox(width: 12),
                Text(
                  trailing!,
                  style: AppTextStyles.price.copyWith(color: fg, fontSize: 16),
                ),
              ],
            );
    }

    final button = AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: KeyedSubtree(
        key: ValueKey(style == GlassStyle.prominent),
        child: LiquidGlass.capsule(
          style: style,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          onTap: enabled ? onTap : null,
          child: Center(child: content),
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
