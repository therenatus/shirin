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
  final int? calories;
  final bool isPreorder;
  final int leadTimeHours;
  final int prepaymentPercent;
  final bool allowInscription;
  final bool allowReferencePhoto;

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
    this.calories,
    this.isPreorder = false,
    this.leadTimeHours = 0,
    this.prepaymentPercent = 0,
    this.allowInscription = false,
    this.allowReferencePhoto = false,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Parse price - can be String or num from API
    double parsePrice(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    // `price` is the regular price, `discountPrice` the reduced one the
    // customer actually pays (the server charges discountPrice ?? price)
    final regular = parsePrice(json['price']);
    final discounted =
        json['discountPrice'] == null ? null : parsePrice(json['discountPrice']);
    final hasDiscount = discounted != null && discounted > 0 && discounted < regular;

    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['nameRu'] as String? ?? '',
      description: json['description'] as String? ?? json['descriptionRu'] as String?,
      price: hasDiscount ? discounted : regular,
      oldPrice: hasDiscount ? regular : null,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      categoryId: json['categoryId'] as String?,
      categoryName: json['category']?['name'] as String?,
      isNew: json['isNew'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? true,
      weight: json['weight'] == null ? null : parsePrice(json['weight']),
      composition: json['ingredients'] as String?,
      calories: (json['calories'] as num?)?.toInt(),
      isPreorder: json['isPreorder'] as bool? ?? false,
      leadTimeHours: (json['leadTimeHours'] as num?)?.toInt() ?? 0,
      prepaymentPercent: (json['prepaymentPercent'] as num?)?.toInt() ?? 0,
      allowInscription: json['allowInscription'] as bool? ?? false,
      allowReferencePhoto: json['allowReferencePhoto'] as bool? ?? false,
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
      calories: calories,
      isPreorder: isPreorder,
      leadTimeHours: leadTimeHours,
      prepaymentPercent: prepaymentPercent,
      allowInscription: allowInscription,
      allowReferencePhoto: allowReferencePhoto,
    );
  }
}
