import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
import '../widgets/cart_item_card.dart';

/// Cart: lines on content cards, the items total, and one prominent
/// checkout button floating above the tab bar. Delivery, points and the
/// final total are calculated by the server on the checkout screen.
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        if (state is! CartLoaded) {
          return const GlassPage(title: 'Корзина', showBack: false, slivers: []);
        }
        if (state.isEmpty) {
          return GlassPage(
            title: 'Корзина',
            showBack: false,
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyCart(onBrowse: () => context.go('/catalog')),
              ),
            ],
          );
        }
        return _buildContent(state);
      },
    );
  }

  Widget _buildContent(CartLoaded state) {
    final hasPreorder = state.items.any((i) => i.product.isPreorder);

    return GlassPage(
      title: 'Корзина',
      eyebrow: '${state.totalItems} ${_plural(state.totalItems)}',
      showBack: false,
      actions: [
        GlassIconButton(
          icon: Icons.delete_sweep_outlined,
          tooltip: 'Очистить',
          onTap: () => _confirmClear(context),
        ),
      ],
      bottomBar: GlassButton(
        label: 'Оформить заказ',
        trailing: formatPrice(state.totalSum),
        prominent: true,
        expanded: true,
        onTap: () => context.push('/checkout'),
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.separated(
            itemCount: state.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = state.items[index];
              return CartItemCard(
                item: item,
                onQuantityChanged: (q) => context.read<CartBloc>().add(
                      UpdateQuantity(lineId: item.lineId, quantity: q),
                    ),
                onRemove: () =>
                    context.read<CartBloc>().add(RemoveFromCart(item.lineId)),
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              children: [
                _SummaryCard(
                  rows: [
                    ('Товары', formatPrice(state.totalSum), null),
                    (
                      'Доставка и баллы',
                      'на следующем шаге',
                      AppColors.textSecondary,
                    ),
                    if (hasPreorder)
                      ('Торт на заказ', 'нужна дата и предоплата', AppColors.warning),
                  ],
                  total: formatPrice(state.totalSum),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _plural(int n) {
    final r10 = n % 10, r100 = n % 100;
    if (r10 == 1 && r100 != 11) return 'товар';
    if (r10 >= 2 && r10 <= 4 && (r100 < 12 || r100 > 14)) return 'товара';
    return 'товаров';
  }

  void _confirmClear(BuildContext context) {
    showGlassSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  size: 30, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            Text('Очистить корзину?', style: AppTextStyles.heading2),
            const SizedBox(height: 6),
            Text(
              'Все товары будут удалены.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    label: 'Отмена',
                    expanded: true,
                    onTap: () => Navigator.pop(ctx),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LiquidGlass.capsule(
                    height: 54,
                    style: GlassStyle.regular.copyWith(
                      tint: AppColors.error.withValues(alpha: 0.9),
                      shadowColor: AppColors.error,
                      foreground: Colors.white,
                    ),
                    onTap: () {
                      context.read<CartBloc>().add(const ClearCart());
                      Navigator.pop(ctx);
                    },
                    child: Center(
                      child: Text('Очистить', style: AppTextStyles.button),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<(String, String, Color?)> rows;
  final String total;

  const _SummaryCard({required this.rows, required this.total});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          for (final (label, value, color) in rows) ...[
            Row(
              children: [
                Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
                Text(
                  value,
                  style: AppTextStyles.price.copyWith(
                    fontSize: 14,
                    color: color ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Text('Итого', style: AppTextStyles.heading3)),
              Text(total, style: AppTextStyles.heading2),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final VoidCallback onBrowse;
  const _EmptyCart({required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LiquidGlass(
              width: 120,
              height: 120,
              borderRadius: BorderRadius.circular(60),
              child: const Center(
                child: Icon(Icons.shopping_bag_outlined,
                    size: 50, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 24),
            Text('Пока пусто', style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text(
              'Наполеон, эклеры или латте? Загляните в меню.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 24),
            GlassButton(
              label: 'Открыть меню',
              icon: Icons.menu_book_rounded,
              prominent: true,
              onTap: onBrowse,
            ),
          ],
        ),
      ),
    );
  }
}
