import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/loyalty_transaction.dart';
import '../repositories/loyalty_repository.dart';

class GetLoyaltyHistory {
  final LoyaltyRepository repository;

  GetLoyaltyHistory(this.repository);

  Future<Either<Failure, List<LoyaltyTransaction>>> call() {
    return repository.getLoyaltyHistory();
  }
}
