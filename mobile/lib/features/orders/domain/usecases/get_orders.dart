import 'package:dartz/dartz.dart' hide Order;
import '../../../../core/error/failures.dart';
import '../entities/order.dart';
import '../repositories/orders_repository.dart';

class GetOrders {
  final OrdersRepository repository;

  GetOrders(this.repository);

  Future<Either<Failure, List<Order>>> call() {
    return repository.getOrders();
  }
}
