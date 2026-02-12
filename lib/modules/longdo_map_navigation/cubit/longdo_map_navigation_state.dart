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
    this.shopLocation = const MyPosition(latitude: 7.882843118090549, longitude: 98.4104004642786), //ยูเนี่ยน
    this.customerLocation = const MyPosition(latitude: 0.0, longitude: 0.0), //เภสัช
    this.jsonRoute,
    this.permissionStatus = PermissionRequestStatus.initial,
    this.locationServiceStatus = LongDoMapNavigationLocationStatus.initial,
    this.showLocationServiceDialog = false,
    this.remainingDistance = 0,
    this.allCoordinates = const [],
    this.polyLineIsPassed = const [],
    this.destinationCoordinates,
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

  final List<List<double>>? allCoordinates;

  final List<List<double>>? polyLineIsPassed;

  /// ระยะทางที่เหลือ (เมตร) — คำนวณโดย JS แล้วส่งกลับมา
  final double remainingDistance;

  final MyPosition? destinationCoordinates;

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
    List<List<double>>? allCoordinates,
    List<List<double>>? polyLineIsPassed,
    MyPosition? destinationCoordinates,
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
      allCoordinates: allCoordinates ?? this.allCoordinates,
      polyLineIsPassed: polyLineIsPassed ?? this.polyLineIsPassed,
      destinationCoordinates: destinationCoordinates ?? this.destinationCoordinates,
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
        allCoordinates,
        polyLineIsPassed,
        destinationCoordinates,
      ];
}