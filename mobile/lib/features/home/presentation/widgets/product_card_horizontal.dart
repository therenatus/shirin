import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/add_to_cart_animation.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../products/domain/entities/product.dart';

/// Compact product tile for horizontal rails: photo, name, price and a
/// round add button that flies the photo to the cart.
class ProductCardHorizontal extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const ProductCardHorizontal({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
  });

  @override
  State<ProductCardHorizontal> createState() => _ProductCardHorizontalState();
}

class _ProductCardHorizontalState extends State<ProductCardHorizontal>
    with SingleTickerProviderStateMixin {
  final GlobalKey _addButtonKey = GlobalKey();
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 0.1,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleAddToCart() {
    // Trigger scale animation
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });

    // Trigger flying animation
    final provider = CartAnimationProvider.of(context);
    if (provider != null) {
      provider.controller.animateToCart(
        productKey: _addButtonKey,
        cartKey: provider.cartIconKey,
        productWidget: _buildAnimatingWidget(),
      );
    }

    // Call the original callback
    widget.onAddToCart?.call();
  }

  Widget _buildAnimatingWidget() {
    return SizedBox(
      width: 50,
      height: 50,
      child: ProductImage(url: widget.product.mainImage, radius: 12, iconSize: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: ContentCard(
        onTap: widget.onTap,
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 120,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductImage(url: p.mainImage, radius: 16),
                  if (p.isNew)
                    const Positioned(
                      top: 8,
                      left: 8,
                      child: TagBadge(text: 'НОВИНКА'),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 2, 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(fontSize: 13, height: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatPrice(p.price),
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: AppTextStyles.price.copyWith(
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _scaleController,
                        builder: (context, child) => Transform.scale(
                          scale: 1.0 - _scaleController.value,
                          child: child,
                        ),
                        child: GestureDetector(
                          key: _addButtonKey,
                          onTap: _handleAddToCart,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
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
