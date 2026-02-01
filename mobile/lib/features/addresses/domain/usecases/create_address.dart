import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/address.dart';
import '../entities/create_address_params.dart';
import '../repositories/addresses_repository.dart';

class CreateAddress {
  final AddressesRepository repository;

  CreateAddress(this.repository);

  Future<Either<Failure, Address>> call(CreateAddressParams params) {
    return repository.createAddress(params);
  }
}
