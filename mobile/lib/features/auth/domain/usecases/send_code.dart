import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class SendCode {
  final AuthRepository repository;

  SendCode(this.repository);

  Future<Either<Failure, void>> call(String phone) {
    return repository.sendCode(phone);
  }
}
