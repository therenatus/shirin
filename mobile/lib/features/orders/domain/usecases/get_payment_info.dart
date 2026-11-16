import 'package:dartz/dartz.dart' hide Order;
import '../../../../core/error/failures.dart';
import '../entities/checkout_preview.dart';
import '../repositories/orders_repository.dart';

class GetPaymentInfo {
  final OrdersRepository repository;

  GetPaymentInfo(this.repository);

  Future<Either<Failure, PaymentInfo>> call() {
    return repository.getPaymentInfo();
  }
}
