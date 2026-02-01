import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/address.dart';
import '../repositories/addresses_repository.dart';

class GetAddresses {
  final AddressesRepository repository;

  GetAddresses(this.repository);

  Future<Either<Failure, List<Address>>> call() {
    return repository.getAddresses();
  }
}
