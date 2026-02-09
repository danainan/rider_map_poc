part of 'longdo_map_route_cubit.dart';

enum LongdoMapRouteStatus {
  initial,
  loading,
  mapReady,
  tracking,
  locationError,
}

enum LongdoRouteLocationServiceStatus {
  initial,
  checking,
  enabled,
  disabled,
}

final class LongdoMapRouteState extends Equatable {
  const LongdoMapRouteState({
    this.status = LongdoMapRouteStatus.initial,
    this.permissionStatus = PermissionRequestStatus.initial,
    this.locationServiceStatus = LongdoRouteLocationServiceStatus.initial,
    this.showLocationServiceDialog = false,
    this.isTracking = false,
    this.isRouteSearching = false,
    this.currentLat = 0,
    this.currentLon = 0,
    // ร้านค้า (Siam Paragon)
    this.shopLat = 13.7466,
    this.shopLon = 100.5347,
    // ลูกค้า (Central World)
    this.customerLat = 13.7468,
    this.customerLon = 100.5392,
    this.routeDistance,
    this.routeInterval,
    this.errorMessage,
  });

  final LongdoMapRouteStatus status;
  final PermissionRequestStatus permissionStatus;
  final LongdoRouteLocationServiceStatus locationServiceStatus;
  final bool showLocationServiceDialog;
  final bool isTracking;
  final bool isRouteSearching;
  final double currentLat;
  final double currentLon;
  final double shopLat;
  final double shopLon;
  final double customerLat;
  final double customerLon;
  final String? routeDistance;
  final String? routeInterval;
  final String? errorMessage;

  bool get isLocationReady =>
      permissionStatus == PermissionRequestStatus.granted &&
      locationServiceStatus == LongdoRouteLocationServiceStatus.enabled;

  LongdoMapRouteState copyWith({
    LongdoMapRouteStatus? status,
    PermissionRequestStatus? permissionStatus,
    LongdoRouteLocationServiceStatus? locationServiceStatus,
    bool? showLocationServiceDialog,
    bool? isTracking,
    bool? isRouteSearching,
    double? currentLat,
    double? currentLon,
    double? shopLat,
    double? shopLon,
    double? customerLat,
    double? customerLon,
    String? routeDistance,
    String? routeInterval,
    String? errorMessage,
  }) {
    return LongdoMapRouteState(
      status: status ?? this.status,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      locationServiceStatus:
          locationServiceStatus ?? this.locationServiceStatus,
      showLocationServiceDialog:
          showLocationServiceDialog ?? this.showLocationServiceDialog,
      isTracking: isTracking ?? this.isTracking,
      isRouteSearching: isRouteSearching ?? this.isRouteSearching,
      currentLat: currentLat ?? this.currentLat,
      currentLon: currentLon ?? this.currentLon,
      shopLat: shopLat ?? this.shopLat,
      shopLon: shopLon ?? this.shopLon,
      customerLat: customerLat ?? this.customerLat,
      customerLon: customerLon ?? this.customerLon,
      routeDistance: routeDistance ?? this.routeDistance,
      routeInterval: routeInterval ?? this.routeInterval,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        permissionStatus,
        locationServiceStatus,
        showLocationServiceDialog,
        isTracking,
        isRouteSearching,
        currentLat,
        currentLon,
        shopLat,
        shopLon,
        customerLat,
        customerLon,
        routeDistance,
        routeInterval,
        errorMessage,
      ];
}
