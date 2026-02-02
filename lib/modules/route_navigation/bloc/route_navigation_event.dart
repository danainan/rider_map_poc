part of 'route_navigation_bloc.dart';

/// Events for RouteNavigationBloc
abstract class RouteNavigationEvent extends Equatable {
  const RouteNavigationEvent();

  @override
  List<Object?> get props => [];
}

/// Check if location service is enabled
class CheckLocationServiceEvent extends RouteNavigationEvent {
  const CheckLocationServiceEvent();
}

/// Request location permission
class RequestLocationPermissionEvent extends RouteNavigationEvent {
  const RequestLocationPermissionEvent();
}

/// Update current rider location from GPS
class UpdateRiderLocationEvent extends RouteNavigationEvent {
  final double latitude;
  final double longitude;

  const UpdateRiderLocationEvent({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}

/// Fetch route from Routes API
class FetchRouteEvent extends RouteNavigationEvent {
  const FetchRouteEvent();
}

/// Start location tracking
class StartLocationTrackingEvent extends RouteNavigationEvent {
  const StartLocationTrackingEvent();
}

/// Stop location tracking
class StopLocationTrackingEvent extends RouteNavigationEvent {
  const StopLocationTrackingEvent();
}

/// Center camera on rider
class CenterOnRiderEvent extends RouteNavigationEvent {
  const CenterOnRiderEvent();
}

/// Fit all markers in view
class FitAllMarkersEvent extends RouteNavigationEvent {
  const FitAllMarkersEvent();
}

/// Map controller is ready
class MapControllerReadyEvent extends RouteNavigationEvent {
  const MapControllerReadyEvent();
}

/// Reset camera action
class ResetCameraActionEvent extends RouteNavigationEvent {
  const ResetCameraActionEvent();
}
