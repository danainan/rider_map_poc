/// Mock location data for Longdo Map Navigation
class LongdoNavigationMockData {
  LongdoNavigationMockData._();

  /// ร้านค้า - Siam Paragon Food Court
  static const double shopLat = 13.7466;
  static const double shopLon = 100.5347;
  static const String shopName = 'ร้านอาหาร Siam Paragon';
  static const String shopAddress = 'Siam Paragon, Pathum Wan, Bangkok';

  /// ลูกค้า - Central World
  static const double customerLat = 13.7468;
  static const double customerLon = 100.5392;
  static const String customerName = 'ลูกค้า - Central World';
  static const String customerAddress = 'Central World, Ratchaprasong, Bangkok';

  /// Default camera position (centered between shop and customer)
  static const double defaultCameraLat = 13.7467;
  static const double defaultCameraLon = 100.5370;
}
