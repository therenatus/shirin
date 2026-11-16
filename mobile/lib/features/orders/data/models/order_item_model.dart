import '../../domain/entities/order_item.dart';

double _num(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;

/// Item of an order as returned by the backend (`formatOrder`):
/// `{id, quantity, price, total, inscription, wishes, referencePhotoUrl,
///   product: {id, name, nameRu, images}}`.
class OrderItemModel {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;
  final String? inscription;
  final String? wishes;
  final String? referencePhotoUrl;

  const OrderItemModel({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.inscription,
    this.wishes,
    this.referencePhotoUrl,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>? ?? const {};
    final images = (product['images'] as List<dynamic>?) ?? const [];
    return OrderItemModel(
      productId: (product['id'] ?? json['productId'] ?? '') as String,
      name: (product['nameRu'] ?? product['name'] ?? json['name'] ?? '') as String,
      price: _num(json['price']),
      quantity: (json['quantity'] as num).toInt(),
      imageUrl: images.isNotEmpty ? images.first as String : null,
      inscription: json['inscription'] as String?,
      wishes: json['wishes'] as String?,
      referencePhotoUrl: json['referencePhotoUrl'] as String?,
    );
  }

  OrderItem toEntity() {
    return OrderItem(
      productId: productId,
      name: name,
      price: price,
      quantity: quantity,
      imageUrl: imageUrl,
      inscription: inscription,
      wishes: wishes,
      referencePhotoUrl: referencePhotoUrl,
    );
  }
}
