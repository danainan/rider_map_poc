import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import 'package:rider_map_poc/data/models/permission/permission_request_status.dart';
import 'package:rider_map_poc/data/services/geolocator/geolocator_service.dart';
import 'package:rider_map_poc/data/services/permission_status/app_permission_status_service.dart';

part 'longdo_map_state.dart';

@injectable
class LongdoMapCubit extends Cubit<LongdoMapState> {
  final GeolocatorService _geolocatorService;
  final AppPermissionStatusService _permissionService;

  StreamSubscription<Position>? _positionSubscription;

  LongdoMapCubit(this._geolocatorService, this._permissionService)
      : super(const LongdoMapState());

  // ---- Initialization (เรียกจาก page initState) ----

  Future<void> initialize() async {
    await requestLocationPermission();
  }

  // ---- Permission ----

  Future<void> requestLocationPermission() async {
    emit(state.copyWith(
      permissionStatus: PermissionRequestStatus.requesting,
    ));

    final status = await _permissionService.requestLocationPermission();
    emit(state.copyWith(permissionStatus: status));

    if (status == PermissionRequestStatus.granted) {
      await checkLocationService();
    }
  }

  // ---- Location Service ----

  Future<void> checkLocationService() async {
    final isEnabled = await _geolocatorService.isLocationServiceEnabled();

    emit(state.copyWith(
      locationServiceStatus: isEnabled
          ? LongdoLocationServiceStatus.enabled
          : LongdoLocationServiceStatus.disabled,
      showLocationServiceDialog: !isEnabled,
    ));

    if (isEnabled) {
      await _onLocationReady();
    }
  }

  Future<void> onAppResumed() async {
    if (state.permissionStatus == PermissionRequestStatus.granted) {
      await checkLocationService();
    }
  }

  void dismissLocationServiceDialog() {
    emit(state.copyWith(showLocationServiceDialog: false));
  }

  // ---- Location Ready → ดึงตำแหน่ง + เริ่ม tracking ----

  Future<void> _onLocationReady() async {
    emit(state.copyWith(status: LongdoMapStatus.loading));

    try {
      final position = await _geolocatorService.determinePosition();
      emit(state.copyWith(
        status: LongdoMapStatus.mapReady,
        currentLat: position.latitude,
        currentLon: position.longitude,
      ));

      startTracking();
    } catch (e) {
      emit(state.copyWith(
        status: LongdoMapStatus.locationError,
        errorMessage: 'ไม่สามารถดึงตำแหน่งได้: $e',
      ));
    }
  }

  // ---- GPS Tracking ----

  void startTracking() {
    if (state.isTracking) return;

    emit(state.copyWith(
      isTracking: true,
      status: LongdoMapStatus.tracking,
    ));

    _positionSubscription = _geolocatorService.getPositionStream().listen(
      (Position position) {
        emit(state.copyWith(
          currentLat: position.latitude,
          currentLon: position.longitude,
        ));
      },
      onError: (error) {
        stopTracking();
        emit(state.copyWith(
          status: LongdoMapStatus.locationError,
          errorMessage: 'GPS Error: $error',
        ));
      },
    );
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    emit(state.copyWith(
      isTracking: false,
      status: LongdoMapStatus.mapReady,
    ));
  }

  Future<void> refreshLocation() async {
    try {
      final position = await _geolocatorService.determinePosition();
      emit(state.copyWith(
        currentLat: position.latitude,
        currentLon: position.longitude,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: LongdoMapStatus.locationError,
        errorMessage: 'ไม่สามารถดึงตำแหน่งได้: $e',
      ));
    }
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    return super.close();
  }
}
