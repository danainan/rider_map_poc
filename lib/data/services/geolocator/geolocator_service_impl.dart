import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart' as injectable;
import 'package:rider_map_poc/data/models/permission/permission_request_status.dart';
import 'package:rider_map_poc/data/services/geolocator/geolocator_service.dart';
import 'package:rider_map_poc/data/services/permission_status/app_permission_status_service.dart';


@injectable.Injectable(as: GeolocatorService)
class GeolocatorServiceImpl implements GeolocatorService {
  GeolocatorServiceImpl(this._appPermissionStatusService);

  final AppPermissionStatusService _appPermissionStatusService;

  @override
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<Position> determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    final permissionStatus = await _appPermissionStatusService.requestLocationPermission();

    if (permissionStatus == PermissionRequestStatus.granted) {
      return Geolocator.getCurrentPosition();
    } else if (permissionStatus == PermissionRequestStatus.denied ||
        permissionStatus == PermissionRequestStatus.hasDeniedBefore) {
      return Future.error('Location permissions are denied.');
    }

    return Future.error('Unable to determine location permissions.');
  }

  @override
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      ),
    );
  }
}
