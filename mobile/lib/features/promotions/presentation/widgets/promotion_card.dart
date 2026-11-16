import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../domain/entities/promotion.dart';

/// Promotion on a solid content card: a photo (or brand gradient) header
/// with a clear-glass "до …" capsule, then the title and description.
class PromotionCard extends StatelessWidget {
  final Promotion promotion;

  const PromotionCard({super.key, required this.promotion});

  static const double _radius = 24;
  static const double _inset = 8;

  @override
  Widget build(BuildContext context) {
    final image = promotion.imageUrl;
    return ContentCard(
      radius: _radius,
      padding: const EdgeInsets.all(_inset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (image != null && image.isNotEmpty)
                  ProductImage(url: image, radius: _radius - _inset)
                else
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_radius - _inset),
                      gradient: const LinearGradient(
                        colors: AppColors.bonusCardGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.local_offer_rounded,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: LiquidGlass.capsule(
                    style: GlassStyle.clear,
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 15, color: AppColors.textPrimary),
                        const SizedBox(width: 6),
                        Text(
                          'до ${_formatDate(promotion.endDate)}',
                          style: AppTextStyles.label.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(promotion.title, style: AppTextStyles.heading3),
                const SizedBox(height: 6),
                Text(
                  promotion.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
