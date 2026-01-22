import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rider_map_poc/modules/rider_map/data/mock_route_data.dart';

/// Custom marker icons - วาดด้วย Canvas
class MapMarkerIcons {
  static BitmapDescriptor? _riderIcon;
  static BitmapDescriptor? _pickupIcon;
  static BitmapDescriptor? _deliveryIcon;

  /// Rider marker - มอเตอร์ไซค์สีฟ้า
  static BitmapDescriptor get riderIcon => _riderIcon ?? BitmapDescriptor.defaultMarker;

  /// Pickup marker - ร้านค้าสีส้ม
  static BitmapDescriptor get pickupIcon => _pickupIcon ?? BitmapDescriptor.defaultMarker;

  /// Delivery marker - ธงสีเขียว
  static BitmapDescriptor get deliveryIcon => _deliveryIcon ?? BitmapDescriptor.defaultMarker;

  /// โหลด icons ทั้งหมด (เรียกครั้งเดียวตอน app start)
  static Future<void> initialize() async {
    if (_riderIcon != null) return; // Already initialized

    _riderIcon = await _createMarkerIcon(
      icon: Icons.two_wheeler,
      backgroundColor: Colors.blue,
    );
    _pickupIcon = await _createMarkerIcon(
      icon: Icons.store,
      backgroundColor: Colors.orange,
    );
    _deliveryIcon = await _createMarkerIcon(
      icon: Icons.flag,
      backgroundColor: Colors.green,
    );
  }

  /// สร้าง marker icon จาก Material Icon
  static Future<BitmapDescriptor> _createMarkerIcon({
    required IconData icon,
    required Color backgroundColor,
    double size = 60,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    // วาดพื้นหลังวงกลม
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, bgPaint);

    // วาดขอบขาว
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 2, borderPaint);

    // วาด icon
    final textPainter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size * 0.5,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      )
      ..layout();

    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }
}

/// Default polyline styles
class MapPolylineStyles {
  /// เส้นทางที่เหลือ - สีฟ้า
  static const Color remainingRouteColor = Colors.blue;

  /// เส้นทางที่ผ่านมาแล้ว - สีเทา
  static final Color traveledRouteColor = Colors.grey.shade400;

  /// ความหนาของเส้น
  static const int polylineWidth = 5;
}

/// Stateless widget that displays the Google Map with markers and polylines
class RiderMapWidget extends StatefulWidget {
  final LatLng riderPosition;
  final int currentRouteIndex;
  final List<LatLng> routePoints;
  final void Function(GoogleMapController) onMapCreated;

  const RiderMapWidget({
    super.key,
    required this.riderPosition,
    required this.currentRouteIndex,
    required this.routePoints,
    required this.onMapCreated,
  });

  @override
  State<RiderMapWidget> createState() => _RiderMapWidgetState();
}

class _RiderMapWidgetState extends State<RiderMapWidget> {
  final _mapKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      key: _mapKey,
      initialCameraPosition: const CameraPosition(
        target: MockRouteData.riderStartPosition,
        zoom: 15,
      ),
      markers: _buildMarkers(),
      polylines: _buildPolylines(),
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      onMapCreated: widget.onMapCreated,
    );
  }

  Set<Marker> _buildMarkers() {
    return {
      Marker(
        markerId: const MarkerId('rider'),
        position: widget.riderPosition,
        icon: MapMarkerIcons.riderIcon,
        anchor: const Offset(0.5, 0.5),
        zIndex: 3,
        infoWindow: const InfoWindow(title: 'Rider'),
      ),
      Marker(
        markerId: const MarkerId('pickup'),
        position: MockRouteData.pickupLocation,
        icon: MapMarkerIcons.pickupIcon,
        infoWindow: const InfoWindow(
          title: 'Pickup Point',
          snippet: 'Siam Paragon',
        ),
        zIndex: 2,
      ),
      Marker(
        markerId: const MarkerId('delivery'),
        position: MockRouteData.deliveryLocation,
        icon: MapMarkerIcons.deliveryIcon,
        infoWindow: const InfoWindow(
          title: 'Delivery Point',
          snippet: 'Central World',
        ),
        zIndex: 2,
      ),
    };
  }

  Set<Polyline> _buildPolylines() {
    final traveledPoints = widget.routePoints.sublist(0, widget.currentRouteIndex + 1);
    final remainingPoints = widget.routePoints.sublist(widget.currentRouteIndex);

    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: remainingPoints,
        color: MapPolylineStyles.remainingRouteColor,
        width: MapPolylineStyles.polylineWidth,
      ),
      Polyline(
        polylineId: const PolylineId('traveled'),
        points: traveledPoints,
        color: MapPolylineStyles.traveledRouteColor,
        width: MapPolylineStyles.polylineWidth,
      ),
    };
  }
}
