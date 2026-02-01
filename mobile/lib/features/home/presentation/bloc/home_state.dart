import 'package:equatable/equatable.dart';
import '../../../products/domain/entities/category.dart';
import '../../../products/domain/entities/product.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final List<Category> categories;
  final List<Product> newProducts;
  final List<Product> popularProducts;

  const HomeLoaded({
    required this.categories,
    required this.newProducts,
    required this.popularProducts,
  });

  @override
  List<Object?> get props => [categories, newProducts, popularProducts];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
