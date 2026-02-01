import '../../domain/entities/address.dart';

class AddressModel {
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

  const AddressModel({
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

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String,
      name: json['name'] as String,
      street: json['street'] as String,
      apartment: json['apartment'] as String?,
      entrance: json['entrance'] as String?,
      floor: json['floor'] as String?,
      intercom: json['intercom'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'street': street,
        'apartment': apartment,
        'entrance': entrance,
        'floor': floor,
        'intercom': intercom,
        'latitude': latitude,
        'longitude': longitude,
        'isDefault': isDefault,
      };

  Address toEntity() {
    return Address(
      id: id,
      name: name,
      street: street,
      apartment: apartment,
      entrance: entrance,
      floor: floor,
      intercom: intercom,
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault,
    );
  }
}
