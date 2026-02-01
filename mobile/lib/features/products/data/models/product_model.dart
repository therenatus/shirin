import '../../domain/entities/product.dart';

class ProductModel {
  final String id;
  final String name;
  final String? description;
  final double price;
  final double? oldPrice;
  final List<String> images;
  final String? categoryId;
  final String? categoryName;
  final bool isNew;
  final bool isAvailable;
  final double? weight;
  final String? composition;

  const ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.oldPrice,
    this.images = const [],
    this.categoryId,
    this.categoryName,
    this.isNew = false,
    this.isAvailable = true,
    this.weight,
    this.composition,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Parse price - can be String or num from API
    double parsePrice(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['nameRu'] as String? ?? '',
      description: json['description'] as String? ?? json['descriptionRu'] as String?,
      price: parsePrice(json['price']),
      oldPrice: parsePrice(json['discountPrice']),
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      categoryId: json['categoryId'] as String?,
      categoryName: json['category']?['name'] as String?,
      isNew: json['isNew'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? true,
      weight: parsePrice(json['weight']),
      composition: json['ingredients'] as String?,
    );
  }

  Product toEntity() {
    return Product(
      id: id,
      name: name,
      description: description,
      price: price,
      oldPrice: oldPrice,
      images: images,
      categoryId: categoryId,
      categoryName: categoryName,
      isNew: isNew,
      isAvailable: isAvailable,
      weight: weight,
      composition: composition,
    );
  }
}
