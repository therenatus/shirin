import 'package:dartz/dartz.dart' hide Order;
import '../../../../core/error/failures.dart';
import '../entities/order.dart';
import '../repositories/orders_repository.dart';

class GetOrderById {
  final OrdersRepository repository;

  GetOrderById(this.repository);

  Future<Either<Failure, Order>> call(String id) {
    return repository.getOrderById(id);
  }
}
