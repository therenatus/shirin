import '../../domain/entities/category.dart';

class CategoryModel {
  final String id;
  final String name;
  final String? imageUrl;
  final int productCount;

  const CategoryModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.productCount = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['nameRu'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      productCount: (json['productCount'] as num?)?.toInt() ?? 0,
    );
  }

  Category toEntity() {
    return Category(
      id: id,
      name: name,
      imageUrl: imageUrl,
      productCount: productCount,
    );
  }
}
