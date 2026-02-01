import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../entities/update_profile_params.dart';

abstract class AuthRepository {
  Future<Either<Failure, void>> sendCode(String phone);
  Future<Either<Failure, User>> verifyCode(String phone, String code);
  Future<Either<Failure, User>> getCurrentUser();
  Future<Either<Failure, User>> updateProfile(UpdateProfileParams params);
  Future<Either<Failure, void>> logout();
}
