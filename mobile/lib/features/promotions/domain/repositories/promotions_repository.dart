import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/promotion.dart';

abstract class PromotionsRepository {
  Future<Either<Failure, List<Promotion>>> getPromotions();
}
