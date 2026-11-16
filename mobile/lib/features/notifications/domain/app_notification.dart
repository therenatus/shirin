import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  final String id;
  final String title;
  final String body;

  /// order_status, payment, loyalty, promo
  final String type;

  /// Order to open on tap, if the notification is about an order.
  final String? orderId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.orderId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      orderId: data?['orderId'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }

  AppNotification read() => AppNotification(
    id: id,
    title: title,
    body: body,
    type: type,
    orderId: orderId,
    isRead: true,
    createdAt: createdAt,
  );

  @override
  List<Object?> get props => [id, isRead];
}
