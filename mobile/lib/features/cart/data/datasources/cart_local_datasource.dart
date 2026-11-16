import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../products/domain/entities/product.dart';
import '../../domain/entities/cart_item.dart';

class CartLocalDatasource {
  static const String _cartKey = 'cart_items';

  Future<List<CartItem>> getCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_cartKey);
    if (data == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(data);
      return jsonList.map((item) {
        final map = item as Map<String, dynamic>;
        final productId = map['id'] as String;
        return CartItem(
          // Carts saved before custom lines existed have no lineId
          lineId: map['lineId'] as String? ?? productId,
          product: Product(
            id: productId,
            name: map['name'] as String,
            price: (map['price'] as num).toDouble(),
            oldPrice: (map['oldPrice'] as num?)?.toDouble(),
            images: (map['images'] as List<dynamic>?)
                    ?.map((e) => e as String)
                    .toList() ??
                [],
            categoryId: map['categoryId'] as String?,
            isNew: map['isNew'] as bool? ?? false,
            isPreorder: map['isPreorder'] as bool? ?? false,
            leadTimeHours: map['leadTimeHours'] as int? ?? 0,
            prepaymentPercent: map['prepaymentPercent'] as int? ?? 0,
            allowInscription: map['allowInscription'] as bool? ?? false,
            allowReferencePhoto: map['allowReferencePhoto'] as bool? ?? false,
          ),
          quantity: map['quantity'] as int? ?? 1,
          inscription: map['inscription'] as String?,
          wishes: map['wishes'] as String?,
          referencePhotoUrl: map['referencePhotoUrl'] as String?,
        );
      }).toList();
    } catch (_) {
      // A corrupted cart must not break the app
      await clearCart();
      return [];
    }
  }

  Future<void> saveCartItems(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items
        .map((item) => {
              'lineId': item.lineId,
              'id': item.product.id,
              'name': item.product.name,
              'price': item.product.price,
              'oldPrice': item.product.oldPrice,
              'images': item.product.images,
              'categoryId': item.product.categoryId,
              'isNew': item.product.isNew,
              'isPreorder': item.product.isPreorder,
              'leadTimeHours': item.product.leadTimeHours,
              'prepaymentPercent': item.product.prepaymentPercent,
              'allowInscription': item.product.allowInscription,
              'allowReferencePhoto': item.product.allowReferencePhoto,
              'quantity': item.quantity,
              'inscription': item.inscription,
              'wishes': item.wishes,
              'referencePhotoUrl': item.referencePhotoUrl,
            })
        .toList();
    await prefs.setString(_cartKey, json.encode(jsonList));
  }

  Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }
}
