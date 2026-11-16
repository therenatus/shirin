import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/qr_token.dart';
import '../repositories/loyalty_repository.dart';

class GetQrToken {
  final LoyaltyRepository repository;

  GetQrToken(this.repository);

  Future<Either<Failure, QrToken>> call() {
    return repository.getQrToken();
  }
}
