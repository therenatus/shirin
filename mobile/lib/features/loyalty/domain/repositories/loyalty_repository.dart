import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/loyalty_info.dart';
import '../entities/loyalty_transaction.dart';
import '../entities/punch_card.dart';
import '../entities/qr_token.dart';

abstract class LoyaltyRepository {
  Future<Either<Failure, LoyaltyInfo>> getLoyaltyInfo();
  Future<Either<Failure, List<LoyaltyTransaction>>> getLoyaltyHistory();
  Future<Either<Failure, List<PunchCard>>> getPunchCards();
  Future<Either<Failure, QrToken>> getQrToken();
}
