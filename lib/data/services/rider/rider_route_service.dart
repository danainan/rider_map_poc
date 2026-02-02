import 'package:google_maps_flutter/google_maps_flutter.dart';

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

/// Rider Route Service - ดึงเส้นทางจาก Google Routes API
abstract class RiderRouteService {
  /// ดึงเส้นทางหลายช่วง (rider -> shop -> customer)
  Future<RiderMultiRouteResult> getMultiStopRoute({
    required LatLng riderLocation,
    required LatLng shopLocation,
    required LatLng customerLocation,
  });
}
