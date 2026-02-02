import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rider_map_poc/modules/route_navigation/data/mock_location_data.dart';

/// Custom marker icons for route navigation
class RouteMarkerIcons {
  static BitmapDescriptor? riderIcon;
  static BitmapDescriptor? restaurantIcon;
  static BitmapDescriptor? customerIcon;

  static Future<void> initialize() async {
    riderIcon = await _createCustomMarkerBitmap(
      icon: Icons.delivery_dining,
      backgroundColor: Colors.blue,
    );
    restaurantIcon = await _createCustomMarkerBitmap(
      icon: Icons.restaurant,
      backgroundColor: Colors.orange,
    );
    customerIcon = await _createCustomMarkerBitmap(
      icon: Icons.person_pin_circle,
      backgroundColor: Colors.green,
    );
  }

  static Future<BitmapDescriptor> _createCustomMarkerBitmap({
    required IconData icon,
    required Color backgroundColor,
    double size = 48,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint();

    // Draw circle background
    paint.color = backgroundColor;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      paint,
    );

    // Draw white border
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 1.5,
      paint,
    );

    // Draw icon
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

class RouteMapWidget extends StatelessWidget {
  final LatLng? riderPosition;
  final LatLng restaurantLocation;
  final LatLng customerLocation;
  final List<LatLng> riderToRestaurantRoute;
  final List<LatLng> restaurantToCustomerRoute;
  final void Function(GoogleMapController) onMapCreated;

  const RouteMapWidget({
    super.key,
    required this.riderPosition,
    required this.restaurantLocation,
    required this.customerLocation,
    required this.riderToRestaurantRoute,
    required this.restaurantToCustomerRoute,
    required this.onMapCreated,
  });

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: riderPosition ?? MockLocationData.defaultCameraPosition,
        zoom: MockLocationData.defaultZoom,
      ),
      markers: _buildMarkers(),
      polylines: _buildPolylines(),
      onMapCreated: onMapCreated,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    // Rider marker
    if (riderPosition != null && RouteMarkerIcons.riderIcon != null) {
      markers.add(Marker(
        markerId: const MarkerId('rider'),
        position: riderPosition!,
        icon: RouteMarkerIcons.riderIcon!,
        anchor: const Offset(0.5, 0.5),
        infoWindow: const InfoWindow(title: 'คุณอยู่ที่นี่'),
      ));
    }

    // Restaurant marker
    if (RouteMarkerIcons.restaurantIcon != null) {
      markers.add(Marker(
        markerId: const MarkerId('restaurant'),
        position: restaurantLocation,
        icon: RouteMarkerIcons.restaurantIcon!,
        anchor: const Offset(0.5, 0.5),
        infoWindow: const InfoWindow(
          title: MockLocationData.restaurantName,
          snippet: MockLocationData.restaurantAddress,
        ),
      ));
    }

    // Customer marker
    if (RouteMarkerIcons.customerIcon != null) {
      markers.add(Marker(
        markerId: const MarkerId('customer'),
        position: customerLocation,
        icon: RouteMarkerIcons.customerIcon!,
        anchor: const Offset(0.5, 0.5),
        infoWindow: InfoWindow(
          title: MockLocationData.customerName,
          snippet: MockLocationData.customerAddress,
        ),
      ));
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    final polylines = <Polyline>{};

    // Rider to Restaurant route (Blue)
    if (riderToRestaurantRoute.isNotEmpty) {
      polylines.add(Polyline(
        polylineId: const PolylineId('rider_to_restaurant'),
        points: riderToRestaurantRoute,
        color: Colors.blue,
        width: 5,
        patterns: [],
      ));
    }

    // Restaurant to Customer route (Green)
    if (restaurantToCustomerRoute.isNotEmpty) {
      polylines.add(Polyline(
        polylineId: const PolylineId('restaurant_to_customer'),
        points: restaurantToCustomerRoute,
        color: Colors.green,
        width: 5,
        patterns: [],
      ));
    }

    return polylines;
  }
}
