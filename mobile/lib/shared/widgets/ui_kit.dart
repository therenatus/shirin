import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_theme.dart';
import 'liquid_glass/liquid_glass_kit.dart';

/// Small building blocks shared by the catalog, cart and product screens.
///
/// The visual language: photos sit on a quiet pastel tile, controls are
/// chunky pills, the accent appears only on the one action that matters.

/// Product photo on a pastel tile with a shimmer placeholder.
class ProductImage extends StatelessWidget {
  final String url;
  final double radius;
  final BoxFit fit;
  final Color? tileColor;
  final double iconSize;

  const ProductImage({
    super.key,
    required this.url,
    this.radius = AppTheme.radiusLg,
    this.fit = BoxFit.cover,
    this.tileColor,
    this.iconSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    final tile = tileColor ?? AppColors.productTile;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        color: tile,
        child: url.isEmpty
            ? _Placeholder(iconSize: iconSize)
            : CachedNetworkImage(
                imageUrl: url,
                fit: fit,
                fadeInDuration: const Duration(milliseconds: 200),
                placeholder: (_, _) => Shimmer.fromColors(
                  baseColor: AppColors.shimmerBase,
                  highlightColor: AppColors.shimmerHighlight,
                  child: Container(color: AppColors.shimmerBase),
                ),
                errorWidget: (_, _, _) => _Placeholder(iconSize: iconSize),
              ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double iconSize;
  const _Placeholder({required this.iconSize});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.cake_outlined,
        size: iconSize,
        color: AppColors.primary.withValues(alpha: 0.35),
      ),
    );
  }
}

/// Minus / count / plus. [onChanged] receives 0 when the user removes the item.
class QuantityStepper extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;
  final bool compact;
  final bool filled;

  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.compact = false,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 34.0 : 44.0;
    final bg = filled ? AppColors.primary : AppColors.surfaceMuted;
    final fg = filled ? AppColors.textOnPrimary : AppColors.textPrimary;

    Widget button(IconData icon, VoidCallback onTap) => SizedBox(
          width: size,
          height: size,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.selectionClick();
                onTap();
              },
              child: Icon(icon, size: compact ? 18 : 20, color: fg),
            ),
          ),
        );

    return Container(
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 14,
                  spreadRadius: -4,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(
            quantity <= 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
            () => onChanged(quantity - 1),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: compact ? 22 : 28),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.price.copyWith(
                fontSize: compact ? 14 : 16,
                color: fg,
              ),
            ),
          ),
          button(Icons.add_rounded, () => onChanged(quantity + 1)),
        ],
      ),
    );
  }
}

/// The "price is the button" pill: tap adds to cart.
class PricePill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool accent;

  const PricePill({
    super.key,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent ? AppColors.primary : AppColors.surfaceMuted,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.price.copyWith(
                  fontSize: 14,
                  color: accent ? AppColors.textOnPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.add_rounded,
                size: 18,
                color: accent ? AppColors.textOnPrimary : AppColors.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal chip used for categories and filters.
class SelectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  const SelectChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final style = selected
        ? GlassStyle.prominent.copyWith(shadowOpacity: 0.18)
        : GlassStyle.regular.copyWith(shadowOpacity: 0.06);
    return LiquidGlass.capsule(
      style: style,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          Text(
            label,
            style: AppTextStyles.label.copyWith(color: style.foreground),
          ),
        ],
      ),
    );
  }
}

/// 44pt round glass icon button (back, favourite, share).
/// [background] tints the glass when given.
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final Color? background;
  final double size;

  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
    this.background,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final style = background == null
        ? GlassStyle.regular
        : GlassStyle.regular.copyWith(tint: background!.withValues(alpha: 0.75));
    return GlassIconButton(
      icon: icon,
      onTap: onTap,
      size: size,
      style: style,
      iconColor: color ?? AppColors.textPrimary,
    );
  }
}

/// Section title with an optional trailing action ("Все").
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTextStyles.heading2)),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

/// Small badge for "Новинка" / "-20%".
class TagBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;

  const TagBadge({
    super.key,
    required this.text,
    this.color = AppColors.primary,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTextStyles.overline.copyWith(
          color: textColor,
          letterSpacing: 0.4,
          fontSize: 11,
        ),
      ),
    );
  }
}

/// Full-width accent button with a label on the left and a value on the right,
/// e.g. "В корзину ……… 1 200 с".
class SplitActionButton extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback? onPressed;
  final bool loading;

  const SplitActionButton({
    super.key,
    required this.label,
    this.value,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      label: label,
      trailing: value,
      onTap: onPressed,
      loading: loading,
      prominent: true,
      expanded: true,
      height: 56,
    );
  }
}

/// Formats 1200 -> "1 200 с" (som, the local currency).
String formatPrice(num value) {
  final n = value.round();
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final left = s.length - i;
    buf.write(s[i]);
    if (left > 1 && left % 3 == 1) buf.write(' ');
  }
  return '${n < 0 ? '-' : ''}$buf с';
}

/// Formats grams: 1000 -> "1 кг", 150 -> "150 г".
String formatWeight(double grams) {
  if (grams >= 1000) {
    final kg = grams / 1000;
    final txt = kg == kg.roundToDouble() ? kg.toInt().toString() : kg.toStringAsFixed(1);
    return '$txt кг';
  }
  return '${grams.toInt()} г';
}
