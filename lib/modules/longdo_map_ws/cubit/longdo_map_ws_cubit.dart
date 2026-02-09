import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import 'package:rider_map_poc/data/models/longdo_route/longdo_route_geojson.dart';
import 'package:rider_map_poc/data/models/permission/permission_request_status.dart';
import 'package:rider_map_poc/data/services/geolocator/geolocator_service.dart';
import 'package:rider_map_poc/data/services/longdo_map/longdo_routing_service.dart';
import 'package:rider_map_poc/data/services/permission_status/app_permission_status_service.dart';

part 'longdo_map_ws_state.dart';

@injectable
class LongdoMapWsCubit extends Cubit<LongdoMapWsState> {
  final GeolocatorService _geolocatorService;
  final AppPermissionStatusService _permissionService;
  final LongdoRoutingService _routingService;

  StreamSubscription<Position>? _positionSubscription;
  double _lastCurrentLat = 0;
  double _lastCurrentLon = 0;

  LongdoMapWsCubit(
    this._geolocatorService,
    this._permissionService,
    this._routingService,
  ) : super(const LongdoMapWsState());

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
          ? LongdoWsLocationServiceStatus.enabled
          : LongdoWsLocationServiceStatus.disabled,
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
    emit(state.copyWith(status: LongdoMapWsStatus.loading));

    try {
      final position = await _geolocatorService.determinePosition();
      emit(state.copyWith(
        status: LongdoMapWsStatus.mapReady,
        currentLat: position.latitude,
        currentLon: position.longitude,
      ));

      // ค้นหาเส้นทางครั้งแรก
      await _fetchRoute(position.latitude, position.longitude);

      startTracking();
    } catch (e) {
      emit(state.copyWith(
        status: LongdoMapWsStatus.locationError,
        errorMessage: 'ไม่สามารถดึงตำแหน่งได้: $e',
      ));
    }
  }

  // ---- Routing Web Service ----
  // Rider → ร้านค้า → ลูกค้า (ยิง 2 ครั้ง แล้วรวม features)

  Future<void> _fetchRoute(double lat, double lon) async {
    emit(state.copyWith(isRouteLoading: true));

    // ยิง 2 เส้นทางพร้อมกัน: Rider→Shop, Shop→Customer
    final results = await Future.wait([
      _routingService.calculateRoute(
        flat: lat,
        flon: lon,
        tlat: state.shopLat,
        tlon: state.shopLon,
      ),
      _routingService.calculateRoute(
        flat: state.shopLat,
        flon: state.shopLon,
        tlat: state.customerLat,
        tlon: state.customerLon,
      ),
    ]);

    final riderToShop = results[0];
    final shopToCustomer = results[1];

    // เช็คว่าทั้ง 2 เส้นทางสำเร็จ
    if (riderToShop.isLeft() || shopToCustomer.isLeft()) {
      final error = riderToShop.fold((e) => e, (_) => '') +
          shopToCustomer.fold((e) => e, (_) => '');
      emit(state.copyWith(
        isRouteLoading: false,
        errorMessage: error.isNotEmpty ? error : 'ไม่สามารถคำนวณเส้นทางได้',
      ));
      return;
    }

    final geoJson1 = riderToShop.getOrElse((_) => throw Exception());
    final geoJson2 = shopToCustomer.getOrElse((_) => throw Exception());

    // รวม features จากทั้ง 2 เส้นทาง
    final allFeatures = [...geoJson1.features, ...geoJson2.features];

    // รวมระยะทาง + เวลา
    final totalDistance =
        geoJson1.properties.distance + geoJson2.properties.distance;
    final totalInterval =
        geoJson1.properties.interval + geoJson2.properties.interval;
    final distanceText =
        totalDistance >= 1000
            ? '${(totalDistance / 1000).toStringAsFixed(1)} km'
            : '${totalDistance.toStringAsFixed(0)} m';
    final intervalMin = (totalInterval / 60).ceil();
    final intervalText = '$intervalMin min';

    // แปลงเป็น JSON สำหรับส่งไป JS
    final routeJson = jsonEncode({
      'features': allFeatures
          .map((f) => {
                'name': f.name,
                'turn': f.turn,
                'turnDesc': f.turnDescription,
                'distance': f.distance,
                'interval': f.interval,
                'coordinates': f.coordinates,
              })
          .toList(),
      'totalDistance': totalDistance,
      'totalInterval': totalInterval,
      'distanceText': distanceText,
      'intervalText': intervalText,
    });

    emit(state.copyWith(
      isRouteLoading: false,
      routeGeoJson: geoJson1,
      routeJsonForJs: routeJson,
      combinedDistanceText: distanceText,
      combinedIntervalText: intervalText,
      combinedFeatureCount: allFeatures.length,
    ));
  }

  /// เรียกจาก page เมื่อต้องการยิง route ใหม่แบบ manual`
  /// หรือเมื่อ rider ออกนอกเส้นทาง (off-route)
  Future<void> refreshRoute() async {
    if (state.currentLat == 0 || state.currentLon == 0) return;
    if (state.isRouteLoading) return; // กัน spam ขณะกำลังโหลดอยู่
    if (_lastCurrentLat == 0 &&
        _lastCurrentLon == 0) return;
    await _fetchRoute(state.currentLat, state.currentLon);
  }

  // ---- GPS Tracking ----

  void startTracking() {
    if (state.isTracking) return;

    emit(state.copyWith(
      isTracking: true,
      status: LongdoMapWsStatus.tracking,
    ));

    _positionSubscription = _geolocatorService.getPositionStream().listen(
      (Position position) {
        _lastCurrentLat = position.latitude;
        _lastCurrentLon = position.longitude;
        emit(state.copyWith(
          currentLat: position.latitude,
          currentLon: position.longitude,
        ));
      },
      onError: (error) {
        stopTracking();
        emit(state.copyWith(
          status: LongdoMapWsStatus.locationError,
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
      status: LongdoMapWsStatus.mapReady,
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
        status: LongdoMapWsStatus.locationError,
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
