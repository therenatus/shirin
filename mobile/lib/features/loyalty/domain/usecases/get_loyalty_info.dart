import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/loyalty_info.dart';
import '../repositories/loyalty_repository.dart';

class GetLoyaltyInfo {
  final LoyaltyRepository repository;

  GetLoyaltyInfo(this.repository);

  Future<Either<Failure, LoyaltyInfo>> call() {
    return repository.getLoyaltyInfo();
  }
}
