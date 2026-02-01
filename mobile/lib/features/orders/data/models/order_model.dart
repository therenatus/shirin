import '../../domain/entities/order.dart';
import 'order_item_model.dart';

class OrderModel {
  final String id;
  final String orderNumber;
  final String status;
  final List<OrderItemModel> items;
  final double totalSum;
  final DateTime createdAt;
  final String? address;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.items,
    required this.totalSum,
    required this.createdAt,
    this.address,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String? ?? json['id'].toString().substring(0, 8).toUpperCase(),
      status: json['status'] as String,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      totalSum: (json['totalSum'] as num?)?.toDouble() ?? (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      address: json['address'] as String?,
    );
  }

  Order toEntity() {
    return Order(
      id: id,
      orderNumber: orderNumber,
      status: _parseStatus(status),
      items: items.map((e) => e.toEntity()).toList(),
      totalSum: totalSum,
      createdAt: createdAt,
      address: address,
    );
  }

  static OrderStatus _parseStatus(String status) {
    switch (status) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}
