import 'package:equatable/equatable.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';

abstract class ProductsState extends Equatable {
  const ProductsState();

  @override
  List<Object?> get props => [];
}

class ProductsInitial extends ProductsState {
  const ProductsInitial();
}

class ProductsLoading extends ProductsState {
  const ProductsLoading();
}

class ProductsLoaded extends ProductsState {
  final List<Product> products;
  final bool hasReachedMax;
  final int currentPage;
  final String? categoryId;
  final String? search;
  final String? sortBy;
  final bool? isNew;
  final double? minPrice;
  final double? maxPrice;

  const ProductsLoaded({
    required this.products,
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.categoryId,
    this.search,
    this.sortBy,
    this.isNew,
    this.minPrice,
    this.maxPrice,
  });

  ProductsLoaded copyWith({
    List<Product>? products,
    bool? hasReachedMax,
    int? currentPage,
    String? categoryId,
    String? search,
    String? sortBy,
    bool? isNew,
    double? minPrice,
    double? maxPrice,
  }) {
    return ProductsLoaded(
      products: products ?? this.products,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      categoryId: categoryId ?? this.categoryId,
      search: search ?? this.search,
      sortBy: sortBy ?? this.sortBy,
      isNew: isNew ?? this.isNew,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
    );
  }

  @override
  List<Object?> get props => [products, hasReachedMax, currentPage, categoryId, search];
}

class ProductsError extends ProductsState {
  final String message;

  const ProductsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Categories states
class CategoriesLoading extends ProductsState {
  const CategoriesLoading();
}

class CategoriesLoaded extends ProductsState {
  final List<Category> categories;

  const CategoriesLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

// Product Details states
class ProductDetailsLoading extends ProductsState {
  const ProductDetailsLoading();
}

class ProductDetailsLoaded extends ProductsState {
  final Product product;

  const ProductDetailsLoaded(this.product);

  @override
  List<Object?> get props => [product];
}

class ProductDetailsError extends ProductsState {
  final String message;

  const ProductDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}
