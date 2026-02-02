import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Builder สำหรับสร้าง Custom Marker Icons แบบ Canvas-based
/// เหมือนกับ RouteMarkerIcons ใน route_navigation
class RiderMarkerBuilder {
  RiderMarkerBuilder._();

  static BitmapDescriptor? _riderIcon;
  static BitmapDescriptor? _shopIcon;
  static BitmapDescriptor? _customerIcon;

  static BitmapDescriptor? get riderIcon => _riderIcon;
  static BitmapDescriptor? get shopIcon => _shopIcon;
  static BitmapDescriptor? get customerIcon => _customerIcon;

  /// Initialize all marker icons - เรียกใช้ก่อนแสดง map
  static Future<void> initialize() async {
    _riderIcon = await _createCustomMarkerBitmap(
      icon: Icons.delivery_dining,
      backgroundColor: Colors.blue,
    );
    _shopIcon = await _createCustomMarkerBitmap(
      icon: Icons.restaurant,
      backgroundColor: Colors.orange,
    );
    _customerIcon = await _createCustomMarkerBitmap(
      icon: Icons.person_pin_circle,
      backgroundColor: Colors.green,
    );
  }

  /// สร้าง Custom Marker ด้วย Canvas
  static Future<BitmapDescriptor> _createCustomMarkerBitmap({
    required IconData icon,
    required Color backgroundColor,
    double size = 48,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint();

    paint.color = backgroundColor;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      paint,
    );

    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 1.5,
      paint,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size * 0.5,
        fontFamily: icon.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }
}
