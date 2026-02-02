import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rider_map_poc/data/services/routes/routes_service.dart';

/// Repository สำหรับจัดการข้อมูล Rider
/// ทำหน้าที่เป็น abstraction layer ระหว่าง Cubit กับ Data Source
abstract class RiderRepository {
  /// ดึงเส้นทางจาก origin ไป destination
  Future<RiderRouteResult> getRoute({
    required LatLng origin,
    required LatLng destination,
  });

  /// ดึงเส้นทางหลายช่วง (เช่น rider -> shop -> customer)
  Future<RiderMultiRouteResult> getMultiStopRoute({
    required LatLng riderLocation,
    required LatLng shopLocation,
    required LatLng customerLocation,
  });
}

/// ผลลัพธ์เส้นทางเดียว
class RiderRouteResult {
  final List<LatLng> polylinePoints;
  final String distance;
  final String duration;
  final bool isSuccess;
  final String? errorMessage;

  const RiderRouteResult({
    required this.polylinePoints,
    required this.distance,
    required this.duration,
    this.isSuccess = true,
    this.errorMessage,
  });

  factory RiderRouteResult.error(String message) {
    return RiderRouteResult(
      polylinePoints: [],
      distance: '',
      duration: '',
      isSuccess: false,
      errorMessage: message,
    );
  }
}

/// ผลลัพธ์เส้นทางหลายช่วง
class RiderMultiRouteResult {
  final List<LatLng> riderToShopPoints;
  final List<LatLng> shopToCustomerPoints;
  final String totalDistance;
  final String totalDuration;
  final String riderToShopDistance;
  final String riderToShopDuration;
  final String shopToCustomerDistance;
  final String shopToCustomerDuration;
  final bool isSuccess;
  final String? errorMessage;

  const RiderMultiRouteResult({
    required this.riderToShopPoints,
    required this.shopToCustomerPoints,
    required this.totalDistance,
    required this.totalDuration,
    required this.riderToShopDistance,
    required this.riderToShopDuration,
    required this.shopToCustomerDistance,
    required this.shopToCustomerDuration,
    this.isSuccess = true,
    this.errorMessage,
  });

  /// รวม polyline points ทั้งหมด
  List<LatLng> get allPoints => [...riderToShopPoints, ...shopToCustomerPoints];

  factory RiderMultiRouteResult.error(String message) {
    return RiderMultiRouteResult(
      riderToShopPoints: [],
      shopToCustomerPoints: [],
      totalDistance: '',
      totalDuration: '',
      riderToShopDistance: '',
      riderToShopDuration: '',
      shopToCustomerDistance: '',
      shopToCustomerDuration: '',
      isSuccess: false,
      errorMessage: message,
    );
  }
}
