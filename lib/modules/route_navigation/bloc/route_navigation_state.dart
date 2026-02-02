part of 'route_navigation_bloc.dart';

/// Location service status
enum LocationServiceStatus {
  checking,
  enabled,
  disabled,
}

/// Location permission status
enum LocationPermissionStatus {
  initial,
  requesting,
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

/// Route loading status
enum RouteStatus {
  initial,
  loading,
  loaded,
  error,
}

/// Camera action
enum CameraAction {
  none,
  centerOnRider,
  fitAllMarkers,
  followRider,
}

/// State for RouteNavigationBloc
class RouteNavigationState extends Equatable {
  // Location data
  final LatLng? riderPosition;
  final LatLng restaurantLocation;
  final LatLng customerLocation;

  // Route data
  final List<LatLng> riderToRestaurantRoute;
  final List<LatLng> restaurantToCustomerRoute;
  final RouteStatus routeStatus;
  final String? routeErrorMessage;

  // Location service & permission
  final LocationServiceStatus locationServiceStatus;
  final LocationPermissionStatus locationPermissionStatus;
  final String? locationErrorMessage;

  // Tracking
  final bool isTrackingLocation;
  final bool isMapReady;

  // Route info
  final String estimatedTimeToRestaurant;
  final String estimatedDistanceToRestaurant;
  final String estimatedTimeToCustomer;
  final String estimatedDistanceToCustomer;

  // Camera
  final CameraAction cameraAction;

  const RouteNavigationState({
    this.riderPosition,
    this.restaurantLocation = MockLocationData.restaurantLocation,
    this.customerLocation = MockLocationData.customerLocation,
    this.riderToRestaurantRoute = const [],
    this.restaurantToCustomerRoute = const [],
    this.routeStatus = RouteStatus.initial,
    this.routeErrorMessage,
    this.locationServiceStatus = LocationServiceStatus.checking,
    this.locationPermissionStatus = LocationPermissionStatus.initial,
    this.locationErrorMessage,
    this.isTrackingLocation = false,
    this.isMapReady = false,
    this.estimatedTimeToRestaurant = '',
    this.estimatedDistanceToRestaurant = '',
    this.estimatedTimeToCustomer = '',
    this.estimatedDistanceToCustomer = '',
    this.cameraAction = CameraAction.none,
  });

  RouteNavigationState copyWith({
    LatLng? riderPosition,
    LatLng? restaurantLocation,
    LatLng? customerLocation,
    List<LatLng>? riderToRestaurantRoute,
    List<LatLng>? restaurantToCustomerRoute,
    RouteStatus? routeStatus,
    String? routeErrorMessage,
    LocationServiceStatus? locationServiceStatus,
    LocationPermissionStatus? locationPermissionStatus,
    String? locationErrorMessage,
    bool? isTrackingLocation,
    bool? isMapReady,
    String? estimatedTimeToRestaurant,
    String? estimatedDistanceToRestaurant,
    String? estimatedTimeToCustomer,
    String? estimatedDistanceToCustomer,
    CameraAction? cameraAction,
  }) {
    return RouteNavigationState(
      riderPosition: riderPosition ?? this.riderPosition,
      restaurantLocation: restaurantLocation ?? this.restaurantLocation,
      customerLocation: customerLocation ?? this.customerLocation,
      riderToRestaurantRoute: riderToRestaurantRoute ?? this.riderToRestaurantRoute,
      restaurantToCustomerRoute: restaurantToCustomerRoute ?? this.restaurantToCustomerRoute,
      routeStatus: routeStatus ?? this.routeStatus,
      routeErrorMessage: routeErrorMessage ?? this.routeErrorMessage,
      locationServiceStatus: locationServiceStatus ?? this.locationServiceStatus,
      locationPermissionStatus: locationPermissionStatus ?? this.locationPermissionStatus,
      locationErrorMessage: locationErrorMessage ?? this.locationErrorMessage,
      isTrackingLocation: isTrackingLocation ?? this.isTrackingLocation,
      isMapReady: isMapReady ?? this.isMapReady,
      estimatedTimeToRestaurant: estimatedTimeToRestaurant ?? this.estimatedTimeToRestaurant,
      estimatedDistanceToRestaurant: estimatedDistanceToRestaurant ?? this.estimatedDistanceToRestaurant,
      estimatedTimeToCustomer: estimatedTimeToCustomer ?? this.estimatedTimeToCustomer,
      estimatedDistanceToCustomer: estimatedDistanceToCustomer ?? this.estimatedDistanceToCustomer,
      cameraAction: cameraAction ?? CameraAction.none,
    );
  }

  /// Check if we have rider location
  bool get hasRiderLocation => riderPosition != null;

  /// Check if routes are loaded
  bool get hasRoutes => riderToRestaurantRoute.isNotEmpty || restaurantToCustomerRoute.isNotEmpty;

  /// Get all route points combined
  List<LatLng> get allRoutePoints => [...riderToRestaurantRoute, ...restaurantToCustomerRoute];

  @override
  List<Object?> get props => [
        riderPosition,
        restaurantLocation,
        customerLocation,
        riderToRestaurantRoute,
        restaurantToCustomerRoute,
        routeStatus,
        routeErrorMessage,
        locationServiceStatus,
        locationPermissionStatus,
        locationErrorMessage,
        isTrackingLocation,
        isMapReady,
        estimatedTimeToRestaurant,
        estimatedDistanceToRestaurant,
        estimatedTimeToCustomer,
        estimatedDistanceToCustomer,
        cameraAction,
      ];
}
