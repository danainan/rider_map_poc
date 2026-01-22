part of 'rider_map_bloc.dart';

/// Events for RiderMapBloc
abstract class RiderMapEvent extends Equatable {
  const RiderMapEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize the map with markers and route
class InitializeMap extends RiderMapEvent {
  const InitializeMap();
}

/// Request location permission and get initial position
class RequestLocationPermission extends RiderMapEvent {
  const RequestLocationPermission();
}

/// Start tracking real location
class StartLocationTracking extends RiderMapEvent {
  const StartLocationTracking();
}

/// Stop tracking real location
class StopLocationTracking extends RiderMapEvent {
  const StopLocationTracking();
}

/// Update rider position from GPS
class UpdateRiderLocationFromGPS extends RiderMapEvent {
  final double latitude;
  final double longitude;

  const UpdateRiderLocationFromGPS({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}

/// Start rider movement simulation (mock)
class StartRiderSimulation extends RiderMapEvent {
  const StartRiderSimulation();
}

/// Stop rider movement simulation (mock)
class StopRiderSimulation extends RiderMapEvent {
  const StopRiderSimulation();
}

/// Update rider position (called by timer for simulation)
class UpdateRiderPosition extends RiderMapEvent {
  const UpdateRiderPosition();
}

/// Center map on rider
class CenterOnRider extends RiderMapEvent {
  const CenterOnRider();
}

/// Fit all markers in view
class FitAllMarkers extends RiderMapEvent {
  const FitAllMarkers();
}

/// Toggle follow rider mode
class ToggleFollowRider extends RiderMapEvent {
  const ToggleFollowRider();
}

/// Map controller is ready
class MapControllerReady extends RiderMapEvent {
  const MapControllerReady();
}

/// Reset camera action after it was handled by UI
class ResetCameraAction extends RiderMapEvent {
  const ResetCameraAction();
}
