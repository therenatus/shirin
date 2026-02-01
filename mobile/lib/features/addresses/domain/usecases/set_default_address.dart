import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/address.dart';
import '../repositories/addresses_repository.dart';

class SetDefaultAddress {
  final AddressesRepository repository;

  SetDefaultAddress(this.repository);

  Future<Either<Failure, Address>> call(String id) {
    return repository.setDefaultAddress(id);
  }
}
