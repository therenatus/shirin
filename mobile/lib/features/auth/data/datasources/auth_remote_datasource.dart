import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/update_profile_params.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDatasource {
  Future<void> sendCode(String phone);
  Future<AuthResponseModel> verifyCode(String phone, String code);
  Future<UserModel> getCurrentUser();
  Future<UserModel> updateProfile(UpdateProfileParams params);
  Future<void> logout();
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final ApiClient _apiClient;

  AuthRemoteDatasourceImpl(this._apiClient);

  @override
  Future<void> sendCode(String phone) async {
    await _apiClient.post(
      ApiEndpoints.sendCode,
      data: {'phone': phone},
    );
  }

  @override
  Future<AuthResponseModel> verifyCode(String phone, String code) async {
    final response = await _apiClient.post(
      ApiEndpoints.verifyCode,
      data: {'phone': phone, 'code': code},
    );
    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final response = await _apiClient.get(ApiEndpoints.profile);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<UserModel> updateProfile(UpdateProfileParams params) async {
    final response = await _apiClient.patch(
      ApiEndpoints.userProfile,
      data: params.toJson(),
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> logout() async {
    await _apiClient.post(ApiEndpoints.logout);
  }
}
