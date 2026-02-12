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


  Timer? _mockTimer;
  bool _isMockMode = true;
  int _currentMockIndex = 0;
  final List<List<double>> _mockCoordinates = [
    [7.883883, 98.411758],  // จุดที่ 1
    [7.88364, 98.411819],   // จุดที่ 2
    [7.883617, 98.411744],  // จุดที่ 2.5
    [7.883600, 98.411672],  // จุดที่ 2.7
    [7.883583, 98.411603],  // จุดที่ 2.9
    [7.883579, 98.411575],  // จุดที่ 3
    [7.883458, 98.411524],  // จุดที่ 3.5
    [7.883567, 98.411491], 
    [7.883392, 98.411527],
    [7.883330, 98.411522],
    [7.883270, 98.411526],
    [7.883219, 98.411535],
    [7.883145, 98.411537],  // จุดที่ 5
    [7.883125, 98.411446],
    [7.883118, 98.411400],
    [7.883116, 98.411321],
    [7.883114, 98.411290],
    [7.883099, 98.411227],
    [7.883033, 98.410652],  // จุดที่ 6
    [7.882872, 98.410667],  // จุดที่ 7 (จุดสุดท้าย)
  ];

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

  void _startTracking() {
    if (_isMockMode) {
      _startMockTracking();
    } else {
      _startRealTracking();
    }
  }

  void _startMockTracking() {
    _currentMockIndex = 0;
    
    // ส่งตำแหน่งแรกทันที
    if (_mockCoordinates.isNotEmpty) {
      final coord = _mockCoordinates[_currentMockIndex];
      emit(state.copyWith(
        currentPosition: MyPosition(
          latitude: coord[0],
          longitude: coord[1],
        ),
      ));
    }

    _mockTimer?.cancel();
    _mockTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _currentMockIndex++;
      
      if (_currentMockIndex >= _mockCoordinates.length) {
        _mockTimer?.cancel();
        return;
      }

      final coord = _mockCoordinates[_currentMockIndex];
      emit(state.copyWith(
        currentPosition: MyPosition(
          latitude: coord[0],
          longitude: coord[1],
        ),
      ));     
    });
  }

  // ---- Tracking ----
  
  void _startRealTracking() {
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
    MyPosition destinationPosion;

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
            final allCoordinates = <List<double>>[];
            for (final feature in combinedFeatures) {
              if (feature.geometry?.type == 'LineString') {
                final coords = feature.geometry?.coordinates;
                if (coords != null) {
                  for (final coord in coords) {
                    if (coord.length >= 2) {
                      final lon = coord[0];
                      final lat = coord[1];
                      allCoordinates.add([lat, lon]);
                    }
                  }
                }
              }
            }

            destinationPosion = MyPosition(
              latitude: allCoordinates.last[0],
              longitude: allCoordinates.last[1],
            );

            emit(state.copyWith(
              status: LongdoMapNavigationStatus.routeReady,
              jsonRoute: combinedGeoJson,
              remainingDistance: 0,
              allCoordinates: allCoordinates,
              destinationCoordinates: destinationPosion,
            ));
          },
        );
      },
    );
  }

  Future<MyPosition> checkIfCurrentLocationNearByAllCoordinators({
    required double currLat,
    required double currLong
  }) async {
    if (state.allCoordinates == null || state.allCoordinates!.isEmpty) {
      return const MyPosition(latitude: 0.0, longitude: 0.0);
    }

    const proximityThresholdMeters = 30.0;

    for (final coord in state.allCoordinates!) {
      final lat = coord[0];
      final lon = coord[1];

      final distance = Geolocator.distanceBetween(
        currLat,
        currLong,
        lat,
        lon,
      );

      //return ตัวที่ใกล้ที่สุดไป
      if (distance <= proximityThresholdMeters) {
        return MyPosition(latitude: lat, longitude: lon);
      }
    }
    return const MyPosition(latitude: 0.0, longitude: 0.0);
  }

  @override
  Future<void> close() {
    _positionStream?.cancel();
    return super.close();
  }
}