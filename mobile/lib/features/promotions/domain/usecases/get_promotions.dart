import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/promotion.dart';
import '../repositories/promotions_repository.dart';

class GetPromotions {
  final PromotionsRepository repository;

  GetPromotions(this.repository);

  Future<Either<Failure, List<Promotion>>> call() {
    return repository.getPromotions();
  }
}
