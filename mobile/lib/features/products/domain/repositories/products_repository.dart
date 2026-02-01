import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/category.dart';
import '../entities/product.dart';

abstract class ProductsRepository {
  Future<Either<Failure, List<Category>>> getCategories();
  Future<Either<Failure, List<Product>>> getProducts({
    String? categoryId,
    String? search,
    String? sortBy,
    bool? isNew,
    double? minPrice,
    double? maxPrice,
    int page = 1,
    int limit = 20,
  });
  Future<Either<Failure, Product>> getProductById(String id);
}
