import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import 'package:rider_map_poc/data/models/geo_json/longdo_map_geo_json.dart';
import 'package:rider_map_poc/data/models/permission/permission_request_status.dart';
import 'package:rider_map_poc/data/models/position/my_position.dart';
import 'package:rider_map_poc/data/services/geolocator/geolocator_service.dart';
import 'package:rider_map_poc/data/services/longdo_map/longdo_map_service.dart';
import 'package:rider_map_poc/data/services/permission_status/app_permission_status_service.dart';

part 'longdo_map_navigation_state.dart';

@injectable
class LongdoMapNavigationCubit extends Cubit<LongdoMapNavigationState> {
  LongdoMapNavigationCubit(
    this._geolocatorService,
    this._permissionService,
    this._longdoMapService,
  ) : super(const LongdoMapNavigationState());

  final GeolocatorService _geolocatorService;
  final AppPermissionStatusService _permissionService;
  final LongdoMapService _longdoMapService;
  StreamSubscription<Position>? _positionStream;

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
          ? LongDoMapNavigationLocationStatus.enabled
          : LongDoMapNavigationLocationStatus.disabled,
      showLocationServiceDialog: !isEnabled,
    ));

    if (isEnabled) {
      await _onLocationReady();
    }
  }

  Future<void> _onLocationReady() async {
    emit(state.copyWith(status: LongdoMapNavigationStatus.routeLoading));

    try {
      final position = await _geolocatorService.determinePosition();
      emit(state.copyWith(
        status: LongdoMapNavigationStatus.mapReady,
        currentPosition: MyPosition(latitude: position.latitude, longitude: position.longitude),
      ));

      await fetchRouteGeoJson(position.latitude, position.longitude);

      _startTracking();
    } catch (e) {
      emit(state.copyWith(
        status: LongdoMapNavigationStatus.positionError,
      ));
    }
  }

  Future<void> onAppResumed() async {
    if (state.permissionStatus == PermissionRequestStatus.denied ||
        state.permissionStatus == PermissionRequestStatus.hasDeniedBefore) {
      await requestLocationPermission();
      return;
    }

    if (state.permissionStatus == PermissionRequestStatus.granted) {
      await checkLocationService();
    }
  }

  // ---- Tracking ----
  
  void _startTracking() {
    _positionStream?.cancel();
    _positionStream = _geolocatorService.getPositionStream().listen(
      (Position position) {
        emit(state.copyWith(
          currentPosition: MyPosition(
            latitude: position.latitude,
            longitude: position.longitude,
          ),
        ));
      },
      onError: (error) {
        stopTracking();
        emit(state.copyWith(
          status: LongdoMapNavigationStatus.positionError,
        ));
      },
    );
  }

  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  // ---- Remaining Distance (จาก JS) ----
  
  void updateRemainingDistance(double distance) {
    emit(state.copyWith(remainingDistance: distance));
  }

  // ---- Fetch Route (ครั้งเดียว ไม่ re-fetch เมื่อออกนอกเส้นทาง) ----

  Future<void> fetchRouteGeoJson(double currentLat, double currentLon) async {
    emit(state.copyWith(status: LongdoMapNavigationStatus.routeLoading));

    final result = await Future.wait([
      _longdoMapService.fetchRouteGeoJson(
        flat: currentLat,
        flon: currentLon,
        tlat: state.shopLocation.latitude,
        tlon: state.shopLocation.longitude,
      ),
      _longdoMapService.fetchRouteGeoJson(
        flat: state.shopLocation.latitude,
        flon: state.shopLocation.longitude,
        tlat: state.customerLocation.latitude,
        tlon: state.customerLocation.longitude,
      ),
    ]);

    final currentToShop = result[0];
    final shopToCustomer = result[1];

    currentToShop.fold(
      (error) {
        emit(state.copyWith(status: LongdoMapNavigationStatus.positionError));
      },
      (geoJson1) {
        shopToCustomer.fold(
          (error) {
            emit(state.copyWith(status: LongdoMapNavigationStatus.positionError));
          },
          (geoJson2) {
            final List<LongDoMapFeature> combinedFeatures = [
              ...(geoJson1.features ?? <LongDoMapFeature>[]),
              ...(geoJson2.features ?? <LongDoMapFeature>[]),
            ];
            final combinedGeoJson = LongDoMapGeoJson(features: combinedFeatures);

            emit(state.copyWith(
              status: LongdoMapNavigationStatus.routeReady,
              jsonRoute: combinedGeoJson,
              remainingDistance: 0,
            ));
          },
        );
      },
    );
  }

  @override
  Future<void> close() {
    _positionStream?.cancel();
    return super.close();
  }
}