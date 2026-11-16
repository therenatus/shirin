import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/notifications_repository.dart';
import '../../domain/app_notification.dart';

class NotificationsState extends Equatable {
  final bool loading;
  final List<AppNotification> items;
  final String? error;

  /// Unread count for the bell badge.
  final int unread;

  const NotificationsState({
    this.loading = false,
    this.items = const [],
    this.error,
    this.unread = 0,
  });

  NotificationsState copyWith({
    bool? loading,
    List<AppNotification>? items,
    String? error,
    bool clearError = false,
    int? unread,
  }) => NotificationsState(
    loading: loading ?? this.loading,
    items: items ?? this.items,
    error: clearError ? null : error ?? this.error,
    unread: unread ?? this.unread,
  );

  @override
  List<Object?> get props => [loading, items, error, unread];
}

/// App-wide: the bell badge and the notifications screen share it.
class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationsRepository repository;

  NotificationsCubit(this.repository) : super(const NotificationsState());

  Future<void> refreshUnread() async {
    final result = await repository.getUnreadCount();
    if (isClosed) return;
    result.fold((_) {}, (n) => emit(state.copyWith(unread: n)));
  }

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));
    final result = await repository.getNotifications();
    if (isClosed) return;
    result.fold(
      (f) => emit(state.copyWith(loading: false, error: f.message)),
      (items) => emit(
        state.copyWith(
          loading: false,
          items: items,
          unread: items.where((n) => !n.isRead).length,
        ),
      ),
    );
  }

  Future<void> markRead(AppNotification n) async {
    if (n.isRead) return;
    emit(
      state.copyWith(
        items: [for (final i in state.items) i.id == n.id ? i.read() : i],
        unread: (state.unread - 1).clamp(0, 1 << 30),
      ),
    );
    await repository.markRead(n.id);
  }

  Future<void> markAllRead() async {
    emit(
      state.copyWith(items: [for (final i in state.items) i.read()], unread: 0),
    );
    await repository.markAllRead();
  }

  /// Signed out: nothing to show.
  void clear() => emit(const NotificationsState());
}
