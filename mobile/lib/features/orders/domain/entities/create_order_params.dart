import 'package:equatable/equatable.dart';

enum DeliveryType { delivery, pickup }

class CreateOrderItemParams extends Equatable {
  final String productId;
  final int quantity;

  const CreateOrderItemParams({
    required this.productId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'quantity': quantity,
      };

  @override
  List<Object?> get props => [productId, quantity];
}

class CreateOrderParams extends Equatable {
  final List<CreateOrderItemParams> items;
  final DeliveryType deliveryType;
  final String? addressId;
  final String? storeId;
  final DateTime? deliveryTime;
  final String? comment;
  final int? pointsToUse;

  const CreateOrderParams({
    required this.items,
    required this.deliveryType,
    this.addressId,
    this.storeId,
    this.deliveryTime,
    this.comment,
    this.pointsToUse,
  });

  Map<String, dynamic> toJson() => {
        'items': items.map((e) => e.toJson()).toList(),
        'deliveryType': deliveryType == DeliveryType.delivery ? 'delivery' : 'pickup',
        if (addressId != null) 'addressId': addressId,
        if (storeId != null) 'storeId': storeId,
        if (deliveryTime != null) 'deliveryTime': deliveryTime!.toIso8601String(),
        if (comment != null) 'comment': comment,
        if (pointsToUse != null) 'pointsToUse': pointsToUse,
      };

  @override
  List<Object?> get props => [items, deliveryType, addressId, storeId, deliveryTime, comment, pointsToUse];
}
