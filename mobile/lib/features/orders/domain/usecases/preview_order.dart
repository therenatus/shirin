import 'package:dartz/dartz.dart' hide Order;
import '../../../../core/error/failures.dart';
import '../entities/checkout_preview.dart';
import '../entities/create_order_params.dart';
import '../repositories/orders_repository.dart';

class PreviewOrder {
  final OrdersRepository repository;

  PreviewOrder(this.repository);

  Future<Either<Failure, CheckoutPreview>> call(CreateOrderParams params) {
    return repository.previewOrder(params);
  }
}
