import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Mock data สำหรับ Rider module
/// จำลองตำแหน่งร้านค้าและลูกค้าในกรุงเทพฯ
class RiderMockData {
  RiderMockData._();

  /// ตำแหน่งร้านค้า - Siam Paragon
  static const LatLng shopLocation = LatLng(13.7466, 100.5347);
  static const String shopName = 'ร้านอาหาร Siam Paragon';
  static const String shopAddress = 'สยามพารากอน, ปทุมวัน, กรุงเทพฯ';

  /// ตำแหน่งลูกค้า - Central World
  static const LatLng customerLocation = LatLng(13.7468, 100.5392);
  static const String customerName = 'คุณสมชาย';
  static const String customerAddress = 'เซ็นทรัลเวิลด์, ปทุมวัน, กรุงเทพฯ';

  /// ศูนย์กลางแผนที่ - Bangkok
  static const LatLng mapCenter = LatLng(13.7563, 100.5018);

  /// Default zoom level
  static const double defaultZoom = 15.0;
}
