import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/address.dart';
import '../entities/create_address_params.dart';
import '../repositories/addresses_repository.dart';

class UpdateAddress {
  final AddressesRepository repository;

  UpdateAddress(this.repository);

  Future<Either<Failure, Address>> call(String id, UpdateAddressParams params) {
    return repository.updateAddress(id, params);
  }
}
