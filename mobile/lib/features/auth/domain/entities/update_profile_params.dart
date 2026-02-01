import 'package:equatable/equatable.dart';

class UpdateProfileParams extends Equatable {
  final String? firstName;
  final String? lastName;
  final String? email;
  final DateTime? birthDate;

  const UpdateProfileParams({
    this.firstName,
    this.lastName,
    this.email,
    this.birthDate,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (firstName != null) json['firstName'] = firstName;
    if (lastName != null) json['lastName'] = lastName;
    if (email != null) json['email'] = email;
    if (birthDate != null) json['birthDate'] = birthDate!.toIso8601String().split('T').first;
    return json;
  }

  @override
  List<Object?> get props => [firstName, lastName, email, birthDate];
}
