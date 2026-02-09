import 'package:fpdart/fpdart.dart';
import 'package:rider_map_poc/data/models/longdo_route/longdo_route_geojson.dart';

/// Service สำหรับยิง Longdo Routing Web Service (GeoJSON endpoint)
abstract class LongdoRoutingService {
  /// คำนวณเส้นทางจาก (flat, flon) → (tlat, tlon)
  /// คืน GeoJSON FeatureCollection ที่มี Polyline แต่ละ section
  Future<Either<String, LongdoRouteGeoJson>> calculateRoute({
    required double flat,
    required double flon,
    required double tlat,
    required double tlon,
    String mode,
    int type,
  });
}
