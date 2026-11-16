import 'package:equatable/equatable.dart';

/// What the order would cost, calculated by the server (`POST /orders/preview`).
class CheckoutPreview extends Equatable {
  final double subtotal;
  final double deliveryFee;
  final int pointsUsed;

  /// Most points that can be spent on this order.
  final int maxPoints;
  final double total;
  final int pointsEarned;
  final double prepaymentAmount;

  /// Earliest date/time for made-to-order items; null if none in the cart.
  final DateTime? earliestTime;
  final int paymentTimeoutMinutes;

  const CheckoutPreview({
    required this.subtotal,
    required this.deliveryFee,
    required this.pointsUsed,
    required this.maxPoints,
    required this.total,
    required this.pointsEarned,
    required this.prepaymentAmount,
    required this.earliestTime,
    required this.paymentTimeoutMinutes,
  });

  factory CheckoutPreview.fromJson(Map<String, dynamic> json) {
    double n(dynamic v) => (v as num?)?.toDouble() ?? 0;
    final earliest = json['earliestTime'] as String?;
    return CheckoutPreview(
      subtotal: n(json['subtotal']),
      deliveryFee: n(json['deliveryFee']),
      pointsUsed: (json['pointsUsed'] as num?)?.toInt() ?? 0,
      maxPoints: (json['maxPoints'] as num?)?.toInt() ?? 0,
      total: n(json['total']),
      pointsEarned: (json['pointsEarned'] as num?)?.toInt() ?? 0,
      prepaymentAmount: n(json['prepaymentAmount']),
      earliestTime: earliest == null ? null : DateTime.parse(earliest).toLocal(),
      paymentTimeoutMinutes: (json['paymentTimeoutMinutes'] as num?)?.toInt() ?? 60,
    );
  }

  @override
  List<Object?> get props => [
        subtotal,
        deliveryFee,
        pointsUsed,
        maxPoints,
        total,
        pointsEarned,
        prepaymentAmount,
        earliestTime,
      ];
}

/// Company payment details for the prepayment (`GET /orders/payment-info`).
class PaymentInfo extends Equatable {
  final String? details;
  final String? qrUrl;

  const PaymentInfo({this.details, this.qrUrl});

  @override
  List<Object?> get props => [details, qrUrl];
}
