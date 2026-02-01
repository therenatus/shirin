import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/usecases/get_categories.dart';
import '../../domain/usecases/get_product_by_id.dart';
import '../../domain/usecases/get_products.dart';
import 'products_event.dart';
import 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final GetProducts _getProducts;
  final GetCategories _getCategories;
  final GetProductById _getProductById;

  ProductsBloc({
    required GetProducts getProducts,
    required GetCategories getCategories,
    required GetProductById getProductById,
  })  : _getProducts = getProducts,
        _getCategories = getCategories,
        _getProductById = getProductById,
        super(const ProductsInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<LoadMoreProducts>(_onLoadMoreProducts);
    on<LoadCategories>(_onLoadCategories);
    on<LoadProductDetails>(_onLoadProductDetails);
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductsState> emit,
  ) async {
    emit(const ProductsLoading());
    final result = await _getProducts(
      categoryId: event.categoryId,
      search: event.search,
      sortBy: event.sortBy,
      isNew: event.isNew,
      minPrice: event.minPrice,
      maxPrice: event.maxPrice,
      page: 1,
      limit: AppConstants.defaultPageSize,
    );
    result.fold(
      (failure) => emit(ProductsError(failure.message)),
      (products) => emit(ProductsLoaded(
        products: products,
        hasReachedMax: products.length < AppConstants.defaultPageSize,
        currentPage: 1,
        categoryId: event.categoryId,
        search: event.search,
        sortBy: event.sortBy,
        isNew: event.isNew,
        minPrice: event.minPrice,
        maxPrice: event.maxPrice,
      )),
    );
  }

  Future<void> _onLoadMoreProducts(
    LoadMoreProducts event,
    Emitter<ProductsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProductsLoaded || currentState.hasReachedMax) return;

    final nextPage = currentState.currentPage + 1;
    final result = await _getProducts(
      categoryId: currentState.categoryId,
      search: currentState.search,
      sortBy: currentState.sortBy,
      isNew: currentState.isNew,
      minPrice: currentState.minPrice,
      maxPrice: currentState.maxPrice,
      page: nextPage,
      limit: AppConstants.defaultPageSize,
    );
    result.fold(
      (failure) => emit(ProductsError(failure.message)),
      (products) => emit(currentState.copyWith(
        products: [...currentState.products, ...products],
        hasReachedMax: products.length < AppConstants.defaultPageSize,
        currentPage: nextPage,
      )),
    );
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<ProductsState> emit,
  ) async {
    emit(const CategoriesLoading());
    final result = await _getCategories();
    result.fold(
      (failure) => emit(ProductsError(failure.message)),
      (categories) => emit(CategoriesLoaded(categories)),
    );
  }

  Future<void> _onLoadProductDetails(
    LoadProductDetails event,
    Emitter<ProductsState> emit,
  ) async {
    emit(const ProductDetailsLoading());
    final result = await _getProductById(event.productId);
    result.fold(
      (failure) => emit(ProductDetailsError(failure.message)),
      (product) => emit(ProductDetailsLoaded(product)),
    );
  }
}
