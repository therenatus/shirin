import 'package:equatable/equatable.dart';

class Product extends Equatable {
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

  const Product({
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

  bool get hasDiscount => oldPrice != null && oldPrice! > price;

  double get discountPercent {
    if (!hasDiscount) return 0;
    return ((oldPrice! - price) / oldPrice! * 100).roundToDouble();
  }

  String get mainImage => images.isNotEmpty ? images.first : '';

  @override
  List<Object?> get props => [id, name, price, categoryId, isNew, isAvailable];
}
