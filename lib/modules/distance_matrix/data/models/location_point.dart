import 'package:equatable/equatable.dart';

class LocationPoint extends Equatable {
  const LocationPoint({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  final double latitude;
  final double longitude;
  final String? address;

  String get latLngString => '$latitude,$longitude';

  LocationPoint copyWith({
    double? latitude,
    double? longitude,
    String? address,
  }) {
    return LocationPoint(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
    );
  }

  @override
  List<Object?> get props => [latitude, longitude, address];
}
