import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../../../products/domain/entities/category.dart';

/// Four-column grid of category tiles: a pastel rounded tile with an icon,
/// and the name below. Tiles spring on press like glass controls.
class CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final ValueChanged<Category> onCategoryTap;

  const CategoryGrid({
    super.key,
    required this.categories,
    required this.onCategoryTap,
  });

  static const _categoryIcons = [
    Icons.cake_rounded,
    Icons.cookie_rounded,
    Icons.icecream_rounded,
    Icons.breakfast_dining_rounded,
    Icons.local_cafe_rounded,
    Icons.bakery_dining_rounded,
    Icons.lunch_dining_rounded,
    Icons.emoji_food_beverage_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final icon = _categoryIcons[index % _categoryIcons.length];
        final bgColor =
            AppColors.categoryColors[index % AppColors.categoryColors.length];
        final iconColor = AppColors
            .categoryIconColors[index % AppColors.categoryIconColors.length];

        return GlassPressable(
          onTap: () => onCategoryTap(category),
          borderRadius: BorderRadius.circular(22),
          glowColor: Colors.transparent,
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.07),
                        blurRadius: 16,
                        spreadRadius: -4,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: iconColor, size: 32),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
