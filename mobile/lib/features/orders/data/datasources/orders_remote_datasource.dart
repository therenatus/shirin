import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/create_order_params.dart';
import '../models/order_model.dart';

abstract class OrdersRemoteDatasource {
  Future<List<OrderModel>> getOrders();
  Future<OrderModel> getOrderById(String id);
  Future<OrderModel> createOrder(CreateOrderParams params);
}

class OrdersRemoteDatasourceImpl implements OrdersRemoteDatasource {
  final ApiClient _apiClient;

  OrdersRemoteDatasourceImpl(this._apiClient);

  @override
  Future<List<OrderModel>> getOrders() async {
    final response = await _apiClient.get(ApiEndpoints.orders);
    final data = response.data as List<dynamic>;
    return data
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<OrderModel> getOrderById(String id) async {
    final response = await _apiClient.get('${ApiEndpoints.orders}/$id');
    return OrderModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<OrderModel> createOrder(CreateOrderParams params) async {
    final response = await _apiClient.post(
      ApiEndpoints.orders,
      data: params.toJson(),
    );
    return OrderModel.fromJson(response.data as Map<String, dynamic>);
  }
}
