import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rider_map_poc/modules/rider_map/widgets/rider_map_widget.dart';

/// Rider delivery status
enum RiderStatus {
  idle,
  headingToPickup,
  arrivedAtPickup,
  headingToDelivery,
  delivered,
}

/// Camera action requested by BLoC
enum CameraAction {
  none,
  centerOnRider,
  fitAllMarkers,
  followRider,
}

/// State for RiderMapBloc - contains only DATA, no UI objects
class RiderMapState extends Equatable {
  // Position data
  final LatLng riderPosition;
  final int currentRouteIndex;
  
  // Status
  final RiderStatus riderStatus;
  final bool isSimulationRunning;
  final bool isFollowingRider;
  final bool isMapReady;
  
  // Display info
  final String estimatedTime;
  final String estimatedDistance;
  
  // Camera action for UI to handle
  final CameraAction cameraAction;
  
  // Marker icons
  final MapMarkerIcons? markerIcons;

  const RiderMapState({
    this.riderPosition = const LatLng(13.7433, 100.5311),
    this.currentRouteIndex = 0,
    this.riderStatus = RiderStatus.idle,
    this.isSimulationRunning = false,
    this.isFollowingRider = true,
    this.isMapReady = false,
    this.estimatedTime = '8 mins',
    this.estimatedDistance = '1.2 km',
    this.cameraAction = CameraAction.none,
    this.markerIcons,
  });

  RiderMapState copyWith({
    LatLng? riderPosition,
    int? currentRouteIndex,
    RiderStatus? riderStatus,
    bool? isSimulationRunning,
    bool? isFollowingRider,
    bool? isMapReady,
    String? estimatedTime,
    String? estimatedDistance,
    CameraAction? cameraAction,
    MapMarkerIcons? markerIcons,
  }) {
    return RiderMapState(
      riderPosition: riderPosition ?? this.riderPosition,
      currentRouteIndex: currentRouteIndex ?? this.currentRouteIndex,
      riderStatus: riderStatus ?? this.riderStatus,
      isSimulationRunning: isSimulationRunning ?? this.isSimulationRunning,
      isFollowingRider: isFollowingRider ?? this.isFollowingRider,
      isMapReady: isMapReady ?? this.isMapReady,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      estimatedDistance: estimatedDistance ?? this.estimatedDistance,
      cameraAction: cameraAction ?? CameraAction.none,
      markerIcons: markerIcons ?? this.markerIcons,
    );
  }

  @override
  List<Object?> get props => [
        riderPosition,
        currentRouteIndex,
        riderStatus,
        isSimulationRunning,
        isFollowingRider,
        isMapReady,
        estimatedTime,
        estimatedDistance,
        cameraAction,
        markerIcons,
      ];
}
