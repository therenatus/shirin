import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/checkout_preview.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/create_order_params.dart';
import '../models/order_model.dart';

abstract class OrdersRemoteDatasource {
  Future<List<OrderModel>> getOrders();
  Future<OrderModel> getOrderById(String id);
  Future<OrderModel> createOrder(CreateOrderParams params);
  Future<CheckoutPreview> previewOrder(CreateOrderParams params);
  Future<PaymentInfo> getPaymentInfo();
  Future<OrderModel> cancelOrder(String id);
  Future<String> uploadReferencePhoto(String filePath);
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

  @override
  Future<CheckoutPreview> previewOrder(CreateOrderParams params) async {
    final response = await _apiClient.post(
      ApiEndpoints.orderPreview,
      data: params.toJson(),
    );
    return CheckoutPreview.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PaymentInfo> getPaymentInfo() async {
    final response = await _apiClient.get(ApiEndpoints.orderPaymentInfo);
    final data = response.data as Map<String, dynamic>;
    return PaymentInfo(
      details: data['details'] as String?,
      qrUrl: data['qrUrl'] as String?,
    );
  }

  @override
  Future<OrderModel> cancelOrder(String id) async {
    final response = await _apiClient.patch('${ApiEndpoints.orders}/$id/cancel');
    return OrderModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<String> uploadReferencePhoto(String filePath) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _apiClient.post(
      ApiEndpoints.referencePhoto,
      data: form,
    );
    return (response.data as Map<String, dynamic>)['url'] as String;
  }
}
