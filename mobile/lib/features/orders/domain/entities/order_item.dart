import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;

  /// Custom-cake wishes, if any.
  final String? inscription;
  final String? wishes;
  final String? referencePhotoUrl;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.inscription,
    this.wishes,
    this.referencePhotoUrl,
  });

  double get total => price * quantity;

  @override
  List<Object?> get props =>
      [productId, name, price, quantity, imageUrl, inscription, wishes, referencePhotoUrl];
}
