import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/punch_card.dart';
import '../repositories/loyalty_repository.dart';

class GetPunchCards {
  final LoyaltyRepository _repository;

  GetPunchCards(this._repository);

  Future<Either<Failure, List<PunchCard>>> call() {
    return _repository.getPunchCards();
  }
}
