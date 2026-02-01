import 'package:dartz/dartz.dart' hide Order;
import '../../../../core/error/failures.dart';
import '../entities/order.dart';
import '../entities/create_order_params.dart';
import '../repositories/orders_repository.dart';

class CreateOrder {
  final OrdersRepository repository;

  CreateOrder(this.repository);

  Future<Either<Failure, Order>> call(CreateOrderParams params) {
    return repository.createOrder(params);
  }
}
