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

/// Cart: lines on content cards, promo code, totals, and one prominent
/// checkout button floating above the tab bar.
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _promoController = TextEditingController();
  bool _promoApplied = false;

  static const double _promoDiscount = 50;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

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
    final discount = _promoApplied ? _promoDiscount : 0;
    final total = (state.totalSum - discount).clamp(0, double.infinity);

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
        trailing: formatPrice(total),
        prominent: true,
        expanded: true,
        onTap: () => showGlassToast(
          context,
          'Оформление заказа появится в следующем обновлении',
          icon: Icons.info_outline_rounded,
        ),
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
                      UpdateQuantity(productId: item.product.id, quantity: q),
                    ),
                onRemove: () =>
                    context.read<CartBloc>().add(RemoveFromCart(item.product.id)),
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              children: [
                _PromoField(
                  controller: _promoController,
                  applied: _promoApplied,
                  onApply: () {
                    if (_promoController.text.trim().isEmpty) return;
                    setState(() => _promoApplied = true);
                    FocusScope.of(context).unfocus();
                  },
                  onReset: () => setState(() {
                    _promoApplied = false;
                    _promoController.clear();
                  }),
                ),
                const SizedBox(height: 16),
                _SummaryCard(
                  rows: [
                    ('Товары', formatPrice(state.totalSum), null),
                    ('Доставка', 'Бесплатно', AppColors.success),
                    if (_promoApplied)
                      ('Промокод', '-${formatPrice(_promoDiscount)}', AppColors.primary),
                  ],
                  total: formatPrice(total),
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

class _PromoField extends StatelessWidget {
  final TextEditingController controller;
  final bool applied;
  final VoidCallback onApply;
  final VoidCallback onReset;

  const _PromoField({
    required this.controller,
    required this.applied,
    required this.onApply,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlass.capsule(
      height: 54,
      padding: const EdgeInsets.only(left: 18, right: 6),
      style: applied
          ? GlassStyle.regular.copyWith(
              tint: AppColors.primaryTint.withValues(alpha: 0.85),
              shadowOpacity: 0.06,
            )
          : GlassStyle.regular.copyWith(shadowOpacity: 0.06),
      child: Row(
        children: [
          Icon(
            applied ? Icons.check_circle_rounded : Icons.local_offer_outlined,
            size: 20,
            color: applied ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !applied,
              textCapitalization: TextCapitalization.characters,
              style: AppTextStyles.label,
              cursorColor: AppColors.primary,
              onSubmitted: (_) => onApply(),
              decoration: const InputDecoration(
                hintText: 'Промокод',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          LiquidGlass.capsule(
            height: 42,
            shadow: false,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            style: const GlassStyle(
              blur: 4,
              tint: Color(0xE6FFFFFF),
              shadowOpacity: 0,
            ),
            onTap: applied ? onReset : onApply,
            child: Center(
              widthFactor: 1,
              child: Text(
                applied ? 'Убрать' : 'Применить',
                style: AppTextStyles.label.copyWith(color: AppColors.primary),
              ),
            ),
          ),
        ],
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
