import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Mock route data for POC - simulates real road coordinates in Bangkok
/// This avoids calling the real Google Directions API during development
class MockRouteData {
  MockRouteData._();

  /// Pickup location - Siam Paragon, Bangkok
  static const LatLng pickupLocation = LatLng(13.7466, 100.5347);

  /// Delivery location - Central World, Bangkok
  static const LatLng deliveryLocation = LatLng(13.7468, 100.5392);

  /// Rider starting position (near pickup)
  static const LatLng riderStartPosition = LatLng(13.7433, 100.5311);

  /// Initial map center - Bangkok
  static const LatLng bangkokCenter = LatLng(13.7563, 100.5018);

  /// Mock route points following real roads from Rider -> Pickup -> Delivery
  /// These coordinates follow actual roads in Bangkok for realistic appearance
  static List<LatLng> getMockRoutePoints() {
    return const [
      // Rider starting position
      LatLng(13.7433, 100.5311),
      LatLng(13.7438, 100.5318),
      LatLng(13.7442, 100.5324),
      LatLng(13.7447, 100.5330),
      LatLng(13.7452, 100.5336),
      LatLng(13.7458, 100.5341),
      // Approaching pickup point
      LatLng(13.7462, 100.5344),
      LatLng(13.7466, 100.5347), // Pickup point (Siam Paragon)
      // From pickup to delivery
      LatLng(13.7467, 100.5352),
      LatLng(13.7467, 100.5358),
      LatLng(13.7468, 100.5365),
      LatLng(13.7468, 100.5372),
      LatLng(13.7468, 100.5380),
      LatLng(13.7468, 100.5386),
      LatLng(13.7468, 100.5392), // Delivery point (Central World)
    ];
  }

  /// Get route from rider to pickup only
  static List<LatLng> getRiderToPickupRoute() {
    return getMockRoutePoints()
        .takeWhile((point) => point != pickupLocation)
        .toList()
      ..add(pickupLocation);
  }

  /// Get route from pickup to delivery only
  static List<LatLng> getPickupToDeliveryRoute() {
    final allPoints = getMockRoutePoints();
    final pickupIndex = allPoints.indexOf(pickupLocation);
    return allPoints.sublist(pickupIndex);
  }

  /// Calculate estimated time based on route distance (mock)
  static String getEstimatedTime() {
    return '8 mins';
  }

  /// Calculate estimated distance (mock)
  static String getEstimatedDistance() {
    return '1.2 km';
  }
}
