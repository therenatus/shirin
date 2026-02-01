import 'dart:convert';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

abstract class AuthLocalDatasource {
  Future<void> cacheTokens(String accessToken, String refreshToken);
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<String?> getAccessToken();
  Future<bool> hasToken();
  Future<void> clearCache();
}

class AuthLocalDatasourceImpl implements AuthLocalDatasource {
  final SecureStorageService _storageService;

  AuthLocalDatasourceImpl(this._storageService);

  @override
  Future<void> cacheTokens(String accessToken, String refreshToken) async {
    await _storageService.saveAccessToken(accessToken);
    await _storageService.saveRefreshToken(refreshToken);
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    await _storageService.saveUserData(json.encode(user.toJson()));
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final userData = await _storageService.getUserData();
    if (userData == null) return null;
    return UserModel.fromJson(json.decode(userData) as Map<String, dynamic>);
  }

  @override
  Future<String?> getAccessToken() async {
    return await _storageService.getAccessToken();
  }

  @override
  Future<bool> hasToken() async {
    final token = await _storageService.getAccessToken();
    return token != null;
  }

  @override
  Future<void> clearCache() async {
    await _storageService.clearAll();
  }
}
