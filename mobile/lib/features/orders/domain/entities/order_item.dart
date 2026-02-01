import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  double get total => price * quantity;

  @override
  List<Object?> get props => [productId, name, price, quantity, imageUrl];
}
