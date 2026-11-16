import '../../domain/entities/order.dart';
import 'order_item_model.dart';

double _num(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;

DateTime? _date(dynamic v) =>
    v is String ? DateTime.tryParse(v)?.toLocal() : null;

/// Order as returned by the backend (`formatOrder` in orders.service.ts).
class OrderModel {
  final String id;
  final String orderNumber;
  final String status;
  final List<OrderItemModel> items;
  final double totalSum;
  final DateTime createdAt;
  final String? address;
  final bool isDelivery;
  final String? storeName;
  final String? storeAddress;
  final DateTime? deliveryTime;
  final String? comment;
  final double deliveryFee;
  final int pointsUsed;
  final int pointsEarned;
  final String paymentStatus;
  final double prepaymentAmount;
  final DateTime? paymentDueAt;

  const OrderModel({
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
    this.paymentStatus = 'NOT_REQUIRED',
    this.prepaymentAmount = 0,
    this.paymentDueAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final address = json['address'];
    final store = json['store'] as Map<String, dynamic>?;
    return OrderModel(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String? ?? '',
      status: json['status'] as String,
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalSum: _num(json['total']),
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      address: address is Map<String, dynamic>
          ? [
              address['street'],
              if (address['apartment'] != null) 'кв. ${address['apartment']}',
            ].whereType<String>().join(', ')
          : address as String?,
      isDelivery: json['deliveryType'] == 'delivery',
      storeName: store?['name'] as String?,
      storeAddress: store?['address'] as String?,
      deliveryTime: _date(json['deliveryTime']),
      comment: json['comment'] as String?,
      deliveryFee: _num(json['deliveryFee']),
      pointsUsed: (json['pointsUsed'] as num?)?.toInt() ?? 0,
      pointsEarned: (json['pointsEarned'] as num?)?.toInt() ?? 0,
      paymentStatus: json['paymentStatus'] as String? ?? 'NOT_REQUIRED',
      prepaymentAmount: _num(json['prepaymentAmount']),
      paymentDueAt: _date(json['paymentDueAt']),
    );
  }

  Order toEntity() {
    return Order(
      id: id,
      orderNumber: orderNumber,
      status: parseStatus(status),
      items: items.map((e) => e.toEntity()).toList(),
      totalSum: totalSum,
      createdAt: createdAt,
      address: address,
      isDelivery: isDelivery,
      storeName: storeName,
      storeAddress: storeAddress,
      deliveryTime: deliveryTime,
      comment: comment,
      deliveryFee: deliveryFee,
      pointsUsed: pointsUsed,
      pointsEarned: pointsEarned,
      paymentStatus: parsePaymentStatus(paymentStatus),
      prepaymentAmount: prepaymentAmount,
      paymentDueAt: paymentDueAt,
    );
  }

  /// The backend sends statuses in upper case (PENDING, CONFIRMED, ...).
  static OrderStatus parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return OrderStatus.confirmed;
      case 'PREPARING':
        return OrderStatus.preparing;
      case 'READY':
        return OrderStatus.ready;
      case 'DELIVERING':
        return OrderStatus.delivering;
      case 'DELIVERED':
        return OrderStatus.delivered;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  static PaymentStatus parsePaymentStatus(String status) {
    switch (status) {
      case 'PENDING':
        return PaymentStatus.pending;
      case 'PAID':
        return PaymentStatus.paid;
      case 'REFUND_PENDING':
        return PaymentStatus.refundPending;
      case 'REFUNDED':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.notRequired;
    }
  }
}
