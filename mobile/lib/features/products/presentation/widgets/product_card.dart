import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/add_to_cart_animation.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../../domain/entities/product.dart';

/// Catalog tile: a solid content card holding the photo, name, weight and
/// the price pill that adds to cart. Once in the cart the pill turns into a
/// stepper. Needs a bounded height (grid cell or fixed-height row).
class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
  });

  /// Grid aspect ratio that fits the card at phone widths.
  static const double gridAspectRatio = 0.6;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  static const double _radius = 24;
  static const double _inset = 8;

  final GlobalKey _imageKey = GlobalKey();

  void _add() {
    // Custom cakes need a date and wishes: open the product page instead
    if (widget.product.isPreorder) {
      context.push('/product/${widget.product.id}');
      return;
    }
    final provider = CartAnimationProvider.of(context);
    if (provider != null) {
      provider.controller.animateToCart(
        productKey: _imageKey,
        cartKey: provider.cartIconKey,
        productWidget: SizedBox(
          width: 56,
          height: 56,
          child: ProductImage(url: widget.product.mainImage, radius: 14, iconSize: 22),
        ),
      );
    }
    if (widget.onAddToCart != null) {
      widget.onAddToCart!();
    } else {
      context.read<CartBloc>().add(AddToCart(widget.product));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    const imageRadius = _radius - _inset;

    return ContentCard(
      onTap: widget.onTap,
      radius: _radius,
      padding: const EdgeInsets.all(_inset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                KeyedSubtree(
                  key: _imageKey,
                  child: ProductImage(url: p.mainImage, radius: imageRadius),
                ),
                if (p.hasDiscount || p.isNew)
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (p.hasDiscount)
                          TagBadge(
                            text: '-${p.discountPercent.toInt()}%',
                            color: AppColors.textPrimary,
                          ),
                        if (p.isNew) const TagBadge(text: 'НОВИНКА'),
                      ],
                    ),
                  ),
                if (!p.isAvailable)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(imageRadius),
                      ),
                      alignment: Alignment.center,
                      child: const TagBadge(
                        text: 'НЕТ В НАЛИЧИИ',
                        color: AppColors.surface,
                        textColor: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 2, 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(fontSize: 15, height: 1.25),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.weight != null ? formatWeight(p.weight!) : ' ',
                    maxLines: 1,
                    style: AppTextStyles.caption,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      if (p.hasDiscount)
                        Expanded(
                          child: Text(
                            formatPrice(p.oldPrice!),
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: AppTextStyles.caption.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.textLight,
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      _CartControl(product: p, onAdd: _add),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartControl extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;

  const _CartControl({required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final p = product;
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        final qty = state is CartLoaded
            ? state.items
                .where((i) => i.lineId == p.id)
                .fold<int>(0, (s, i) => s + i.quantity)
            : 0;
        if (qty > 0) {
          return QuantityStepper(
            quantity: qty,
            compact: true,
            filled: true,
            onChanged: (q) {
              if (q <= 0) {
                context.read<CartBloc>().add(RemoveFromCart(p.id));
              } else {
                context.read<CartBloc>().add(
                      UpdateQuantity(lineId: p.id, quantity: q),
                    );
              }
            },
          );
        }
        return PricePill(
          label: formatPrice(p.price),
          accent: p.hasDiscount,
          onTap: p.isAvailable ? onAdd : () {},
        );
      },
    );
  }
}
