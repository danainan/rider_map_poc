import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rider_map_poc/modules/rider_map/data/mock_route_data.dart';

/// Marker icons holder - initialized once in parent page
class MapMarkerIcons {
  final BitmapDescriptor riderIcon;
  final BitmapDescriptor pickupIcon;
  final BitmapDescriptor deliveryIcon;

  const MapMarkerIcons({
    required this.riderIcon,
    required this.pickupIcon,
    required this.deliveryIcon,
  });

  /// Create custom marker icons asynchronously
  static Future<MapMarkerIcons> create() async {
    final riderIcon = await _createCustomMarkerBitmap(
      icon: Icons.two_wheeler,
      color: Colors.blue,
      size: 60,
    );
    final pickupIcon = await _createCustomMarkerBitmap(
      icon: Icons.store,
      color: Colors.orange,
      size: 60,
    );
    final deliveryIcon = await _createCustomMarkerBitmap(
      icon: Icons.flag,
      color: Colors.green,
      size: 60,
    );
    return MapMarkerIcons(
      riderIcon: riderIcon,
      pickupIcon: pickupIcon,
      deliveryIcon: deliveryIcon,
    );
  }

  static Future<BitmapDescriptor> _createCustomMarkerBitmap({
    required IconData icon,
    required Color color,
    required double size,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = color;

    // Draw circle background
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      paint,
    );

    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 2,
      borderPaint,
    );

    // Draw icon
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size * 0.5,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
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

/// Stateless widget that displays the Google Map with markers and polylines
class RiderMapWidget extends StatefulWidget {
  final LatLng riderPosition;
  final int currentRouteIndex;
  final List<LatLng> routePoints;
  final MapMarkerIcons markerIcons;
  final void Function(GoogleMapController) onMapCreated;

  const RiderMapWidget({
    super.key,
    required this.riderPosition,
    required this.currentRouteIndex,
    required this.routePoints,
    required this.markerIcons,
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
        icon: widget.markerIcons.riderIcon,
        anchor: const Offset(0.5, 0.5),
        zIndex: 3,
        infoWindow: const InfoWindow(title: 'Rider'),
      ),
      Marker(
        markerId: const MarkerId('pickup'),
        position: MockRouteData.pickupLocation,
        icon: widget.markerIcons.pickupIcon,
        infoWindow: const InfoWindow(
          title: 'Pickup Point',
          snippet: 'Siam Paragon',
        ),
        zIndex: 2,
      ),
      Marker(
        markerId: const MarkerId('delivery'),
        position: MockRouteData.deliveryLocation,
        icon: widget.markerIcons.deliveryIcon,
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
        color: Colors.blue.shade600,
        width: 5,
      ),
      Polyline(
        polylineId: const PolylineId('traveled'),
        points: traveledPoints,
        color: Colors.grey.shade400,
        width: 5,
      ),
    };
  }
}
