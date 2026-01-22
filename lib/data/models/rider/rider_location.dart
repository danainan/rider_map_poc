import 'package:equatable/equatable.dart';

/// Rider location model
class RiderLocation extends Equatable {
  const RiderLocation({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.heading,
    this.speed,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? heading;
  final double? speed;

  RiderLocation copyWith({
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    double? heading,
    double? speed,
  }) {
    return RiderLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
    );
  }

  factory RiderLocation.fromJson(Map<String, dynamic> json) {
    return RiderLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      heading: (json['heading'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'heading': heading,
      'speed': speed,
    };
  }

  @override
  List<Object?> get props => [latitude, longitude, timestamp, heading, speed];
}
