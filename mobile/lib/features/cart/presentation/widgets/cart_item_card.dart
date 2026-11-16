import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../domain/entities/cart_item.dart';

/// One cart line on a content card: photo tile, name and weight,
/// line total, stepper. Swipe left to remove.
class CartItemCard extends StatelessWidget {
  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final p = item.product;
    return Dismissible(
      key: Key('cart-${p.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 28),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      child: ContentCard(
        padding: const EdgeInsets.all(12),
        onTap: () => context.push('/product/${p.id}'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 84,
              height: 84,
              // Concentric with the card: 24 - 12 padding.
              child: ProductImage(url: p.mainImage, radius: 14, iconSize: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(fontSize: 15, height: 1.25),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (p.weight != null) formatWeight(p.weight!),
                      '${formatPrice(p.price)} / шт',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                  if (item.inscription != null)
                    Text(
                      'Надпись: «${item.inscription}»',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
                    ),
                  if (item.wishes != null)
                    Text(
                      item.wishes!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                  if (item.referencePhotoUrl != null)
                    Text('С фото-образцом', style: AppTextStyles.caption),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formatPrice(item.totalPrice),
                            style: AppTextStyles.price.copyWith(fontSize: 17),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      QuantityStepper(
                        quantity: item.quantity,
                        compact: true,
                        onChanged: (q) => q <= 0 ? onRemove() : onQuantityChanged(q),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
