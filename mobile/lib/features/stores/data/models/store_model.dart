import '../../domain/entities/store.dart';

class StoreModel {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final double? lat;
  final double? lng;
  final String? workingHours;

  const StoreModel({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.lat,
    this.lng,
    this.workingHours,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      workingHours: json['workingHours'] as String?,
    );
  }

  Store toEntity() {
    return Store(
      id: id,
      name: name,
      address: address,
      phone: phone,
      lat: lat,
      lng: lng,
      workingHours: workingHours,
    );
  }
}
