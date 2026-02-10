part of 'longdo_map_navigation_cubit.dart';

enum LongdoMapNavigationStatus {
  initial,
  locationDisabled,
  mapReady,
  positionError,
  routeLoading,
  routeReady,
}

enum LongDoMapNavigationLocationStatus {
  initial,
  checking,
  enabled,
  disabled,
}

final class LongdoMapNavigationState extends Equatable {
  const LongdoMapNavigationState({
    this.status = LongdoMapNavigationStatus.initial,
    this.currentPosition,
    this.shopLocation = const MyPosition(latitude: 7.882843118090549, longitude: 98.4104004642786),
    this.customerLocation = const MyPosition(latitude: 7.880905644762614, longitude: 98.40977075309326),
    this.jsonRoute,
    this.permissionStatus = PermissionRequestStatus.initial,
    this.locationServiceStatus = LongDoMapNavigationLocationStatus.initial,
    this.showLocationServiceDialog = false,
    this.remainingDistance = 0,
  });

  final LongdoMapNavigationStatus status;
  final MyPosition? currentPosition;

  // Mock Location
  final MyPosition shopLocation;
  final MyPosition customerLocation;

  final LongDoMapGeoJson? jsonRoute;

  final PermissionRequestStatus permissionStatus;
  final LongDoMapNavigationLocationStatus locationServiceStatus;
  final bool showLocationServiceDialog;

  /// ระยะทางที่เหลือ (เมตร) — คำนวณโดย JS แล้วส่งกลับมา
  final double remainingDistance;

  LongdoMapNavigationState copyWith({
    LongdoMapNavigationStatus? status,
    MyPosition? currentPosition,
    MyPosition? shopLocation,
    MyPosition? customerLocation,
    LongDoMapGeoJson? jsonRoute,
    PermissionRequestStatus? permissionStatus,
    LongDoMapNavigationLocationStatus? locationServiceStatus,
    bool? showLocationServiceDialog,
    double? remainingDistance,
  }) {
    return LongdoMapNavigationState(
      status: status ?? this.status,
      currentPosition: currentPosition ?? this.currentPosition,
      shopLocation: shopLocation ?? this.shopLocation,
      customerLocation: customerLocation ?? this.customerLocation,
      jsonRoute: jsonRoute ?? this.jsonRoute,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      locationServiceStatus: locationServiceStatus ?? this.locationServiceStatus,
      showLocationServiceDialog: showLocationServiceDialog ?? this.showLocationServiceDialog,
      remainingDistance: remainingDistance ?? this.remainingDistance,
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentPosition,
        shopLocation,
        customerLocation,
        jsonRoute,
        permissionStatus,
        locationServiceStatus,
        showLocationServiceDialog,
        remainingDistance,
      ];
}