import 'package:equatable/equatable.dart';

class Address extends Equatable {
  final String id;
  final String name;
  final String street;
  final String? apartment;
  final String? entrance;
  final String? floor;
  final String? intercom;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  const Address({
    required this.id,
    required this.name,
    required this.street,
    this.apartment,
    this.entrance,
    this.floor,
    this.intercom,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  String get fullAddress {
    final parts = <String>[street];
    if (apartment != null && apartment!.isNotEmpty) {
      parts.add('кв. $apartment');
    }
    if (entrance != null && entrance!.isNotEmpty) {
      parts.add('подъезд $entrance');
    }
    if (floor != null && floor!.isNotEmpty) {
      parts.add('этаж $floor');
    }
    return parts.join(', ');
  }

  @override
  List<Object?> get props => [
        id,
        name,
        street,
        apartment,
        entrance,
        floor,
        intercom,
        latitude,
        longitude,
        isDefault,
      ];
}
