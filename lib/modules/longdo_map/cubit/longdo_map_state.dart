part of 'longdo_map_cubit.dart';

enum LongdoMapStatus {
  initial,
  loading,
  mapReady,
  tracking,
  locationError,
}

enum LongdoLocationServiceStatus {
  initial,
  checking,
  enabled,
  disabled,
}

final class LongdoMapState extends Equatable {
  const LongdoMapState({
    this.status = LongdoMapStatus.initial,
    this.permissionStatus = PermissionRequestStatus.initial,
    this.locationServiceStatus = LongdoLocationServiceStatus.initial,
    this.showLocationServiceDialog = false,
    this.isTracking = false,
    this.currentLat = 0,
    this.currentLon = 0,
    this.errorMessage,
  });

  final LongdoMapStatus status;
  final PermissionRequestStatus permissionStatus;
  final LongdoLocationServiceStatus locationServiceStatus;
  final bool showLocationServiceDialog;
  final bool isTracking;
  final double currentLat;
  final double currentLon;
  final String? errorMessage;

  bool get isLocationReady =>
      permissionStatus == PermissionRequestStatus.granted &&
      locationServiceStatus == LongdoLocationServiceStatus.enabled;

  LongdoMapState copyWith({
    LongdoMapStatus? status,
    PermissionRequestStatus? permissionStatus,
    LongdoLocationServiceStatus? locationServiceStatus,
    bool? showLocationServiceDialog,
    bool? isTracking,
    double? currentLat,
    double? currentLon,
    String? errorMessage,
  }) {
    return LongdoMapState(
      status: status ?? this.status,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      locationServiceStatus:
          locationServiceStatus ?? this.locationServiceStatus,
      showLocationServiceDialog:
          showLocationServiceDialog ?? this.showLocationServiceDialog,
      isTracking: isTracking ?? this.isTracking,
      currentLat: currentLat ?? this.currentLat,
      currentLon: currentLon ?? this.currentLon,
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
        currentLat,
        currentLon,
        errorMessage,
      ];
}
