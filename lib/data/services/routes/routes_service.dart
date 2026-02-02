import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Route response model
class RouteResponse {
  final List<LatLng> polylinePoints;
  final String distance;
  final String duration;

  const RouteResponse({
    required this.polylinePoints,
    required this.distance,
    required this.duration,
  });
}

/// Routes Service interface - uses Google Routes API
abstract class RoutesService {
  /// Get route between two points
  Future<RouteResponse> getRoute({
    required LatLng origin,
    required LatLng destination,
  });
}
