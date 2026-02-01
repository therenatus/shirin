import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String? imageUrl;
  final int productCount;

  const Category({
    required this.id,
    required this.name,
    this.imageUrl,
    this.productCount = 0,
  });

  @override
  List<Object?> get props => [id, name, imageUrl, productCount];
}
