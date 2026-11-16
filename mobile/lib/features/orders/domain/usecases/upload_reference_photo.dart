import 'package:dartz/dartz.dart' hide Order;
import '../../../../core/error/failures.dart';

import '../repositories/orders_repository.dart';

class UploadReferencePhoto {
  final OrdersRepository repository;

  UploadReferencePhoto(this.repository);

  Future<Either<Failure, String>> call(String filePath) {
    return repository.uploadReferencePhoto(filePath);
  }
}
