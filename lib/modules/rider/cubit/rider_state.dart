part of 'rider_cubit.dart';

enum LocationServiceStatus {
  initial,
  checking,
  enabled,
  disabled,
}

enum RouteLoadingStatus {
  initial,
  loading,
  loaded,
  error,
}

enum RiderDeliveryStatus {
  idle,
  headingToShop,
  arrivedAtShop,
  headingToCustomer,
  delivered,
}

enum RiderCameraAction {
  none,
  centerOnRider,
  fitAllMarkers,
  followRider,
}

final class RiderState extends Equatable {
  const RiderState({
    this.permissionStatus = PermissionRequestStatus.initial,
    this.locationServiceStatus = LocationServiceStatus.initial,
    this.showLocationServiceDialog = false,
    this.riderPosition,
    this.isTrackingLocation = false,
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
    this.deliveryStatus = RiderDeliveryStatus.idle,
    this.cameraAction = RiderCameraAction.none,
    this.isFollowingRider = true,
    this.isMapReady = false,
    this.errorMessage,
  });

  final PermissionRequestStatus permissionStatus;
  final LocationServiceStatus locationServiceStatus;
  final bool showLocationServiceDialog;
  final LatLng? riderPosition;
  final bool isTrackingLocation;
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
  final RiderDeliveryStatus deliveryStatus;
  final RiderCameraAction cameraAction;
  final bool isFollowingRider;
  final bool isMapReady;
  final String? errorMessage;

  List<LatLng> get allRoutePoints => [...riderToShopPoints, ...shopToCustomerPoints];

  bool get isReadyToShowMap =>
      permissionStatus == PermissionRequestStatus.granted &&
      locationServiceStatus == LocationServiceStatus.enabled;

  bool get hasRoute => riderToShopPoints.isNotEmpty || shopToCustomerPoints.isNotEmpty;

  RiderState copyWith({
    PermissionRequestStatus? permissionStatus,
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
      permissionStatus: permissionStatus ?? this.permissionStatus,
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
        permissionStatus,
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
