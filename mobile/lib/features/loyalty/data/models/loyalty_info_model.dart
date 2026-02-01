import '../../domain/entities/loyalty_info.dart';

class LoyaltyInfoModel {
  final int points;
  final String? qrCode;
  final String level;

  const LoyaltyInfoModel({
    required this.points,
    this.qrCode,
    required this.level,
  });

  factory LoyaltyInfoModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyInfoModel(
      points: (json['points'] as num?)?.toInt() ?? 0,
      qrCode: json['qrCode'] as String?,
      level: json['level'] as String? ?? 'Bronze',
    );
  }

  LoyaltyInfo toEntity() {
    return LoyaltyInfo(
      points: points,
      qrCode: qrCode,
      level: level,
    );
  }
}
