import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/order.dart';

/// Single source of truth for how an order status looks across the
/// orders list, order card and order details.
extension OrderStatusStyle on OrderStatus {
  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.confirmed:
        return AppColors.primary;
      case OrderStatus.preparing:
        return AppColors.primary;
      case OrderStatus.ready:
        return AppColors.success;
      case OrderStatus.delivering:
        return AppColors.primary;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.pending:
        return Icons.schedule_rounded;
      case OrderStatus.confirmed:
        return Icons.thumb_up_alt_rounded;
      case OrderStatus.preparing:
        return Icons.restaurant_rounded;
      case OrderStatus.ready:
        return Icons.check_circle_rounded;
      case OrderStatus.delivering:
        return Icons.delivery_dining_rounded;
      case OrderStatus.delivered:
        return Icons.done_all_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Ожидает';
      case OrderStatus.confirmed:
        return 'Принят';
      case OrderStatus.preparing:
        return 'Готовится';
      case OrderStatus.ready:
        return 'Готов';
      case OrderStatus.delivering:
        return 'В пути';
      case OrderStatus.delivered:
        return 'Выполнен';
      case OrderStatus.cancelled:
        return 'Отменён';
    }
  }

  String get description {
    switch (this) {
      case OrderStatus.pending:
        return 'Ожидаем подтверждения';
      case OrderStatus.confirmed:
        return 'Заказ принят в работу';
      case OrderStatus.preparing:
        return 'Готовим ваш заказ';
      case OrderStatus.ready:
        return 'Заказ готов';
      case OrderStatus.delivering:
        return 'Курьер везёт заказ';
      case OrderStatus.delivered:
        return 'Заказ получен';
      case OrderStatus.cancelled:
        return 'Заказ был отменён';
    }
  }

  bool get isActive =>
      this != OrderStatus.delivered && this != OrderStatus.cancelled;
}

/// Display number: the server number, or the id tail when it is missing.
String orderDisplayNumber(Order order) => order.orderNumber.isNotEmpty
    ? order.orderNumber
    : order.id.substring(order.id.length - 6).toUpperCase();

String itemsWord(int count) {
  final r10 = count % 10, r100 = count % 100;
  if (r10 == 1 && r100 != 11) return 'товар';
  if (r10 >= 2 && r10 <= 4 && (r100 < 12 || r100 > 14)) return 'товара';
  return 'товаров';
}

/// Small tinted capsule with a status dot: "• Готовится".
class OrderStatusChip extends StatelessWidget {
  final OrderStatus status;
  final bool large;

  const OrderStatusChip({super.key, required this.status, this.large = false});

  @override
  Widget build(BuildContext context) {
    final c = status.color;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 8 : 5,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (large)
            Icon(status.icon, size: 16, color: c)
          else
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
          SizedBox(width: large ? 6 : 6),
          Text(
            status.label,
            style: AppTextStyles.label.copyWith(
              fontSize: large ? 13 : 12,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}
