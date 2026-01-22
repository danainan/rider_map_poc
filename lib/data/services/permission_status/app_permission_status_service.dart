import 'package:rider_map_poc/data/models/permission/permission_request_status.dart';

abstract class AppPermissionStatusService {
  Future<PermissionRequestStatus> requestLocationPermission();
}
