import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/address.dart';
import '../entities/create_address_params.dart';

abstract class AddressesRepository {
  Future<Either<Failure, List<Address>>> getAddresses();
  Future<Either<Failure, Address>> getAddressById(String id);
  Future<Either<Failure, Address>> createAddress(CreateAddressParams params);
  Future<Either<Failure, Address>> updateAddress(String id, UpdateAddressParams params);
  Future<Either<Failure, void>> deleteAddress(String id);
  Future<Either<Failure, Address>> setDefaultAddress(String id);
}
