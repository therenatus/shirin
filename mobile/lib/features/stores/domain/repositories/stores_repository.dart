import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/store.dart';

abstract class StoresRepository {
  Future<Either<Failure, List<Store>>> getStores();
}
