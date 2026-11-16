import 'package:dartz/dartz.dart' hide Order;
import '../../../../core/error/failures.dart';
import '../entities/order.dart';
import '../entities/create_order_params.dart';
import '../entities/checkout_preview.dart';

abstract class OrdersRepository {
  Future<Either<Failure, List<Order>>> getOrders();
  Future<Either<Failure, Order>> getOrderById(String id);
  Future<Either<Failure, Order>> createOrder(CreateOrderParams params);
  Future<Either<Failure, CheckoutPreview>> previewOrder(CreateOrderParams params);
  Future<Either<Failure, PaymentInfo>> getPaymentInfo();
  Future<Either<Failure, Order>> cancelOrder(String id);

  /// Uploads a reference photo for a custom cake; returns its URL.
  Future<Either<Failure, String>> uploadReferencePhoto(String filePath);
}
