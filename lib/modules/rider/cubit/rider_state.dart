part of 'rider_cubit.dart';

/// สถานะของ Location Permission
enum LocationPermissionStatus {
  initial,
  checking,
  granted,
  denied,
  deniedForever,
}

/// สถานะของ Location Service (GPS)
enum LocationServiceStatus {
  initial,
  checking,
  enabled,
  disabled,
}

/// สถานะการโหลดเส้นทาง
enum RouteLoadingStatus {
  initial,
  loading,
  loaded,
  error,
}

/// สถานะของ Rider
enum RiderDeliveryStatus {
  idle,
  headingToShop,
  arrivedAtShop,
  headingToCustomer,
  delivered,
}

/// Camera action สำหรับควบคุม GoogleMap
enum RiderCameraAction {
  none,
  centerOnRider,
  fitAllMarkers,
  followRider,
}

/// State หลักของ RiderCubit
final class RiderState extends Equatable {
  const RiderState({
    // Permission & Service Status
    this.locationPermissionStatus = LocationPermissionStatus.initial,
    this.locationServiceStatus = LocationServiceStatus.initial,
    this.showLocationServiceDialog = false,
    // Rider Position
    this.riderPosition,
    this.isTrackingLocation = false,
    // Route
    this.routeLoadingStatus = RouteLoadingStatus.initial,
    this.riderToShopPoints = const [],
    this.shopToCustomerPoints = const [],
    this.riderToShopDistance = '',
    this.riderToShopDuration = '',
    this.shopToCustomerDistance = '',
    this.shopToCustomerDuration = '',
    this.totalDistance = '',
    this.totalDuration = '',
    this.routeErrorMessage,
    // Delivery Status
    this.deliveryStatus = RiderDeliveryStatus.idle,
    // Camera
    this.cameraAction = RiderCameraAction.none,
    this.isFollowingRider = true,
    // Map
    this.isMapReady = false,
    // Error
    this.errorMessage,
  });

  // Permission & Service Status
  final LocationPermissionStatus locationPermissionStatus;
  final LocationServiceStatus locationServiceStatus;
  final bool showLocationServiceDialog;

  // Rider Position
  final LatLng? riderPosition;
  final bool isTrackingLocation;

  // Route Data
  final RouteLoadingStatus routeLoadingStatus;
  final List<LatLng> riderToShopPoints;
  final List<LatLng> shopToCustomerPoints;
  final String riderToShopDistance;
  final String riderToShopDuration;
  final String shopToCustomerDistance;
  final String shopToCustomerDuration;
  final String totalDistance;
  final String totalDuration;
  final String? routeErrorMessage;

  // Delivery Status
  final RiderDeliveryStatus deliveryStatus;

  // Camera Control
  final RiderCameraAction cameraAction;
  final bool isFollowingRider;

  // Map
  final bool isMapReady;

  // Error
  final String? errorMessage;

  /// รวม polyline points ทั้งหมด
  List<LatLng> get allRoutePoints => [...riderToShopPoints, ...shopToCustomerPoints];

  /// เช็คว่าพร้อมแสดงแผนที่หรือยัง
  bool get isReadyToShowMap =>
      locationPermissionStatus == LocationPermissionStatus.granted &&
      locationServiceStatus == LocationServiceStatus.enabled;

  /// เช็คว่ามีเส้นทางหรือยัง
  bool get hasRoute => riderToShopPoints.isNotEmpty || shopToCustomerPoints.isNotEmpty;

  RiderState copyWith({
    LocationPermissionStatus? locationPermissionStatus,
    LocationServiceStatus? locationServiceStatus,
    bool? showLocationServiceDialog,
    LatLng? riderPosition,
    bool? isTrackingLocation,
    RouteLoadingStatus? routeLoadingStatus,
    List<LatLng>? riderToShopPoints,
    List<LatLng>? shopToCustomerPoints,
    String? riderToShopDistance,
    String? riderToShopDuration,
    String? shopToCustomerDistance,
    String? shopToCustomerDuration,
    String? totalDistance,
    String? totalDuration,
    String? routeErrorMessage,
    RiderDeliveryStatus? deliveryStatus,
    RiderCameraAction? cameraAction,
    bool? isFollowingRider,
    bool? isMapReady,
    String? errorMessage,
  }) {
    return RiderState(
      locationPermissionStatus: locationPermissionStatus ?? this.locationPermissionStatus,
      locationServiceStatus: locationServiceStatus ?? this.locationServiceStatus,
      showLocationServiceDialog: showLocationServiceDialog ?? this.showLocationServiceDialog,
      riderPosition: riderPosition ?? this.riderPosition,
      isTrackingLocation: isTrackingLocation ?? this.isTrackingLocation,
      routeLoadingStatus: routeLoadingStatus ?? this.routeLoadingStatus,
      riderToShopPoints: riderToShopPoints ?? this.riderToShopPoints,
      shopToCustomerPoints: shopToCustomerPoints ?? this.shopToCustomerPoints,
      riderToShopDistance: riderToShopDistance ?? this.riderToShopDistance,
      riderToShopDuration: riderToShopDuration ?? this.riderToShopDuration,
      shopToCustomerDistance: shopToCustomerDistance ?? this.shopToCustomerDistance,
      shopToCustomerDuration: shopToCustomerDuration ?? this.shopToCustomerDuration,
      totalDistance: totalDistance ?? this.totalDistance,
      totalDuration: totalDuration ?? this.totalDuration,
      routeErrorMessage: routeErrorMessage ?? this.routeErrorMessage,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      cameraAction: cameraAction ?? this.cameraAction,
      isFollowingRider: isFollowingRider ?? this.isFollowingRider,
      isMapReady: isMapReady ?? this.isMapReady,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        locationPermissionStatus,
        locationServiceStatus,
        showLocationServiceDialog,
        riderPosition,
        isTrackingLocation,
        routeLoadingStatus,
        riderToShopPoints,
        shopToCustomerPoints,
        riderToShopDistance,
        riderToShopDuration,
        shopToCustomerDistance,
        shopToCustomerDuration,
        totalDistance,
        totalDuration,
        routeErrorMessage,
        deliveryStatus,
        cameraAction,
        isFollowingRider,
        isMapReady,
        errorMessage,
      ];
}
