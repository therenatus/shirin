import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shirin_app/core/error/failures.dart';
import 'package:shirin_app/features/notifications/data/notifications_repository.dart';
import 'package:shirin_app/features/notifications/domain/app_notification.dart';
import 'package:shirin_app/features/notifications/presentation/bloc/notifications_cubit.dart';

class _FakeRepo implements NotificationsRepository {
  final List<String> readIds = [];
  bool allRead = false;
  final List<AppNotification> items;
  _FakeRepo(this.items);

  @override
  Future<Either<Failure, List<AppNotification>>> getNotifications() async => Right(items);
  @override
  Future<Either<Failure, int>> getUnreadCount() async => Right(items.where((n) => !n.isRead).length);
  @override
  Future<Either<Failure, void>> markRead(String id) async {
    readIds.add(id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> markAllRead() async {
    allRead = true;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> registerPushToken(String token) async => const Right(null);
}

AppNotification n(String id, {bool read = false}) => AppNotification.fromJson({
      'id': id,
      'title': 'Заказ готов',
      'body': 'Ждём вас',
      'type': 'order_status',
      'data': {'orderId': 'o-$id', 'orderNumber': 'SHR-1'},
      'isRead': read,
      'createdAt': '2026-11-17T08:00:00.000Z',
    });

void main() {
  test('reads the order id from the notification data', () {
    expect(n('1').orderId, 'o-1');
  });

  test('marking one as read lowers the badge once', () async {
    final repo = _FakeRepo([n('1'), n('2'), n('3', read: true)]);
    final cubit = NotificationsCubit(repo);
    await cubit.load();
    expect(cubit.state.unread, 2);

    await cubit.markRead(cubit.state.items.first);
    await cubit.markRead(cubit.state.items.first); // already read: no-op
    expect(cubit.state.unread, 1);
    expect(repo.readIds, ['1']);

    await cubit.markAllRead();
    expect(cubit.state.unread, 0);
    expect(cubit.state.items.every((i) => i.isRead), isTrue);
    expect(repo.allRead, isTrue);
    await cubit.close();
  });
}
