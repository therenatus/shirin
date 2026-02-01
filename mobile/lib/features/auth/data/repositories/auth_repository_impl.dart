import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/update_profile_params.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remoteDatasource;
  final AuthLocalDatasource _localDatasource;

  static const _testPhone = '+996999999999';
  static const _testCode = '9999';

  AuthRepositoryImpl(this._remoteDatasource, this._localDatasource);

  bool _isTestPhone(String phone) => phone == _testPhone;

  Future<bool> get _isTestMode async {
    final token = await _localDatasource.getAccessToken();
    return token == 'test-access-token';
  }

  @override
  Future<Either<Failure, void>> sendCode(String phone) async {
    if (_isTestPhone(phone)) {
      return const Right(null);
    }
    try {
      await _remoteDatasource.sendCode(phone);
      return const Right(null);
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, User>> verifyCode(String phone, String code) async {
    if (_isTestPhone(phone) && code == _testCode) {
      const testUser = UserModel(
        id: 'test-user-id',
        phone: _testPhone,
        firstName: 'Тест',
        lastName: 'Пользователь',
        loyaltyPoints: 150,
      );
      await _localDatasource.cacheTokens('test-access-token', 'test-refresh-token');
      await _localDatasource.cacheUser(testUser);
      return Right(testUser.toEntity());
    }
    try {
      final response = await _remoteDatasource.verifyCode(phone, code);
      await _localDatasource.cacheTokens(
        response.accessToken,
        response.refreshToken,
      );
      await _localDatasource.cacheUser(response.user);
      return Right(response.user.toEntity());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final hasToken = await _localDatasource.hasToken();
      if (!hasToken) {
        return const Left(UnauthorizedFailure());
      }

      // For test token, return cached user without API call
      final token = await _localDatasource.getAccessToken();
      if (token == 'test-access-token') {
        final cachedUser = await _localDatasource.getCachedUser();
        if (cachedUser != null) {
          return Right(cachedUser.toEntity());
        }
      }

      final user = await _remoteDatasource.getCurrentUser();
      await _localDatasource.cacheUser(user);
      return Right(user.toEntity());
    } on UnauthorizedException {
      await _localDatasource.clearCache();
      return const Left(UnauthorizedFailure());
    } on NetworkException {
      // Try cached user when offline
      final cachedUser = await _localDatasource.getCachedUser();
      if (cachedUser != null) {
        return Right(cachedUser.toEntity());
      }
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile(UpdateProfileParams params) async {
    if (await _isTestMode) {
      // For test mode, return updated user from cache
      final cachedUser = await _localDatasource.getCachedUser();
      if (cachedUser != null) {
        final updatedUser = UserModel(
          id: cachedUser.id,
          phone: cachedUser.phone,
          firstName: params.firstName ?? cachedUser.firstName,
          lastName: params.lastName ?? cachedUser.lastName,
          email: params.email ?? cachedUser.email,
          birthDate: params.birthDate ?? cachedUser.birthDate,
          loyaltyPoints: cachedUser.loyaltyPoints,
          qrCode: cachedUser.qrCode,
        );
        await _localDatasource.cacheUser(updatedUser);
        return Right(updatedUser.toEntity());
      }
      return const Left(UnauthorizedFailure());
    }
    try {
      final user = await _remoteDatasource.updateProfile(params);
      await _localDatasource.cacheUser(user);
      return Right(user.toEntity());
    } on UnauthorizedException {
      await _localDatasource.clearCache();
      return const Left(UnauthorizedFailure());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remoteDatasource.logout();
    } catch (_) {
      // Logout locally even if remote fails
    }
    await _localDatasource.clearCache();
    return const Right(null);
  }
}
