import 'package:flutter/material.dart';
import 'liquid_glass/liquid_glass_kit.dart';
import '../../core/constants/app_colors.dart';

enum AppButtonVariant { primary, outlined, text }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      // Primary = brand-tinted glass, outlined = neutral glass.
      case AppButtonVariant.primary:
      case AppButtonVariant.outlined:
        return GlassButton(
          label: label,
          icon: icon,
          onTap: onPressed,
          loading: isLoading,
          prominent: variant == AppButtonVariant.primary,
          expanded: true,
          height: 56,
        );
      case AppButtonVariant.text:
        return _buildText(context);
    }
  }

  Widget _buildText(BuildContext context) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      child: _buildChild(AppColors.primary),
    );
  }

  Widget _buildChild(Color color) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    }
    return Text(label);
  }
}
