import 'package:equatable/equatable.dart';
import 'order_item.dart';

enum OrderStatus { pending, confirmed, preparing, ready, delivered, cancelled }

class Order extends Equatable {
  final String id;
  final String orderNumber;
  final OrderStatus status;
  final List<OrderItem> items;
  final double totalSum;
  final DateTime createdAt;
  final String? address;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.items,
    required this.totalSum,
    required this.createdAt,
    this.address,
  });

  @override
  List<Object?> get props => [id, orderNumber, status, items, totalSum, createdAt, address];
}
