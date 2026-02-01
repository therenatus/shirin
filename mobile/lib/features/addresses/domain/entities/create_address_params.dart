import 'package:equatable/equatable.dart';

class CreateAddressParams extends Equatable {
  final String name;
  final String street;
  final String? apartment;
  final String? entrance;
  final String? floor;
  final String? intercom;
  final double? latitude;
  final double? longitude;
  final bool? isDefault;

  const CreateAddressParams({
    required this.name,
    required this.street,
    this.apartment,
    this.entrance,
    this.floor,
    this.intercom,
    this.latitude,
    this.longitude,
    this.isDefault,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'street': street,
        if (apartment != null) 'apartment': apartment,
        if (entrance != null) 'entrance': entrance,
        if (floor != null) 'floor': floor,
        if (intercom != null) 'intercom': intercom,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (isDefault != null) 'isDefault': isDefault,
      };

  @override
  List<Object?> get props => [
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

class UpdateAddressParams extends Equatable {
  final String? name;
  final String? street;
  final String? apartment;
  final String? entrance;
  final String? floor;
  final String? intercom;
  final double? latitude;
  final double? longitude;

  const UpdateAddressParams({
    this.name,
    this.street,
    this.apartment,
    this.entrance,
    this.floor,
    this.intercom,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (name != null) json['name'] = name;
    if (street != null) json['street'] = street;
    if (apartment != null) json['apartment'] = apartment;
    if (entrance != null) json['entrance'] = entrance;
    if (floor != null) json['floor'] = floor;
    if (intercom != null) json['intercom'] = intercom;
    if (latitude != null) json['latitude'] = latitude;
    if (longitude != null) json['longitude'] = longitude;
    return json;
  }

  @override
  List<Object?> get props => [
        name,
        street,
        apartment,
        entrance,
        floor,
        intercom,
        latitude,
        longitude,
      ];
}
