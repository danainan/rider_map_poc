import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Mock location data for route navigation
class MockLocationData {
  MockLocationData._();

  /// ร้านอาหาร - Siam Paragon Food Court
  static const LatLng restaurantLocation = LatLng(13.7466, 100.5347);
  static const String restaurantName = 'Siam Paragon Food Court';
  static const String restaurantAddress = 'Siam Paragon, Pathum Wan, Bangkok';

  /// ตำแหน่งลูกค้า - Central World
  static const LatLng customerLocation = LatLng(13.7468, 100.5392);
  static const String customerName = 'คุณสมชาย';
  static const String customerAddress = 'Central World, Ratchaprasong, Bangkok';

  /// Default camera position (Bangkok)
  static const LatLng defaultCameraPosition = LatLng(13.7466, 100.5370);
  static const double defaultZoom = 15.0;

  /// Get estimated time to restaurant (mock)
  static String getEstimatedTimeToRestaurant() => '5 นาที';

  /// Get estimated distance to restaurant (mock)
  static String getEstimatedDistanceToRestaurant() => '800 ม.';

  /// Get estimated time to customer (mock)
  static String getEstimatedTimeToCustomer() => '3 นาที';

  /// Get estimated distance to customer (mock)
  static String getEstimatedDistanceToCustomer() => '500 ม.';

  /// Get total estimated time (mock)
  static String getTotalEstimatedTime() => '8 นาที';

  /// Get total estimated distance (mock)
  static String getTotalEstimatedDistance() => '1.3 กม.';
}
