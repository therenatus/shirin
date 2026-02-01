import '../../domain/entities/punch_card.dart';

class PunchCardModel {
  final String id;
  final String size;
  final String sizeName;
  final int currentPunches;
  final int maxPunches;
  final bool isComplete;
  final bool freeItemClaimed;
  final DateTime createdAt;
  final DateTime? completedAt;

  const PunchCardModel({
    required this.id,
    required this.size,
    required this.sizeName,
    required this.currentPunches,
    required this.maxPunches,
    required this.isComplete,
    required this.freeItemClaimed,
    required this.createdAt,
    this.completedAt,
  });

  factory PunchCardModel.fromJson(Map<String, dynamic> json) {
    return PunchCardModel(
      id: json['id'] as String,
      size: json['size'] as String,
      sizeName: json['sizeName'] as String,
      currentPunches: (json['currentPunches'] as num).toInt(),
      maxPunches: (json['maxPunches'] as num).toInt(),
      isComplete: json['isComplete'] as bool,
      freeItemClaimed: json['freeItemClaimed'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  PunchCard toEntity() {
    return PunchCard(
      id: id,
      size: _parseCoffeeSize(size),
      sizeName: sizeName,
      currentPunches: currentPunches,
      maxPunches: maxPunches,
      isComplete: isComplete,
      freeItemClaimed: freeItemClaimed,
      createdAt: createdAt,
      completedAt: completedAt,
    );
  }

  static CoffeeSize _parseCoffeeSize(String size) {
    switch (size) {
      case 'S':
        return CoffeeSize.S;
      case 'M':
        return CoffeeSize.M;
      case 'L':
        return CoffeeSize.L;
      default:
        return CoffeeSize.M;
    }
  }
}
