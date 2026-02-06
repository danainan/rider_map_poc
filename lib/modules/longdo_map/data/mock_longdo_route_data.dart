/// Mock location data for Longdo Map POC
/// เก็บแค่พิกัดร้านค้าและลูกค้า — route ใช้ Longdo Routing API คำนวณให้
class MockLongdoRouteData {
  MockLongdoRouteData._();

  // ---- ร้านค้า (Siam Paragon) ----
  static const double shopLat = 13.7466;
  static const double shopLon = 100.5347;
  static const String shopTitle = 'ร้านค้า';
  static const String shopDetail = 'Siam Paragon';

  // ---- ลูกค้า (Central World) ----
  static const double customerLat = 13.7468;
  static const double customerLon = 100.5392;
  static const String customerTitle = 'ลูกค้า';
  static const String customerDetail = 'Central World';
}
