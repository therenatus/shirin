import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/create_address_params.dart';
import '../models/address_model.dart';

abstract class AddressesRemoteDatasource {
  Future<List<AddressModel>> getAddresses();
  Future<AddressModel> getAddressById(String id);
  Future<AddressModel> createAddress(CreateAddressParams params);
  Future<AddressModel> updateAddress(String id, UpdateAddressParams params);
  Future<void> deleteAddress(String id);
  Future<AddressModel> setDefaultAddress(String id);
}

class AddressesRemoteDatasourceImpl implements AddressesRemoteDatasource {
  final ApiClient _apiClient;

  AddressesRemoteDatasourceImpl(this._apiClient);

  @override
  Future<List<AddressModel>> getAddresses() async {
    final response = await _apiClient.get(ApiEndpoints.addresses);
    final data = response.data as List<dynamic>;
    return data
        .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AddressModel> getAddressById(String id) async {
    final response = await _apiClient.get(ApiEndpoints.addressById(id));
    return AddressModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AddressModel> createAddress(CreateAddressParams params) async {
    final response = await _apiClient.post(
      ApiEndpoints.addresses,
      data: params.toJson(),
    );
    return AddressModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AddressModel> updateAddress(String id, UpdateAddressParams params) async {
    final response = await _apiClient.patch(
      ApiEndpoints.addressById(id),
      data: params.toJson(),
    );
    return AddressModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteAddress(String id) async {
    await _apiClient.delete(ApiEndpoints.addressById(id));
  }

  @override
  Future<AddressModel> setDefaultAddress(String id) async {
    final response = await _apiClient.post(ApiEndpoints.setDefaultAddress(id));
    return AddressModel.fromJson(response.data as Map<String, dynamic>);
  }
}
