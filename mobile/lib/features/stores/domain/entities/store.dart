import 'package:equatable/equatable.dart';

class Store extends Equatable {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final double? lat;
  final double? lng;
  final String? workingHours;

  const Store({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.lat,
    this.lng,
    this.workingHours,
  });

  @override
  List<Object?> get props => [id, name, address, phone, lat, lng, workingHours];
}
