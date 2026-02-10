import 'package:flutter/foundation.dart';
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
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5, // Update every 5 meters
      ),
    );

  //   late LocationSettings locationSettings;

  //   if (defaultTargetPlatform == TargetPlatform.android) {
  //     // --- ตั้งค่าสำหรับ ANDROID ---
  //     locationSettings = AndroidSettings(
  //       accuracy: LocationAccuracy.high, // หรือ LocationAccuracy.best
  //       distanceFilter: 0, // ตั้งเป็น 0 เพื่อรับค่าทุกครั้งที่มีการขยับ (Smooth สุด)
  //       forceLocationManager: true,
  //       intervalDuration: const Duration(seconds: 1), // อัพเดททุก 1 วินาที
  //       // การตั้งค่า Foreground Notification สำคัญมาก เพื่อให้ทำงานตอนพับหน้าจอได้
  //       foregroundNotificationConfig: const ForegroundNotificationConfig(
  //         notificationTitle: "กำลังนำทาง",
  //         notificationText: "แอปกำลังติดตามตำแหน่งของคุณ",
  //         enableWakeLock: true, // ป้องกัน CPU หลับ
  //       ),
  //     );
  //   } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
  //     // --- ตั้งค่าสำหรับ iOS ---
  //     locationSettings = AppleSettings(
  //       // สำคัญ: โหมดนี้จะใช้ Sensor Fusion (GPS + Gyro + Accelerometer) ช่วยคำนวณตอนรถวิ่ง
  //       accuracy: LocationAccuracy.bestForNavigation, 
  //       activityType: ActivityType.automotiveNavigation, // บอก iOS ว่าเรากำลังขับรถ
  //       distanceFilter: 0, // หรือ kCLDistanceFilterNone
  //       pauseLocationUpdatesAutomatically: false, // ห้ามหยุด update เมื่อรถติดไฟแดง
  //       showBackgroundLocationIndicator: true, // โชว์แถบสีฟ้าด้านบนเวลาพับแอป
  //     );
  //   } else {
  //     // --- ตั้งค่าสำหรับ Platform อื่นๆ ---
  //     locationSettings = const LocationSettings(
  //       accuracy: LocationAccuracy.high,
  //       distanceFilter: 5,
  //     );
  //   }

  //   return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  
}
