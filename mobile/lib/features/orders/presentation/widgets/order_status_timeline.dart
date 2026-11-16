import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../../domain/entities/order.dart';
import 'order_status_style.dart';

/// Glass status header for the order details screen: the current status
/// large, its description, and a horizontal progress track of all steps.
/// A cancelled order shows a single cancelled state instead of the track.
class OrderStatusTimeline extends StatelessWidget {
  final OrderStatus currentStatus;

  const OrderStatusTimeline({super.key, required this.currentStatus});

  static const _steps = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.ready,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final isCancelled = currentStatus == OrderStatus.cancelled;
    final c = currentStatus.color;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(currentStatus.icon, color: c, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'СТАТУС ЗАКАЗА',
                      style: AppTextStyles.overline,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCancelled ? 'Заказ отменён' : currentStatus.label,
                      style: AppTextStyles.heading2.copyWith(
                        color: isCancelled ? AppColors.error : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCancelled
                          ? 'Если у вас есть вопросы, свяжитесь с поддержкой'
                          : currentStatus.description,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isCancelled) ...[
            const SizedBox(height: 20),
            _Track(current: _steps.indexOf(currentStatus)),
          ],
        ],
      ),
    );
  }
}

class _Track extends StatelessWidget {
  final int current;
  const _Track({required this.current});

  @override
  Widget build(BuildContext context) {
    final steps = OrderStatusTimeline._steps;
    return Column(
      children: [
        // Dots joined by segments.
        Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              _Dot(
                icon: steps[i].icon,
                done: i <= current,
                isCurrent: i == current,
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: i < current
                          ? AppColors.primary
                          : AppColors.textLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < steps.length; i++)
              Expanded(
                child: Text(
                  steps[i].label,
                  textAlign: i == 0
                      ? TextAlign.left
                      : i == steps.length - 1
                          ? TextAlign.right
                          : TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    fontWeight: i == current ? FontWeight.w800 : FontWeight.w600,
                    color: i <= current ? AppColors.textPrimary : AppColors.textLight,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final IconData icon;
  final bool done;
  final bool isCurrent;

  const _Dot({required this.icon, required this.done, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      width: isCurrent ? 34 : 28,
      height: isCurrent ? 34 : 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppColors.primary : Colors.white.withValues(alpha: 0.7),
        border: done
            ? null
            : Border.all(color: AppColors.textLight.withValues(alpha: 0.35), width: 1.5),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Icon(
        done && !isCurrent ? Icons.check_rounded : icon,
        size: isCurrent ? 18 : 15,
        color: done ? Colors.white : AppColors.textLight,
      ),
    );
  }
}
