import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/loyalty_info_model.dart';
import '../models/loyalty_transaction_model.dart';
import '../models/punch_card_model.dart';

abstract class LoyaltyRemoteDatasource {
  Future<LoyaltyInfoModel> getLoyaltyInfo();
  Future<List<LoyaltyTransactionModel>> getLoyaltyHistory();
  Future<List<PunchCardModel>> getPunchCards();
  Future<PunchCardModel> claimFreeCoffee(String size);
}

class LoyaltyRemoteDatasourceImpl implements LoyaltyRemoteDatasource {
  final ApiClient _apiClient;

  LoyaltyRemoteDatasourceImpl(this._apiClient);

  @override
  Future<LoyaltyInfoModel> getLoyaltyInfo() async {
    final response = await _apiClient.get(ApiEndpoints.loyalty);
    return LoyaltyInfoModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<LoyaltyTransactionModel>> getLoyaltyHistory() async {
    final response = await _apiClient.get(ApiEndpoints.loyaltyHistory);
    final data = response.data as List<dynamic>;
    return data
        .map((e) =>
            LoyaltyTransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<PunchCardModel>> getPunchCards() async {
    final response = await _apiClient.get(ApiEndpoints.punchCards);
    final data = response.data as List<dynamic>;
    return data
        .map((e) => PunchCardModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PunchCardModel> claimFreeCoffee(String size) async {
    final response = await _apiClient.post(ApiEndpoints.claimFreeCoffee(size));
    return PunchCardModel.fromJson(response.data as Map<String, dynamic>);
  }
}
