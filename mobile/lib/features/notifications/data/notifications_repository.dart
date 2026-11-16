import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../../../core/network/api_client.dart';
import '../../auth/data/datasources/auth_local_datasource.dart';
import '../domain/app_notification.dart';

/// Customer notifications and push token registration.
class NotificationsRepository {
  final ApiClient _api;
  final AuthLocalDatasource _auth;

  NotificationsRepository(this._api, this._auth);

  Future<bool> get _isTestMode async =>
      kDebugMode && await _auth.getAccessToken() == 'test-access-token';

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  Future<Either<Failure, List<AppNotification>>> getNotifications() async {
    if (await _isTestMode) return const Right([]);
    return _guard(() async {
      final res = await _api.get(
        ApiEndpoints.notifications,
        queryParameters: {'limit': 50},
      );
      final list = (res.data as Map<String, dynamic>)['data'] as List<dynamic>;
      return list
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<Either<Failure, int>> getUnreadCount() async {
    if (await _isTestMode) return const Right(0);
    return _guard(() async {
      final res = await _api.get(ApiEndpoints.notificationsUnread);
      return ((res.data as Map<String, dynamic>)['unread'] as num).toInt();
    });
  }

  Future<Either<Failure, void>> markRead(String id) =>
      _guard(() => _api.patch('${ApiEndpoints.notifications}/$id/read'));

  Future<Either<Failure, void>> markAllRead() =>
      _guard(() => _api.post(ApiEndpoints.notificationsReadAll));

  /// Tells the server where to send pushes for the signed-in user.
  Future<Either<Failure, void>> registerPushToken(String token) async {
    if (await _isTestMode) return const Right(null);
    return _guard(
      () => _api.post(ApiEndpoints.fcmToken, data: {'token': token}),
    );
  }
}
