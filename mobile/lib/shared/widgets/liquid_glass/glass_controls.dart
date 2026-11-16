import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import 'glass_style.dart';
import 'liquid_glass.dart';

/// Solid content card: white, softly shadowed. Content (products, orders,
/// text) lives on these, not on glass, so it stays crisp and legible.
class ContentCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final VoidCallback? onTap;
  final Color color;

  const ContentCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = 24,
    this.onTap,
    this.color = AppColors.surface,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.07),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    return card;
  }
}

/// Glass group: a glass panel holding controls (settings rows, filters,
/// quick actions). Use [ContentCard] for content instead.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final GlassStyle style;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = 26,
    this.style = GlassStyle.regular,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: LiquidGlass(
        style: style,
        borderRadius: BorderRadius.circular(radius),
        padding: padding,
        onTap: onTap,
        child: child,
      ),
    );
  }
}

/// Glass chip for categories and filters. Selected chips get the brand tint.
class GlassChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  const GlassChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
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
      child: Center(
        widthFactor: 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: style.foreground),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: style.foreground,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// iOS-style segmented control on glass, with a sliding glass thumb.
class GlassSegmented<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final double height;

  const GlassSegmented({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.height = 44,
  });

  @override
  Widget build(BuildContext context) {
    final index = values.indexOf(selected).clamp(0, values.length - 1);
    return LiquidGlass.capsule(
      height: height,
      padding: const EdgeInsets.all(4),
      style: GlassStyle.regular.copyWith(shadowOpacity: 0.06),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / values.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutBack,
                left: index * w,
                top: 0,
                bottom: 0,
                width: w,
                child: LiquidGlass.capsule(
                  shadow: false,
                  style: const GlassStyle(
                    blur: 4,
                    tint: Color(0xF2FFFFFF),
                    shadowOpacity: 0,
                  ),
                ),
              ),
              Row(
                children: [
                  for (final v in values)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (v == selected) return;
                          HapticFeedback.selectionClick();
                          onChanged(v);
                        },
                        child: Center(
                          child: Text(
                            labelOf(v),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.label.copyWith(
                              fontSize: 14,
                              color: v == selected
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Text field on glass. Pass a [controller] or listen with [onChanged].
class GlassTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final String? label;
  final IconData? icon;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final bool autofocus;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;

  const GlassTextField({
    super.key,
    this.controller,
    this.hint,
    this.label,
    this.icon,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLines = 1,
    this.autofocus = false,
    this.focusNode,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    final field = LiquidGlass(
      borderRadius: BorderRadius.circular(maxLines > 1 ? 22 : 999),
      style: GlassStyle.regular.copyWith(shadowOpacity: 0.05),
      padding: EdgeInsets.symmetric(horizontal: icon != null ? 14 : 20),
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Padding(
              padding: EdgeInsets.only(top: maxLines > 1 ? 16 : 0),
              child: Icon(icon, size: 20, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              autofocus: autofocus,
              onChanged: onChanged,
              onFieldSubmitted: onSubmitted,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              inputFormatters: inputFormatters,
              maxLines: maxLines,
              validator: validator,
              textCapitalization: textCapitalization,
              style: AppTextStyles.bodyLarge,
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: hint,
                filled: false,
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                hintStyle: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ),
          ),
          if (suffix != null) suffix!,
        ],
      ),
    );

    if (label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(label!, style: AppTextStyles.label),
        ),
        field,
      ],
    );
  }
}

/// Opens a Liquid Glass bottom sheet floating above the content with
/// rounded corners on all sides (iOS 26 style).
Future<T?> showGlassSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool useRootNavigator = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    backgroundColor: Colors.transparent,
    elevation: 0,
    showDragHandle: false,
    barrierColor: AppColors.textPrimary.withValues(alpha: 0.18),
    builder: (context) {
      final bottom = MediaQuery.paddingOf(context).bottom;
      final keyboard = MediaQuery.viewInsetsOf(context).bottom;
      final top = MediaQuery.paddingOf(context).top;
      final maxHeight =
          MediaQuery.sizeOf(context).height - top - 12 - keyboard - bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(
          8,
          0,
          8,
          (bottom > 0 ? bottom - 4 : 8) + keyboard,
        ),
        child: ConstrainedBox(
          // Never slide under the status bar.
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: LiquidGlass(
            style: GlassStyle.thick,
            borderRadius: BorderRadius.circular(34),
            child: SafeArea(
              top: false,
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 38,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.textLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Flexible(child: builder(context)),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Floating glass toast, replaces Material snackbars.
///
/// [bottomOffset] lifts the toast above floating bottom bars; by default it
/// clears the tab bar.
void showGlassToast(
  BuildContext context,
  String message, {
  IconData? icon,
  double bottomOffset = 96,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottomOffset),
        content: LiquidGlass.capsule(
          style: GlassStyle.dark.copyWith(tint: const Color(0xCC2A1620)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: Colors.white),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                ),
              ),
              if (actionLabel != null)
                GestureDetector(
                  onTap: () {
                    messenger.hideCurrentSnackBar();
                    onAction?.call();
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      actionLabel,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
}
