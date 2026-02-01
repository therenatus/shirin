import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String phone;
  final String? firstName;
  final String? lastName;
  final String? email;
  final DateTime? birthDate;
  final int loyaltyPoints;
  final String? qrCode;

  const User({
    required this.id,
    required this.phone,
    this.firstName,
    this.lastName,
    this.email,
    this.birthDate,
    this.loyaltyPoints = 0,
    this.qrCode,
  });

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? phone;
  }

  @override
  List<Object?> get props => [id, phone, firstName, lastName, email, birthDate, loyaltyPoints, qrCode];
}
