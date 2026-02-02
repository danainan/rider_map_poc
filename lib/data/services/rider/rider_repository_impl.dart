import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:rider_map_poc/data/services/routes/routes_service.dart';
import 'package:rider_map_poc/data/services/rider/rider_repository.dart';

/// Implementation ของ RiderRepository
/// ใช้ RoutesService ในการดึงเส้นทางจาก Google Routes API
@Injectable(as: RiderRepository)
class RiderRepositoryImpl implements RiderRepository {
  final RoutesService _routesService;

  RiderRepositoryImpl(this._routesService);

  @override
  Future<RiderRouteResult> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final response = await _routesService.getRoute(
        origin: origin,
        destination: destination,
      );

      return RiderRouteResult(
        polylinePoints: response.polylinePoints,
        distance: response.distance,
        duration: response.duration,
      );
    } catch (e) {
      return RiderRouteResult.error(e.toString());
    }
  }

  @override
  Future<RiderMultiRouteResult> getMultiStopRoute({
    required LatLng riderLocation,
    required LatLng shopLocation,
    required LatLng customerLocation,
  }) async {
    try {
      // ดึงเส้นทาง rider -> shop
      final riderToShop = await _routesService.getRoute(
        origin: riderLocation,
        destination: shopLocation,
      );

      // ดึงเส้นทาง shop -> customer
      final shopToCustomer = await _routesService.getRoute(
        origin: shopLocation,
        destination: customerLocation,
      );

      // คำนวณระยะทางรวม
      final totalDistance = _combineDuration(
        riderToShop.distance,
        shopToCustomer.distance,
      );

      // คำนวณเวลารวม
      final totalDuration = _combineDuration(
        riderToShop.duration,
        shopToCustomer.duration,
      );

      return RiderMultiRouteResult(
        riderToShopPoints: riderToShop.polylinePoints,
        shopToCustomerPoints: shopToCustomer.polylinePoints,
        totalDistance: totalDistance,
        totalDuration: totalDuration,
        riderToShopDistance: riderToShop.distance,
        riderToShopDuration: riderToShop.duration,
        shopToCustomerDistance: shopToCustomer.distance,
        shopToCustomerDuration: shopToCustomer.duration,
      );
    } catch (e) {
      return RiderMultiRouteResult.error(e.toString());
    }
  }

  String _combineDuration(String duration1, String duration2) {
    // Simple combination - แสดงผลรวม
    return '$duration1 + $duration2';
  }
}
