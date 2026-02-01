import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class VerifyCode {
  final AuthRepository repository;

  VerifyCode(this.repository);

  Future<Either<Failure, User>> call(String phone, String code) {
    return repository.verifyCode(phone, code);
  }
}
