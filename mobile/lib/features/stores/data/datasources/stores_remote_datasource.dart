import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/store_model.dart';

abstract class StoresRemoteDatasource {
  Future<List<StoreModel>> getStores();
}

class StoresRemoteDatasourceImpl implements StoresRemoteDatasource {
  final ApiClient _apiClient;

  StoresRemoteDatasourceImpl(this._apiClient);

  @override
  Future<List<StoreModel>> getStores() async {
    final response = await _apiClient.get(ApiEndpoints.stores);
    final data = response.data as List<dynamic>;
    return data
        .map((e) => StoreModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
