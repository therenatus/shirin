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

    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((item) {
      final map = item as Map<String, dynamic>;
      return CartItem(
        product: Product(
          id: map['id'] as String,
          name: map['name'] as String,
          price: (map['price'] as num).toDouble(),
          oldPrice: (map['oldPrice'] as num?)?.toDouble(),
          images: (map['images'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [],
          categoryId: map['categoryId'] as String?,
          isNew: map['isNew'] as bool? ?? false,
        ),
        quantity: map['quantity'] as int? ?? 1,
      );
    }).toList();
  }

  Future<void> saveCartItems(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((item) => {
          'id': item.product.id,
          'name': item.product.name,
          'price': item.product.price,
          'oldPrice': item.product.oldPrice,
          'images': item.product.images,
          'categoryId': item.product.categoryId,
          'isNew': item.product.isNew,
          'quantity': item.quantity,
        }).toList();
    await prefs.setString(_cartKey, json.encode(jsonList));
  }

  Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }
}
