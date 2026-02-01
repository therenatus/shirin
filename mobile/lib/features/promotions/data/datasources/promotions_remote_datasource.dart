import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/promotion_model.dart';

abstract class PromotionsRemoteDatasource {
  Future<List<PromotionModel>> getPromotions();
}

class PromotionsRemoteDatasourceImpl implements PromotionsRemoteDatasource {
  final ApiClient _apiClient;

  PromotionsRemoteDatasourceImpl(this._apiClient);

  @override
  Future<List<PromotionModel>> getPromotions() async {
    final response = await _apiClient.get(ApiEndpoints.promotions);
    final data = response.data as List<dynamic>;
    return data
        .map((e) => PromotionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
