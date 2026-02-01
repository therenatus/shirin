import 'package:equatable/equatable.dart';

class LoyaltyInfo extends Equatable {
  final int points;
  final String? qrCode;
  final String level;

  const LoyaltyInfo({
    required this.points,
    this.qrCode,
    required this.level,
  });

  @override
  List<Object?> get props => [points, qrCode, level];
}
