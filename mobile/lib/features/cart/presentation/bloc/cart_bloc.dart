import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/cart_local_datasource.dart';
import '../../domain/entities/cart_item.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final CartLocalDatasource _localDatasource;

  CartBloc(this._localDatasource) : super(const CartInitial()) {
    on<LoadCart>(_onLoadCart);
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<UpdateQuantity>(_onUpdateQuantity);
    on<ClearCart>(_onClearCart);
  }

  Future<void> _onLoadCart(LoadCart event, Emitter<CartState> emit) async {
    final items = await _localDatasource.getCartItems();
    emit(CartLoaded(items: items));
  }

  Future<void> _onAddToCart(AddToCart event, Emitter<CartState> emit) async {
    final currentItems = _getCurrentItems();
    final existingIndex =
        currentItems.indexWhere((item) => item.product.id == event.product.id);

    List<CartItem> updatedItems;
    if (existingIndex >= 0) {
      updatedItems = List.from(currentItems);
      updatedItems[existingIndex] = currentItems[existingIndex].copyWith(
        quantity: currentItems[existingIndex].quantity + 1,
      );
    } else {
      updatedItems = [...currentItems, CartItem(product: event.product)];
    }

    await _localDatasource.saveCartItems(updatedItems);
    emit(CartLoaded(items: updatedItems));
  }

  Future<void> _onRemoveFromCart(
      RemoveFromCart event, Emitter<CartState> emit) async {
    final currentItems = _getCurrentItems();
    final updatedItems =
        currentItems.where((item) => item.product.id != event.productId).toList();
    await _localDatasource.saveCartItems(updatedItems);
    emit(CartLoaded(items: updatedItems));
  }

  Future<void> _onUpdateQuantity(
      UpdateQuantity event, Emitter<CartState> emit) async {
    final currentItems = _getCurrentItems();
    if (event.quantity <= 0) {
      final updatedItems =
          currentItems.where((item) => item.product.id != event.productId).toList();
      await _localDatasource.saveCartItems(updatedItems);
      emit(CartLoaded(items: updatedItems));
      return;
    }

    final updatedItems = currentItems.map((item) {
      if (item.product.id == event.productId) {
        return item.copyWith(quantity: event.quantity);
      }
      return item;
    }).toList();

    await _localDatasource.saveCartItems(updatedItems);
    emit(CartLoaded(items: updatedItems));
  }

  Future<void> _onClearCart(ClearCart event, Emitter<CartState> emit) async {
    await _localDatasource.clearCart();
    emit(const CartLoaded(items: []));
  }

  List<CartItem> _getCurrentItems() {
    final currentState = state;
    if (currentState is CartLoaded) return currentState.items;
    return [];
  }
}
