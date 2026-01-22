import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:rider_map_poc/modules/rider_map/data/mock_route_data.dart';

part 'rider_map_event.dart';
part 'rider_map_state.dart';

@injectable
class RiderMapBloc extends Bloc<RiderMapEvent, RiderMapState> {
  Timer? _simulationTimer;
  final List<LatLng> _routePoints = MockRouteData.getMockRoutePoints();

  RiderMapBloc() : super(const RiderMapState()) {
    on<InitializeMap>(_onInitializeMap);
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
    return super.close();
  }
}
