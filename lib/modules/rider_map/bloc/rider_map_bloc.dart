import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:rider_map_poc/data/services/geolocator/geolocator_service.dart';
import 'package:rider_map_poc/modules/rider_map/data/mock_route_data.dart';

part 'rider_map_event.dart';
part 'rider_map_state.dart';

@injectable
class RiderMapBloc extends Bloc<RiderMapEvent, RiderMapState> {
  final GeolocatorService _geolocatorService;
  
  Timer? _simulationTimer;
  StreamSubscription<Position>? _positionStreamSubscription;
  final List<LatLng> _routePoints = MockRouteData.getMockRoutePoints();

  RiderMapBloc(this._geolocatorService) : super(const RiderMapState()) {
    on<InitializeMap>(_onInitializeMap);
    on<RequestLocationPermission>(_onRequestLocationPermission);
    on<StartLocationTracking>(_onStartLocationTracking);
    on<StopLocationTracking>(_onStopLocationTracking);
    on<UpdateRiderLocationFromGPS>(_onUpdateRiderLocationFromGPS);
    on<StartRiderSimulation>(_onStartRiderSimulation);
    on<StopRiderSimulation>(_onStopRiderSimulation);
    on<UpdateRiderPosition>(_onUpdateRiderPosition);
    on<CenterOnRider>(_onCenterOnRider);
    on<FitAllMarkers>(_onFitAllMarkers);
    on<ToggleFollowRider>(_onToggleFollowRider);
    on<MapControllerReady>(_onMapControllerReady);
    on<ResetCameraAction>(_onResetCameraAction);
  }

  /// Get route points for UI to build polylines
  List<LatLng> get routePoints => _routePoints;

  void _onMapControllerReady(
    MapControllerReady event,
    Emitter<RiderMapState> emit,
  ) {
    emit(state.copyWith(isMapReady: true));
  }

  void _onInitializeMap(
    InitializeMap event,
    Emitter<RiderMapState> emit,
  ) {
    emit(state.copyWith(
      riderPosition: MockRouteData.riderStartPosition,
      estimatedTime: MockRouteData.getEstimatedTime(),
      estimatedDistance: MockRouteData.getEstimatedDistance(),
    ));
  }

  /// Request location permission and get initial position
  Future<void> _onRequestLocationPermission(
    RequestLocationPermission event,
    Emitter<RiderMapState> emit,
  ) async {
    emit(state.copyWith(locationStatus: LocationStatus.requesting));

    try {
      final position = await _geolocatorService.determinePosition();
      emit(state.copyWith(
        locationStatus: LocationStatus.granted,
        riderPosition: LatLng(position.latitude, position.longitude),
        cameraAction: CameraAction.centerOnRider,
      ));
    } catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('Location services are disabled')) {
        emit(state.copyWith(
          locationStatus: LocationStatus.serviceDisabled,
          locationErrorMessage: errorMessage,
        ));
      } else {
        emit(state.copyWith(
          locationStatus: LocationStatus.denied,
          locationErrorMessage: errorMessage,
        ));
      }
    }
  }

  /// Start tracking real GPS location
  void _onStartLocationTracking(
    StartLocationTracking event,
    Emitter<RiderMapState> emit,
  ) {
    if (state.isTrackingLocation) return;

    emit(state.copyWith(
      isTrackingLocation: true,
      riderStatus: RiderStatus.headingToPickup,
    ));

    _positionStreamSubscription = _geolocatorService.getPositionStream().listen(
      (position) {
        add(UpdateRiderLocationFromGPS(
          latitude: position.latitude,
          longitude: position.longitude,
        ));
      },
      onError: (error) {
        add(const StopLocationTracking());
      },
    );
  }

  /// Stop tracking GPS location
  void _onStopLocationTracking(
    StopLocationTracking event,
    Emitter<RiderMapState> emit,
  ) {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    emit(state.copyWith(isTrackingLocation: false));
  }

  /// Update rider position from GPS
  void _onUpdateRiderLocationFromGPS(
    UpdateRiderLocationFromGPS event,
    Emitter<RiderMapState> emit,
  ) {
    final newPosition = LatLng(event.latitude, event.longitude);
    emit(state.copyWith(
      riderPosition: newPosition,
      cameraAction: state.isFollowingRider ? CameraAction.followRider : CameraAction.none,
    ));
  }

  void _onStartRiderSimulation(
    StartRiderSimulation event,
    Emitter<RiderMapState> emit,
  ) {
    if (state.isSimulationRunning) return;

    emit(state.copyWith(
      isSimulationRunning: true,
      riderStatus: RiderStatus.headingToPickup,
    ));

    _simulationTimer = Timer.periodic(
      const Duration(milliseconds: 800),
      (_) => add(const UpdateRiderPosition()),
    );
  }

  void _onStopRiderSimulation(
    StopRiderSimulation event,
    Emitter<RiderMapState> emit,
  ) {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    emit(state.copyWith(isSimulationRunning: false));
  }

  void _onUpdateRiderPosition(
    UpdateRiderPosition event,
    Emitter<RiderMapState> emit,
  ) {
    final nextIndex = state.currentRouteIndex + 1;

    if (nextIndex >= _routePoints.length) {
      // Reached destination
      _simulationTimer?.cancel();
      _simulationTimer = null;
      emit(state.copyWith(
        isSimulationRunning: false,
        riderStatus: RiderStatus.delivered,
      ));
      return;
    }

    final newPosition = _routePoints[nextIndex];

    // Check status updates
    RiderStatus newStatus = state.riderStatus;
    if (newPosition == MockRouteData.pickupLocation) {
      newStatus = RiderStatus.arrivedAtPickup;
    } else if (state.riderStatus == RiderStatus.arrivedAtPickup &&
        nextIndex > _routePoints.indexOf(MockRouteData.pickupLocation)) {
      newStatus = RiderStatus.headingToDelivery;
    }

    emit(state.copyWith(
      riderPosition: newPosition,
      currentRouteIndex: nextIndex,
      riderStatus: newStatus,
      cameraAction: state.isFollowingRider ? CameraAction.followRider : CameraAction.none,
    ));
  }

  void _onCenterOnRider(
    CenterOnRider event,
    Emitter<RiderMapState> emit,
  ) {
    emit(state.copyWith(cameraAction: CameraAction.centerOnRider));
  }

  void _onFitAllMarkers(
    FitAllMarkers event,
    Emitter<RiderMapState> emit,
  ) {
    emit(state.copyWith(cameraAction: CameraAction.fitAllMarkers));
  }

  void _onToggleFollowRider(
    ToggleFollowRider event,
    Emitter<RiderMapState> emit,
  ) {
    emit(state.copyWith(isFollowingRider: !state.isFollowingRider));
  }

  void _onResetCameraAction(
    ResetCameraAction event,
    Emitter<RiderMapState> emit,
  ) {
    emit(state.copyWith(cameraAction: CameraAction.none));
  }

  @override
  Future<void> close() {
    _simulationTimer?.cancel();
    _positionStreamSubscription?.cancel();
    return super.close();
  }
}
