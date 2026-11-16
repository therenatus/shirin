import 'package:equatable/equatable.dart';
import 'order_item.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  delivering,
  delivered,
  cancelled,
}

/// Prepayment for made-to-order items.
enum PaymentStatus { notRequired, pending, paid, refundPending, refunded }

class Order extends Equatable {
  final String id;
  final String orderNumber;
  final OrderStatus status;
  final List<OrderItem> items;

  /// Amount to pay: items + delivery - points.
  final double totalSum;
  final DateTime createdAt;

  /// Delivery address or, for pickup, null (see [storeName]).
  final String? address;
  final bool isDelivery;
  final String? storeName;
  final String? storeAddress;
  final DateTime? deliveryTime;
  final String? comment;
  final double deliveryFee;
  final int pointsUsed;
  final int pointsEarned;
  final PaymentStatus paymentStatus;
  final double prepaymentAmount;
  final DateTime? paymentDueAt;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.items,
    required this.totalSum,
    required this.createdAt,
    this.address,
    this.isDelivery = false,
    this.storeName,
    this.storeAddress,
    this.deliveryTime,
    this.comment,
    this.deliveryFee = 0,
    this.pointsUsed = 0,
    this.pointsEarned = 0,
    this.paymentStatus = PaymentStatus.notRequired,
    this.prepaymentAmount = 0,
    this.paymentDueAt,
  });

  bool get awaitingPayment => paymentStatus == PaymentStatus.pending;

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        status,
        items,
        totalSum,
        createdAt,
        address,
        isDelivery,
        storeName,
        deliveryTime,
        comment,
        paymentStatus,
        prepaymentAmount,
        paymentDueAt,
      ];
}
