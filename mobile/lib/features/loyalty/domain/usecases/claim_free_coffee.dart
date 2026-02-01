import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/punch_card.dart';
import '../repositories/loyalty_repository.dart';

class ClaimFreeCoffee {
  final LoyaltyRepository _repository;

  ClaimFreeCoffee(this._repository);

  Future<Either<Failure, PunchCard>> call(CoffeeSize size) {
    return _repository.claimFreeCoffee(size);
  }
}
