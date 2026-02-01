import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/product.dart';
import '../repositories/products_repository.dart';

class GetProducts {
  final ProductsRepository repository;

  GetProducts(this.repository);

  Future<Either<Failure, List<Product>>> call({
    String? categoryId,
    String? search,
    String? sortBy,
    bool? isNew,
    double? minPrice,
    double? maxPrice,
    int page = 1,
    int limit = 20,
  }) {
    return repository.getProducts(
      categoryId: categoryId,
      search: search,
      sortBy: sortBy,
      isNew: isNew,
      minPrice: minPrice,
      maxPrice: maxPrice,
      page: page,
      limit: limit,
    );
  }
}
