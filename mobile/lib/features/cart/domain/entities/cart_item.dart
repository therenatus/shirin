import 'package:equatable/equatable.dart';
import '../../../products/domain/entities/product.dart';

/// A line in the cart.
///
/// Plain items are one line per product ([lineId] == product id). A custom
/// cake with an inscription, wishes or a photo is its own line, so two cakes
/// with different inscriptions stay separate.
class CartItem extends Equatable {
  final String lineId;
  final Product product;
  final int quantity;
  final String? inscription;
  final String? wishes;
  final String? referencePhotoUrl;

  const CartItem({
    required this.lineId,
    required this.product,
    this.quantity = 1,
    this.inscription,
    this.wishes,
    this.referencePhotoUrl,
  });

  bool get isCustomised =>
      (inscription?.isNotEmpty ?? false) ||
      (wishes?.isNotEmpty ?? false) ||
      referencePhotoUrl != null;

  double get totalPrice => product.price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      lineId: lineId,
      product: product,
      quantity: quantity ?? this.quantity,
      inscription: inscription,
      wishes: wishes,
      referencePhotoUrl: referencePhotoUrl,
    );
  }

  @override
  List<Object?> get props =>
      [lineId, product.id, quantity, inscription, wishes, referencePhotoUrl];
}
