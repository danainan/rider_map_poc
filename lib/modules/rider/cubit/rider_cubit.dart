import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:rider_map_poc/data/services/geolocator/geolocator_service.dart';
import 'package:rider_map_poc/modules/rider/data/rider_mock_data.dart';
import 'package:rider_map_poc/data/services/rider/rider_repository.dart';

part 'rider_state.dart';

@injectable
class RiderCubit extends Cubit<RiderState> {
  final GeolocatorService _geolocatorService;
  final RiderRepository _riderRepository;

  StreamSubscription<Position>? _positionStreamSubscription;

  RiderCubit(
    this._geolocatorService,
    this._riderRepository,
  ) : super(const RiderState());

  Future<void> initialize() async {
    await checkLocationPermission();
  }

  @override
  Future<void> close() {
    _positionStreamSubscription?.cancel();
    return super.close();
  }

  Future<void> checkLocationPermission() async {
    emit(state.copyWith(locationPermissionStatus: LocationPermissionStatus.checking));

    try {
      final permission = await Geolocator.checkPermission();
      
      switch (permission) {
        case LocationPermission.always:
        case LocationPermission.whileInUse:
          emit(state.copyWith(locationPermissionStatus: LocationPermissionStatus.granted));
          await checkLocationService();
          break;
        case LocationPermission.denied:
          await requestLocationPermission();
          break;
        case LocationPermission.deniedForever:
          emit(state.copyWith(locationPermissionStatus: LocationPermissionStatus.deniedForever));
          break;
        case LocationPermission.unableToDetermine:
          emit(state.copyWith(locationPermissionStatus: LocationPermissionStatus.denied));
          break;
      }
    } catch (e) {
      emit(state.copyWith(
        locationPermissionStatus: LocationPermissionStatus.denied,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> requestLocationPermission() async {
    emit(state.copyWith(locationPermissionStatus: LocationPermissionStatus.checking));

    try {
      final permission = await Geolocator.requestPermission();

      switch (permission) {
        case LocationPermission.always:
        case LocationPermission.whileInUse:
          emit(state.copyWith(locationPermissionStatus: LocationPermissionStatus.granted));
          await checkLocationService();
          break;
        case LocationPermission.denied:
          emit(state.copyWith(locationPermissionStatus: LocationPermissionStatus.denied));
          break;
        case LocationPermission.deniedForever:
          emit(state.copyWith(locationPermissionStatus: LocationPermissionStatus.deniedForever));
          break;
        case LocationPermission.unableToDetermine:
          emit(state.copyWith(locationPermissionStatus: LocationPermissionStatus.denied));
          break;
      }
    } catch (e) {
      emit(state.copyWith(
        locationPermissionStatus: LocationPermissionStatus.denied,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> checkLocationService() async {
    emit(state.copyWith(locationServiceStatus: LocationServiceStatus.checking));

    final isEnabled = await _geolocatorService.isLocationServiceEnabled();

    if (isEnabled) {
      emit(state.copyWith(
        locationServiceStatus: LocationServiceStatus.enabled,
        showLocationServiceDialog: false,
      ));
      await _onLocationReady();
    } else {
      emit(state.copyWith(
        locationServiceStatus: LocationServiceStatus.disabled,
        showLocationServiceDialog: true,
      ));
    }
  }

  Future<void> onAppResumed() async {
    if (state.locationPermissionStatus == LocationPermissionStatus.granted) {
      await checkLocationService();
    }
  }

  void dismissLocationServiceDialog() {
    emit(state.copyWith(showLocationServiceDialog: false));
  }

  void showLocationServiceDialogAgain() {
    emit(state.copyWith(showLocationServiceDialog: true));
  }

  Future<void> _onLocationReady() async {
    await _getCurrentPosition();

    startLocationTracking();

    await loadRoute();
  }

  Future<void> _getCurrentPosition() async {
    try {
      final position = await _geolocatorService.determinePosition();
      emit(state.copyWith(
        riderPosition: LatLng(position.latitude, position.longitude),
        cameraAction: RiderCameraAction.centerOnRider,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'ไม่สามารถดึงตำแหน่งได้: ${e.toString()}'));
    }
  }

  void startLocationTracking() {
    if (state.isTrackingLocation) return;

    emit(state.copyWith(
      isTrackingLocation: true,
      deliveryStatus: RiderDeliveryStatus.headingToShop,
    ));

    _positionStreamSubscription = _geolocatorService.getPositionStream().listen(
      (position) {
        _updateRiderPosition(position.latitude, position.longitude);
      },
      onError: (error) {
        stopLocationTracking();
      },
    );
  }

  /// หยุด tracking ตำแหน่ง
  void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    emit(state.copyWith(isTrackingLocation: false));
  }

  /// อัพเดทตำแหน่ง Rider
  void _updateRiderPosition(double latitude, double longitude) {
    final newPosition = LatLng(latitude, longitude);
    emit(state.copyWith(
      riderPosition: newPosition,
      cameraAction: state.isFollowingRider ? RiderCameraAction.followRider : RiderCameraAction.none,
    ));
  }

  Future<void> loadRoute() async {
    if (state.riderPosition == null) return;

    emit(state.copyWith(routeLoadingStatus: RouteLoadingStatus.loading));

    final result = await _riderRepository.getMultiStopRoute(
      riderLocation: state.riderPosition!,
      shopLocation: RiderMockData.shopLocation,
      customerLocation: RiderMockData.customerLocation,
    );

    if (result.isSuccess) {
      emit(state.copyWith(
        routeLoadingStatus: RouteLoadingStatus.loaded,
        riderToShopPoints: result.riderToShopPoints,
        shopToCustomerPoints: result.shopToCustomerPoints,
        riderToShopDistance: result.riderToShopDistance,
        riderToShopDuration: result.riderToShopDuration,
        shopToCustomerDistance: result.shopToCustomerDistance,
        shopToCustomerDuration: result.shopToCustomerDuration,
        totalDistance: result.totalDistance,
        totalDuration: result.totalDuration,
        cameraAction: RiderCameraAction.fitAllMarkers,
      ));
    } else {
      emit(state.copyWith(
        routeLoadingStatus: RouteLoadingStatus.error,
        routeErrorMessage: result.errorMessage,
      ));
    }
  }

  Future<void> refreshRoute() async {
    await loadRoute();
  }

  void centerOnRider() {
    emit(state.copyWith(cameraAction: RiderCameraAction.centerOnRider));
  }

  void fitAllMarkers() {
    emit(state.copyWith(cameraAction: RiderCameraAction.fitAllMarkers));
  }

  void toggleFollowRider() {
    emit(state.copyWith(
      isFollowingRider: !state.isFollowingRider,
      cameraAction: !state.isFollowingRider ? RiderCameraAction.centerOnRider : RiderCameraAction.none,
    ));
  }

  void resetCameraAction() {
    emit(state.copyWith(cameraAction: RiderCameraAction.none));
  }

  void onMapReady() {
    emit(state.copyWith(isMapReady: true));
  }

  void updateDeliveryStatus(RiderDeliveryStatus status) {
    emit(state.copyWith(deliveryStatus: status));
  }

  void arrivedAtShop() {
    emit(state.copyWith(deliveryStatus: RiderDeliveryStatus.arrivedAtShop));
  }

  void startDeliveryToCustomer() {
    emit(state.copyWith(deliveryStatus: RiderDeliveryStatus.headingToCustomer));
  }

  void completeDelivery() {
    stopLocationTracking();
    emit(state.copyWith(deliveryStatus: RiderDeliveryStatus.delivered));
  }
}
