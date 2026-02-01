import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../products/domain/usecases/get_categories.dart';
import '../../../products/domain/usecases/get_products.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetCategories _getCategories;
  final GetProducts _getProducts;

  HomeBloc({
    required GetCategories getCategories,
    required GetProducts getProducts,
  })  : _getCategories = getCategories,
        _getProducts = getProducts,
        super(const HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
  }

  Future<void> _onLoadHomeData(
    LoadHomeData event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());

    final categoriesResult = await _getCategories();
    final newProductsResult = await _getProducts(isNew: true, limit: 10);
    final popularResult = await _getProducts(sortBy: 'popular', limit: 10);

    categoriesResult.fold(
      (failure) => emit(HomeError(failure.message)),
      (categories) {
        final newProducts = newProductsResult.fold(
          (_) => <dynamic>[],
          (products) => products,
        );
        final popular = popularResult.fold(
          (_) => <dynamic>[],
          (products) => products,
        );
        emit(HomeLoaded(
          categories: categories,
          newProducts: List.from(newProducts),
          popularProducts: List.from(popular),
        ));
      },
    );
  }
}
