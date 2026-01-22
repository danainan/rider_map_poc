import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Rider delivery status
enum RiderStatus {
  idle,
  headingToPickup,
  arrivedAtPickup,
  headingToDelivery,
  delivered,
}

/// State for RiderMapBloc
class RiderMapState extends Equatable {
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final LatLng riderPosition;
  final LatLng? cameraTarget;
  final double cameraZoom;
  final RiderStatus riderStatus;
  final bool isSimulationRunning;
  final bool isFollowingRider;
  final int currentRouteIndex;
  final bool isMapReady;
  final String estimatedTime;
  final String estimatedDistance;

  const RiderMapState({
    this.markers = const {},
    this.polylines = const {},
    this.riderPosition = const LatLng(13.7433, 100.5311),
    this.cameraTarget,
    this.cameraZoom = 15.0,
    this.riderStatus = RiderStatus.idle,
    this.isSimulationRunning = false,
    this.isFollowingRider = true,
    this.currentRouteIndex = 0,
    this.isMapReady = false,
    this.estimatedTime = '8 mins',
    this.estimatedDistance = '1.2 km',
  });

  RiderMapState copyWith({
    Set<Marker>? markers,
    Set<Polyline>? polylines,
    LatLng? riderPosition,
    LatLng? cameraTarget,
    double? cameraZoom,
    RiderStatus? riderStatus,
    bool? isSimulationRunning,
    bool? isFollowingRider,
    int? currentRouteIndex,
    bool? isMapReady,
    String? estimatedTime,
    String? estimatedDistance,
  }) {
    return RiderMapState(
      markers: markers ?? this.markers,
      polylines: polylines ?? this.polylines,
      riderPosition: riderPosition ?? this.riderPosition,
      cameraTarget: cameraTarget ?? this.cameraTarget,
      cameraZoom: cameraZoom ?? this.cameraZoom,
      riderStatus: riderStatus ?? this.riderStatus,
      isSimulationRunning: isSimulationRunning ?? this.isSimulationRunning,
      isFollowingRider: isFollowingRider ?? this.isFollowingRider,
      currentRouteIndex: currentRouteIndex ?? this.currentRouteIndex,
      isMapReady: isMapReady ?? this.isMapReady,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      estimatedDistance: estimatedDistance ?? this.estimatedDistance,
    );
  }

  @override
  List<Object?> get props => [
        markers,
        polylines,
        riderPosition,
        cameraTarget,
        cameraZoom,
        riderStatus,
        isSimulationRunning,
        isFollowingRider,
        currentRouteIndex,
        isMapReady,
        estimatedTime,
        estimatedDistance,
      ];
}
