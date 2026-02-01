import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/addresses_repository.dart';

class DeleteAddress {
  final AddressesRepository repository;

  DeleteAddress(this.repository);

  Future<Either<Failure, void>> call(String id) {
    return repository.deleteAddress(id);
  }
}
