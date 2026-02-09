part of 'longdo_map_ws_cubit.dart';

enum LongdoMapWsStatus {
  initial,
  loading,
  mapReady,
  tracking,
  locationError,
}

enum LongdoWsLocationServiceStatus {
  initial,
  checking,
  enabled,
  disabled,
}

final class LongdoMapWsState extends Equatable {
  const LongdoMapWsState({
    this.status = LongdoMapWsStatus.initial,
    this.permissionStatus = PermissionRequestStatus.initial,
    this.locationServiceStatus = LongdoWsLocationServiceStatus.initial,
    this.showLocationServiceDialog = false,
    this.isTracking = false,
    this.isRouteLoading = false,
    this.currentLat = 0,
    this.currentLon = 0,
    // ร้านค้า (Siam Paragon)
    this.shopLat = 13.7466,
    this.shopLon = 100.5347,
    // ลูกค้า (Central World)
    this.customerLat = 13.7468,
    this.customerLon = 100.5392,
    this.routeGeoJson,
    this.routeJsonForJs,
    this.combinedDistanceText,
    this.combinedIntervalText,
    this.combinedFeatureCount = 0,
    this.errorMessage,
  });

  final LongdoMapWsStatus status;
  final PermissionRequestStatus permissionStatus;
  final LongdoWsLocationServiceStatus locationServiceStatus;
  final bool showLocationServiceDialog;
  final bool isTracking;
  final bool isRouteLoading;
  final double currentLat;
  final double currentLon;
  final double shopLat;
  final double shopLon;
  final double customerLat;
  final double customerLon;
  final LongdoRouteGeoJson? routeGeoJson;
  final String? routeJsonForJs;
  final String? combinedDistanceText;
  final String? combinedIntervalText;
  final int combinedFeatureCount;
  final String? errorMessage;

  bool get isLocationReady =>
      permissionStatus == PermissionRequestStatus.granted &&
      locationServiceStatus == LongdoWsLocationServiceStatus.enabled;

  bool get hasRoute => routeGeoJson != null;

  LongdoMapWsState copyWith({
    LongdoMapWsStatus? status,
    PermissionRequestStatus? permissionStatus,
    LongdoWsLocationServiceStatus? locationServiceStatus,
    bool? showLocationServiceDialog,
    bool? isTracking,
    bool? isRouteLoading,
    double? currentLat,
    double? currentLon,
    double? shopLat,
    double? shopLon,
    double? customerLat,
    double? customerLon,
    LongdoRouteGeoJson? routeGeoJson,
    String? routeJsonForJs,
    String? combinedDistanceText,
    String? combinedIntervalText,
    int? combinedFeatureCount,
    String? errorMessage,
  }) {
    return LongdoMapWsState(
      status: status ?? this.status,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      locationServiceStatus:
          locationServiceStatus ?? this.locationServiceStatus,
      showLocationServiceDialog:
          showLocationServiceDialog ?? this.showLocationServiceDialog,
      isTracking: isTracking ?? this.isTracking,
      isRouteLoading: isRouteLoading ?? this.isRouteLoading,
      currentLat: currentLat ?? this.currentLat,
      currentLon: currentLon ?? this.currentLon,
      shopLat: shopLat ?? this.shopLat,
      shopLon: shopLon ?? this.shopLon,
      customerLat: customerLat ?? this.customerLat,
      customerLon: customerLon ?? this.customerLon,
      routeGeoJson: routeGeoJson ?? this.routeGeoJson,
      routeJsonForJs: routeJsonForJs ?? this.routeJsonForJs,
      combinedDistanceText: combinedDistanceText ?? this.combinedDistanceText,
      combinedIntervalText: combinedIntervalText ?? this.combinedIntervalText,
      combinedFeatureCount: combinedFeatureCount ?? this.combinedFeatureCount,
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
        isRouteLoading,
        currentLat,
        currentLon,
        shopLat,
        shopLon,
        customerLat,
        customerLon,
        routeGeoJson,
        routeJsonForJs,
        combinedDistanceText,
        combinedIntervalText,
        combinedFeatureCount,
        errorMessage,
      ];
}
