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
    final customised = (event.inscription?.isNotEmpty ?? false) ||
        (event.wishes?.isNotEmpty ?? false) ||
        event.referencePhotoUrl != null;
    // Plain items merge into one line per product; custom ones never merge
    final existingIndex = customised
        ? -1
        : currentItems.indexWhere((item) => item.lineId == event.product.id);

    List<CartItem> updatedItems;
    if (existingIndex >= 0) {
      updatedItems = List.from(currentItems);
      updatedItems[existingIndex] = currentItems[existingIndex].copyWith(
        quantity: currentItems[existingIndex].quantity + event.quantity,
      );
    } else {
      updatedItems = [
        ...currentItems,
        CartItem(
          lineId: customised
              ? '${event.product.id}#${DateTime.now().microsecondsSinceEpoch}'
              : event.product.id,
          product: event.product,
          quantity: event.quantity,
          inscription: event.inscription,
          wishes: event.wishes,
          referencePhotoUrl: event.referencePhotoUrl,
        ),
      ];
    }

    await _localDatasource.saveCartItems(updatedItems);
    emit(CartLoaded(items: updatedItems));
  }

  Future<void> _onRemoveFromCart(
      RemoveFromCart event, Emitter<CartState> emit) async {
    final currentItems = _getCurrentItems();
    final updatedItems =
        currentItems.where((item) => item.lineId != event.lineId).toList();
    await _localDatasource.saveCartItems(updatedItems);
    emit(CartLoaded(items: updatedItems));
  }

  Future<void> _onUpdateQuantity(
      UpdateQuantity event, Emitter<CartState> emit) async {
    final currentItems = _getCurrentItems();
    if (event.quantity <= 0) {
      final updatedItems =
          currentItems.where((item) => item.lineId != event.lineId).toList();
      await _localDatasource.saveCartItems(updatedItems);
      emit(CartLoaded(items: updatedItems));
      return;
    }

    final updatedItems = currentItems.map((item) {
      if (item.lineId == event.lineId) {
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
