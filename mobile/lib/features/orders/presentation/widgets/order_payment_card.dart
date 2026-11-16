import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../domain/entities/checkout_preview.dart';
import '../../domain/entities/order.dart';
import '../../domain/usecases/get_payment_info.dart';
import 'order_status_style.dart';

/// Prepayment for a made-to-order cake: how much, until when, and the
/// company's payment details and QR while it is still due.
class OrderPaymentCard extends StatefulWidget {
  final Order order;

  const OrderPaymentCard({super.key, required this.order});

  @override
  State<OrderPaymentCard> createState() => _OrderPaymentCardState();
}

class _OrderPaymentCardState extends State<OrderPaymentCard> {
  PaymentInfo? _info;

  @override
  void initState() {
    super.initState();
    if (widget.order.awaitingPayment) _loadInfo();
  }

  Future<void> _loadInfo() async {
    final result = await sl<GetPaymentInfo>()();
    if (!mounted) return;
    result.fold((_) {}, (info) => setState(() => _info = info));
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final (title, color, icon) = switch (order.paymentStatus) {
      PaymentStatus.pending => ('Ждём предоплату', AppColors.warning, Icons.hourglass_top_rounded),
      PaymentStatus.paid => ('Предоплата получена', AppColors.success, Icons.verified_rounded),
      PaymentStatus.refundPending => ('Вернём предоплату', AppColors.error, Icons.undo_rounded),
      PaymentStatus.refunded => ('Предоплата возвращена', AppColors.textSecondary, Icons.undo_rounded),
      PaymentStatus.notRequired => ('', AppColors.textSecondary, Icons.info_outline_rounded),
    };
    final due = order.paymentDueAt;

    return ContentCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: AppTextStyles.heading3)),
              Text(
                formatPrice(order.prepaymentAmount),
                style: AppTextStyles.price.copyWith(color: color),
              ),
            ],
          ),
          if (order.awaitingPayment && order.status.isActive) ...[
            const SizedBox(height: 10),
            if (due != null)
              Text(
                'Оплатите до ${_two(due.hour)}:${_two(due.minute)} '
                '${_two(due.day)}.${_two(due.month)}, иначе заказ отменится автоматически.',
                style: AppTextStyles.bodySmall,
              ),
            if (_info?.qrUrl != null) ...[
              const SizedBox(height: 14),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Image.network(_info!.qrUrl!, width: 180, height: 180),
                ),
              ),
            ],
            if (_info?.details != null) ...[
              const SizedBox(height: 12),
              Text(_info!.details!, style: AppTextStyles.bodyMedium),
            ],
            const SizedBox(height: 12),
            GlassButton(
              label: 'Скопировать номер заказа ${orderDisplayNumber(order)}',
              icon: Icons.copy_rounded,
              expanded: true,
              onTap: () {
                Clipboard.setData(ClipboardData(text: orderDisplayNumber(order)));
                showGlassToast(context, 'Номер заказа скопирован',
                    icon: Icons.check_rounded, bottomOffset: 120);
              },
            ),
            const SizedBox(height: 8),
            Text(
              'После оплаты менеджер подтвердит её, и мы начнём готовить. '
              'Потяните экран вниз, чтобы обновить статус.',
              style: AppTextStyles.caption,
            ),
          ],
          if (order.paymentStatus == PaymentStatus.refundPending) ...[
            const SizedBox(height: 10),
            Text('Заказ отменён. Менеджер свяжется с вами, чтобы вернуть деньги.',
                style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }
}
