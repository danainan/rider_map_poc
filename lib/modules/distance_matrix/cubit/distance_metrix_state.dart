part of 'distance_metrix_cubit.dart';

enum DistanceMetrixStatus {
  initial,
  loading,
  success,
  failure,
}

final class DistanceMetrixState extends Equatable {
  const DistanceMetrixState({
    this.status = DistanceMetrixStatus.initial,
    this.distanceMatrix = DistanceMatrixResponse.empty,
    this.locations = const [],
    this.totalDistance = 0,
    this.totalDuration = 0,
    this.errorMessage,
  });

  final DistanceMetrixStatus status;
  final DistanceMatrixResponse distanceMatrix;
  final List<LocationPoint> locations;
  final double totalDistance; // in meters
  final int totalDuration; // in seconds
  final String? errorMessage;

  bool get hasLocations => locations.length >= 2;
  bool get canCalculate => locations.length >= 2 && 
      locations.every((loc) => loc.latitude != 0 && loc.longitude != 0);

  String get formattedDistance {
    if (totalDistance < 1000) {
      return '${totalDistance.toStringAsFixed(0)} m';
    }
    return '${(totalDistance / 1000).toStringAsFixed(2)} km';
  }

  String get formattedDuration {
    final hours = totalDuration ~/ 3600;
    final minutes = (totalDuration % 3600) ~/ 60;
    
    if (hours > 0) {
      return '$hours ชม. $minutes นาที';
    }
    return '$minutes นาที';
  }

  DistanceMetrixState copyWith({
    DistanceMetrixStatus? status,
    DistanceMatrixResponse? distanceMatrix,
    List<LocationPoint>? locations,
    double? totalDistance,
    int? totalDuration,
    String? errorMessage,
  }) {
    return DistanceMetrixState(
      status: status ?? this.status,
      distanceMatrix: distanceMatrix ?? this.distanceMatrix,
      locations: locations ?? this.locations,
      totalDistance: totalDistance ?? this.totalDistance,
      totalDuration: totalDuration ?? this.totalDuration,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    distanceMatrix,
    locations,
    totalDistance,
    totalDuration,
    errorMessage,
  ];
}

