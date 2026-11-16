import 'package:dartz/dartz.dart' hide Order;
import '../../../../core/error/failures.dart';
import '../entities/order.dart';
import '../repositories/orders_repository.dart';

class CancelOrder {
  final OrdersRepository repository;

  CancelOrder(this.repository);

  Future<Either<Failure, Order>> call(String id) {
    return repository.cancelOrder(id);
  }
}
