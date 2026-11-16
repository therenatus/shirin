import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../bloc/notifications_cubit.dart';

/// Glass bell with the unread count; opens the notifications screen.
class NotificationsBell extends StatelessWidget {
  final GlassStyle? style;
  const NotificationsBell({super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      buildWhen: (a, b) => a.unread != b.unread,
      builder: (context, state) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            GlassIconButton(
              icon: state.unread > 0
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              tooltip: state.unread > 0
                  ? 'Уведомления: ${state.unread} новых'
                  : 'Уведомления',
              style: style ?? GlassStyle.regular,
              onTap: () => context.push('/notifications'),
            ),
            if (state.unread > 0)
              Positioned(
                right: 2,
                top: 2,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    constraints: const BoxConstraints(minWidth: 18),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      state.unread > 99 ? '99+' : '${state.unread}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
