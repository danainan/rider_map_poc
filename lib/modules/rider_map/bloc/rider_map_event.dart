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

/// Start rider movement simulation
class StartRiderSimulation extends RiderMapEvent {
  const StartRiderSimulation();
}

/// Stop rider movement simulation
class StopRiderSimulation extends RiderMapEvent {
  const StopRiderSimulation();
}

/// Update rider position (called by timer)
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
