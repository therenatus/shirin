import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../domain/entities/order.dart';
import '../bloc/orders_bloc.dart';
import '../widgets/order_status_style.dart';
import '../widgets/order_status_timeline.dart';

class OrderDetailsPage extends StatelessWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (context, state) {
        if (state is OrdersLoading) {
          return GlassPage(
            title: 'Заказ',
            largeTitle: false,
            slivers: [_fill(_buildLoadingState())],
          );
        }
        if (state is OrdersError) {
          return GlassPage(
            title: 'Заказ',
            largeTitle: false,
            slivers: [_fill(_buildErrorState(context, state.message))],
          );
        }
        if (state is OrderDetailsLoaded) {
          return _buildContent(context, state.order);
        }
        return const GlassPage(title: 'Заказ', largeTitle: false, slivers: []);
      },
    );
  }

  Widget _fill(Widget child) =>
      SliverFillRemaining(hasScrollBody: false, child: child);

  Widget _buildContent(BuildContext context, Order order) {
    final canCancel = order.status == OrderStatus.pending ||
        order.status == OrderStatus.confirmed;

    return GlassPage(
      title: 'Заказ #${orderDisplayNumber(order)}',
      eyebrow: _formatFullDate(order.createdAt),
      bottomBar: canCancel ? _CancelButton(onTap: () => _showCancelDialog(context)) : null,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.list(
            children: [
              OrderStatusTimeline(currentStatus: order.status),
              const SizedBox(height: 16),
              _buildOrderItems(order),
              if (order.address != null) ...[
                const SizedBox(height: 16),
                _buildDeliveryInfo(order),
              ],
              const SizedBox(height: 16),
              _buildPriceSummary(order),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTextStyles.heading3)),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildOrderItems(Order order) {
    return ContentCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Состав заказа',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${order.items.length} ${itemsWord(order.items.length)}',
                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          for (var i = 0; i < order.items.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppColors.divider),
              ),
            Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: ProductImage(
                    url: order.items[i].imageUrl ?? '',
                    radius: 14,
                    iconSize: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.items[i].name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label.copyWith(height: 1.25),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${formatPrice(order.items[i].price)} × ${order.items[i].quantity}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatPrice(order.items[i].total),
                  style: AppTextStyles.price.copyWith(fontSize: 15),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo(Order order) {
    return ContentCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Адрес доставки', style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(order.address!, style: AppTextStyles.label),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary(Order order) {
    return ContentCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _priceRow('Товары', formatPrice(_calculateSubtotal(order))),
          const SizedBox(height: 10),
          _priceRow('Доставка', 'Бесплатно', color: AppColors.success),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Text('Итого', style: AppTextStyles.heading3)),
              Text(
                formatPrice(order.totalSum),
                style: AppTextStyles.heading2.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {Color? color}) {
    return Row(
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
    );
  }

  void _showCancelDialog(BuildContext context) {
    HapticFeedback.mediumImpact();
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
              child: const Icon(Icons.warning_rounded,
                  color: AppColors.error, size: 32),
            ),
            const SizedBox(height: 16),
            Text('Отменить заказ?', style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text(
              'Вы уверены, что хотите отменить этот заказ?\nЭто действие нельзя отменить.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    label: 'Назад',
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
                      Navigator.pop(ctx);
                      // TODO: Cancel order
                    },
                    child: Center(
                      child: Text('Отменить', style: AppTextStyles.button),
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text('Загружаем детали...', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LiquidGlass(
              width: 112,
              height: 112,
              borderRadius: BorderRadius.circular(56),
              child: const Center(
                child: Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.error),
              ),
            ),
            const SizedBox(height: 24),
            Text('Ошибка загрузки', style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: AppTextStyles.bodySmall),
            const SizedBox(height: 24),
            GlassButton(
              label: 'Назад',
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateSubtotal(Order order) {
    return order.items.fold(0.0, (sum, item) => sum + item.total);
  }

  String _formatFullDate(DateTime date) {
    const months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
    ];
    final time =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '${date.day} ${months[date.month - 1]} ${date.year}, $time';
  }
}

/// Neutral glass capsule with a destructive label. Not the brand-tinted
/// action: cancelling is a secondary, cautious action.
class _CancelButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CancelButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LiquidGlass.capsule(
      height: 54,
      onTap: onTap,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.close_rounded, size: 20, color: AppColors.error),
            const SizedBox(width: 8),
            Text(
              'Отменить заказ',
              style: AppTextStyles.button.copyWith(color: AppColors.error),
            ),
          ],
        ),
      ),
    );
  }
}
