import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/store.dart';
import '../repositories/stores_repository.dart';

class GetStores {
  final StoresRepository repository;

  GetStores(this.repository);

  Future<Either<Failure, List<Store>>> call() {
    return repository.getStores();
  }
}
