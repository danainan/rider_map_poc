import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import 'package:rider_map_poc/data/models/permission/permission_request_status.dart';
import 'package:rider_map_poc/data/services/geolocator/geolocator_service.dart';
import 'package:rider_map_poc/data/services/permission_status/app_permission_status_service.dart';

part 'longdo_map_route_state.dart';

@injectable
class LongdoMapRouteCubit extends Cubit<LongdoMapRouteState> {
  final GeolocatorService _geolocatorService;
  final AppPermissionStatusService _permissionService;

  StreamSubscription<Position>? _positionSubscription;

  // ตำแหน่งล่าสุดที่สั่ง updateStartPoint → เทียบว่า rider ขยับหรือยัง
  double _lastRouteLat = 0;
  double _lastRouteLon = 0;
  static const double _routeRefreshDistanceMeters = 50;

  LongdoMapRouteCubit(
    this._geolocatorService,
    this._permissionService,
  ) : super(const LongdoMapRouteState());

  // ---- Initialization ----

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
          ? LongdoRouteLocationServiceStatus.enabled
          : LongdoRouteLocationServiceStatus.disabled,
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

  // ---- Location Ready ----

  Future<void> _onLocationReady() async {
    emit(state.copyWith(status: LongdoMapRouteStatus.loading));

    try {
      final position = await _geolocatorService.determinePosition();
      _lastRouteLat = position.latitude;
      _lastRouteLon = position.longitude;

      emit(state.copyWith(
        status: LongdoMapRouteStatus.mapReady,
        currentLat: position.latitude,
        currentLon: position.longitude,
      ));

      startTracking();
    } catch (e) {
      emit(state.copyWith(
        status: LongdoMapRouteStatus.locationError,
        errorMessage: 'ไม่สามารถดึงตำแหน่งได้: $e',
      ));
    }
  }

  // ---- Route info จาก JS ----

  void onRouteComplete(String distance, String interval) {
    emit(state.copyWith(
      isRouteSearching: false,
      routeDistance: distance,
      routeInterval: interval,
    ));
  }

  void onRouteSearching() {
    emit(state.copyWith(isRouteSearching: true));
  }

  // ---- GPS Tracking ----

  void startTracking() {
    if (state.isTracking) return;

    emit(state.copyWith(
      isTracking: true,
      status: LongdoMapRouteStatus.tracking,
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
          status: LongdoMapRouteStatus.locationError,
          errorMessage: 'GPS Error: $error',
        ));
      },
    );
  }

  /// เช็คว่า rider ขยับจากจุดสุดท้ายที่เคยอัพเดท route เกิน threshold หรือยัง
  bool shouldUpdateRoute(double lat, double lon) {
    if (_lastRouteLat == 0 && _lastRouteLon == 0) return true;

    final distance = Geolocator.distanceBetween(
      _lastRouteLat,
      _lastRouteLon,
      lat,
      lon,
    );

    if (distance >= _routeRefreshDistanceMeters) {
      _lastRouteLat = lat;
      _lastRouteLon = lon;
      return true;
    }
    return false;
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    emit(state.copyWith(
      isTracking: false,
      status: LongdoMapRouteStatus.mapReady,
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
        status: LongdoMapRouteStatus.locationError,
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
