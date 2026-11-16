import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../domain/entities/order.dart';
import 'order_status_style.dart';

/// Order on a content card: number, date and status chip on top, product
/// thumbnails and a summary in the middle, total at the bottom.
class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const OrderCard({super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = order.status;
    return ContentCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(status.icon, color: status.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Заказ #${orderDisplayNumber(order)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.heading3.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 1),
                    Text(_formatDate(order.createdAt), style: AppTextStyles.caption),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OrderStatusChip(status: status),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _ProductThumbs(order: order),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _productsSummary(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.items.length} ${itemsWord(order.items.length)}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Итого', style: AppTextStyles.bodySmall),
              const Spacer(),
              Text(
                formatPrice(order.totalSum),
                style: AppTextStyles.price.copyWith(fontSize: 17),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AppColors.textLight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _productsSummary() {
    return order.items.map((i) => i.name).take(2).join(', ') +
        (order.items.length > 2 ? ' и др.' : '');
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    if (diff.inDays == 1) return 'Вчера, ${_formatTime(date)}';
    if (diff.inDays < 7) return '${diff.inDays} дн назад';

    const months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

/// Up to three overlapping product tiles plus a "+N" tile.
class _ProductThumbs extends StatelessWidget {
  final Order order;
  const _ProductThumbs({required this.order});

  static const double _size = 48;
  static const double _step = 20;

  @override
  Widget build(BuildContext context) {
    final shown = order.items.take(3).toList();
    final extra = order.items.length - 3;
    final count = shown.length + (extra > 0 ? 1 : 0);
    final width = count == 0 ? _size : _size + (count - 1) * _step;

    return SizedBox(
      width: width,
      height: _size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * _step,
              child: _frame(
                ProductImage(
                  url: shown[i].imageUrl ?? '',
                  radius: 12,
                  iconSize: 20,
                ),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * _step,
              child: _frame(
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '+$extra',
                    style: AppTextStyles.label.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _frame(Widget child) => Container(
        width: _size,
        height: _size,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: child,
      );
}
