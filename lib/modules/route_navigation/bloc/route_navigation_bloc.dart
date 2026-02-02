import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:rider_map_poc/data/services/geolocator/geolocator_service.dart';
import 'package:rider_map_poc/data/services/routes/routes_service.dart';
import 'package:rider_map_poc/modules/route_navigation/data/mock_location_data.dart';

part 'route_navigation_event.dart';
part 'route_navigation_state.dart';

@injectable
class RouteNavigationBloc extends Bloc<RouteNavigationEvent, RouteNavigationState> {
  final GeolocatorService _geolocatorService;
  final RoutesService _routesService;

  StreamSubscription<Position>? _positionStreamSubscription;

  RouteNavigationBloc(
    this._geolocatorService,
    this._routesService,
  ) : super(const RouteNavigationState()) {
    on<CheckLocationServiceEvent>(_onCheckLocationService);
    on<RequestLocationPermissionEvent>(_onRequestLocationPermission);
    on<UpdateRiderLocationEvent>(_onUpdateRiderLocation);
    on<FetchRouteEvent>(_onFetchRoute);
    on<StartLocationTrackingEvent>(_onStartLocationTracking);
    on<StopLocationTrackingEvent>(_onStopLocationTracking);
    on<CenterOnRiderEvent>(_onCenterOnRider);
    on<FitAllMarkersEvent>(_onFitAllMarkers);
    on<MapControllerReadyEvent>(_onMapControllerReady);
    on<ResetCameraActionEvent>(_onResetCameraAction);
  }

  /// Check if location service is enabled
  Future<void> _onCheckLocationService(
    CheckLocationServiceEvent event,
    Emitter<RouteNavigationState> emit,
  ) async {
    final isEnabled = await _geolocatorService.isLocationServiceEnabled();
    emit(state.copyWith(
      locationServiceStatus: isEnabled
          ? LocationServiceStatus.enabled
          : LocationServiceStatus.disabled,
    ));
  }

  /// Request location permission and get initial position
  Future<void> _onRequestLocationPermission(
    RequestLocationPermissionEvent event,
    Emitter<RouteNavigationState> emit,
  ) async {
    emit(state.copyWith(locationPermissionStatus: LocationPermissionStatus.requesting));

    try {
      final position = await _geolocatorService.determinePosition();
      final riderPos = LatLng(position.latitude, position.longitude);
      
      emit(state.copyWith(
        locationPermissionStatus: LocationPermissionStatus.granted,
        riderPosition: riderPos,
        cameraAction: CameraAction.fitAllMarkers,
      ));

      // Automatically fetch routes after getting rider position
      add(const FetchRouteEvent());
    } catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('Location services are disabled')) {
        emit(state.copyWith(
          locationPermissionStatus: LocationPermissionStatus.serviceDisabled,
          locationErrorMessage: errorMessage,
        ));
      } else if (errorMessage.contains('permanently denied')) {
        emit(state.copyWith(
          locationPermissionStatus: LocationPermissionStatus.deniedForever,
          locationErrorMessage: errorMessage,
        ));
      } else {
        emit(state.copyWith(
          locationPermissionStatus: LocationPermissionStatus.denied,
          locationErrorMessage: errorMessage,
        ));
      }
    }
  }

  /// Update rider location
  void _onUpdateRiderLocation(
    UpdateRiderLocationEvent event,
    Emitter<RouteNavigationState> emit,
  ) {
    final newPosition = LatLng(event.latitude, event.longitude);
    emit(state.copyWith(
      riderPosition: newPosition,
      cameraAction: CameraAction.followRider,
    ));
  }

  /// Fetch route from Routes API
  Future<void> _onFetchRoute(
    FetchRouteEvent event,
    Emitter<RouteNavigationState> emit,
  ) async {
    if (state.riderPosition == null) return;

    emit(state.copyWith(routeStatus: RouteStatus.loading));

    try {
      // Fetch route: Rider -> Restaurant
      final riderToRestaurant = await _routesService.getRoute(
        origin: state.riderPosition!,
        destination: state.restaurantLocation,
      );

      // Fetch route: Restaurant -> Customer
      final restaurantToCustomer = await _routesService.getRoute(
        origin: state.restaurantLocation,
        destination: state.customerLocation,
      );

      emit(state.copyWith(
        routeStatus: RouteStatus.loaded,
        riderToRestaurantRoute: riderToRestaurant.polylinePoints,
        restaurantToCustomerRoute: restaurantToCustomer.polylinePoints,
        estimatedTimeToRestaurant: riderToRestaurant.duration,
        estimatedDistanceToRestaurant: riderToRestaurant.distance,
        estimatedTimeToCustomer: restaurantToCustomer.duration,
        estimatedDistanceToCustomer: restaurantToCustomer.distance,
        cameraAction: CameraAction.fitAllMarkers,
      ));
    } catch (e) {
      emit(state.copyWith(
        routeStatus: RouteStatus.error,
        routeErrorMessage: e.toString(),
      ));
    }
  }

  /// Start location tracking
  void _onStartLocationTracking(
    StartLocationTrackingEvent event,
    Emitter<RouteNavigationState> emit,
  ) {
    if (state.isTrackingLocation) return;

    emit(state.copyWith(isTrackingLocation: true));

    _positionStreamSubscription = _geolocatorService.getPositionStream().listen(
      (position) {
        add(UpdateRiderLocationEvent(
          latitude: position.latitude,
          longitude: position.longitude,
        ));
      },
      onError: (error) {
        add(const StopLocationTrackingEvent());
      },
    );
  }

  /// Stop location tracking
  void _onStopLocationTracking(
    StopLocationTrackingEvent event,
    Emitter<RouteNavigationState> emit,
  ) {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    emit(state.copyWith(isTrackingLocation: false));
  }

  /// Center on rider
  void _onCenterOnRider(
    CenterOnRiderEvent event,
    Emitter<RouteNavigationState> emit,
  ) {
    emit(state.copyWith(cameraAction: CameraAction.centerOnRider));
  }

  /// Fit all markers
  void _onFitAllMarkers(
    FitAllMarkersEvent event,
    Emitter<RouteNavigationState> emit,
  ) {
    emit(state.copyWith(cameraAction: CameraAction.fitAllMarkers));
  }

  /// Map controller ready
  void _onMapControllerReady(
    MapControllerReadyEvent event,
    Emitter<RouteNavigationState> emit,
  ) {
    emit(state.copyWith(isMapReady: true));
  }

  /// Reset camera action
  void _onResetCameraAction(
    ResetCameraActionEvent event,
    Emitter<RouteNavigationState> emit,
  ) {
    emit(state.copyWith(cameraAction: CameraAction.none));
  }

  @override
  Future<void> close() {
    _positionStreamSubscription?.cancel();
    return super.close();
  }
}
