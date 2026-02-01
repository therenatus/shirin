import '../../domain/entities/user.dart';

class UserModel {
  final String id;
  final String phone;
  final String? firstName;
  final String? lastName;
  final String? email;
  final DateTime? birthDate;
  final int loyaltyPoints;
  final String? qrCode;

  const UserModel({
    required this.id,
    required this.phone,
    this.firstName,
    this.lastName,
    this.email,
    this.birthDate,
    this.loyaltyPoints = 0,
    this.qrCode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      phone: json['phone'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      birthDate: json['birthDate'] != null ? DateTime.parse(json['birthDate'] as String) : null,
      loyaltyPoints: (json['loyaltyPoints'] as num?)?.toInt() ?? 0,
      qrCode: json['qrCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'birthDate': birthDate?.toIso8601String(),
      'loyaltyPoints': loyaltyPoints,
      'qrCode': qrCode,
    };
  }

  User toEntity() {
    return User(
      id: id,
      phone: phone,
      firstName: firstName,
      lastName: lastName,
      email: email,
      birthDate: birthDate,
      loyaltyPoints: loyaltyPoints,
      qrCode: qrCode,
    );
  }
}
