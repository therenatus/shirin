import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/loyalty_info.dart';
import '../entities/loyalty_transaction.dart';
import '../entities/punch_card.dart';

abstract class LoyaltyRepository {
  Future<Either<Failure, LoyaltyInfo>> getLoyaltyInfo();
  Future<Either<Failure, List<LoyaltyTransaction>>> getLoyaltyHistory();
  Future<Either<Failure, List<PunchCard>>> getPunchCards();
  Future<Either<Failure, PunchCard>> claimFreeCoffee(CoffeeSize size);
}
