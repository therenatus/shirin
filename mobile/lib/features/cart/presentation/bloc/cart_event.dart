import 'package:equatable/equatable.dart';
import '../../../products/domain/entities/product.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class LoadCart extends CartEvent {
  const LoadCart();
}

/// Adds one [product]. With any custom wishes it becomes a separate line.
class AddToCart extends CartEvent {
  final Product product;
  final int quantity;
  final String? inscription;
  final String? wishes;
  final String? referencePhotoUrl;

  const AddToCart(
    this.product, {
    this.quantity = 1,
    this.inscription,
    this.wishes,
    this.referencePhotoUrl,
  });

  @override
  List<Object?> get props =>
      [product, quantity, inscription, wishes, referencePhotoUrl];
}

class RemoveFromCart extends CartEvent {
  final String lineId;

  const RemoveFromCart(this.lineId);

  @override
  List<Object?> get props => [lineId];
}

class UpdateQuantity extends CartEvent {
  final String lineId;
  final int quantity;

  const UpdateQuantity({required this.lineId, required this.quantity});

  @override
  List<Object?> get props => [lineId, quantity];
}

class ClearCart extends CartEvent {
  const ClearCart();
}
