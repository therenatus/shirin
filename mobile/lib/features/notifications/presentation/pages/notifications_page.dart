import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../../domain/app_notification.dart';
import '../bloc/notifications_cubit.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsCubit>().load();
  }

  IconData _icon(String type) => switch (type) {
    'payment' => Icons.payments_rounded,
    'loyalty' => Icons.stars_rounded,
    'promo' => Icons.local_offer_rounded,
    _ => Icons.receipt_long_rounded,
  };

  String _when(DateTime d) {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final time = '${two(d.hour)}:${two(d.minute)}';
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'Сегодня, $time';
    }
    return '${two(d.day)}.${two(d.month)}, $time';
  }

  void _open(BuildContext context, AppNotification n) {
    context.read<NotificationsCubit>().markRead(n);
    if (n.orderId != null) context.push('/orders/${n.orderId}');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        final cubit = context.read<NotificationsCubit>();
        return GlassPage(
          title: 'Уведомления',
          onRefresh: cubit.load,
          actions: [
            if (state.unread > 0)
              GlassIconButton(
                icon: Icons.done_all_rounded,
                tooltip: 'Прочитать все',
                onTap: cubit.markAllRead,
              ),
          ],
          slivers: [
            if (state.loading && state.items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (state.items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      state.error ??
                          'Здесь появятся статусы заказов, оплата и начисления баллов',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList.separated(
                  itemCount: state.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final n = state.items[i];
                    return ContentCard(
                      onTap: () => _open(context, n),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryTint,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _icon(n.type),
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n.title,
                                  style: AppTextStyles.label.copyWith(
                                    fontWeight: n.isRead
                                        ? FontWeight.w600
                                        : FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(n.body, style: AppTextStyles.bodySmall),
                                const SizedBox(height: 4),
                                Text(
                                  _when(n.createdAt),
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          if (!n.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 6, left: 8),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
