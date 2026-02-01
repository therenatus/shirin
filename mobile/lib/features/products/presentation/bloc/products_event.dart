import 'package:equatable/equatable.dart';

abstract class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductsEvent {
  final String? categoryId;
  final String? search;
  final String? sortBy;
  final bool? isNew;
  final double? minPrice;
  final double? maxPrice;

  const LoadProducts({
    this.categoryId,
    this.search,
    this.sortBy,
    this.isNew,
    this.minPrice,
    this.maxPrice,
  });

  @override
  List<Object?> get props => [categoryId, search, sortBy, isNew, minPrice, maxPrice];
}

class LoadMoreProducts extends ProductsEvent {
  const LoadMoreProducts();
}

class LoadCategories extends ProductsEvent {
  const LoadCategories();
}

class LoadProductDetails extends ProductsEvent {
  final String productId;

  const LoadProductDetails(this.productId);

  @override
  List<Object?> get props => [productId];
}
