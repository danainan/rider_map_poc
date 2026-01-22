import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rider_map_poc/modules/rider_map/data/mock_route_data.dart';
import 'package:rider_map_poc/modules/rider_map/bloc/rider_map_event.dart';
import 'package:rider_map_poc/modules/rider_map/bloc/rider_map_state.dart';

class RiderMapBloc extends Bloc<RiderMapEvent, RiderMapState> {
  GoogleMapController? _mapController;
  Timer? _simulationTimer;
  final List<LatLng> _routePoints = MockRouteData.getMockRoutePoints();

  // Custom marker bitmaps
  BitmapDescriptor? _riderIcon;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _deliveryIcon;

  RiderMapBloc() : super(const RiderMapState()) {
    on<InitializeMap>(_onInitializeMap);
    on<StartRiderSimulation>(_onStartRiderSimulation);
    on<StopRiderSimulation>(_onStopRiderSimulation);
    on<UpdateRiderPosition>(_onUpdateRiderPosition);
    on<CenterOnRider>(_onCenterOnRider);
    on<FitAllMarkers>(_onFitAllMarkers);
    on<ToggleFollowRider>(_onToggleFollowRider);
    on<MapControllerReady>(_onMapControllerReady);
  }

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
    add(const MapControllerReady());
  }

  Future<void> _onMapControllerReady(
    MapControllerReady event,
    Emitter<RiderMapState> emit,
  ) async {
    emit(state.copyWith(isMapReady: true));
  }

  Future<void> _onInitializeMap(
    InitializeMap event,
    Emitter<RiderMapState> emit,
  ) async {
    // Create custom marker icons
    await _createMarkerIcons();

    // Create markers
    final markers = _createMarkers();

    // Create polylines
    final polylines = _createPolylines();

    emit(state.copyWith(
      markers: markers,
      polylines: polylines,
      riderPosition: MockRouteData.riderStartPosition,
      cameraTarget: MockRouteData.riderStartPosition,
      estimatedTime: MockRouteData.getEstimatedTime(),
      estimatedDistance: MockRouteData.getEstimatedDistance(),
    ));
  }

  Future<void> _createMarkerIcons() async {
    _riderIcon = await _createCustomMarkerBitmap(
      icon: Icons.two_wheeler,
      color: Colors.blue,
      size: 100,
    );
    _pickupIcon = await _createCustomMarkerBitmap(
      icon: Icons.store,
      color: Colors.orange,
      size: 90,
    );
    _deliveryIcon = await _createCustomMarkerBitmap(
      icon: Icons.flag,
      color: Colors.green,
      size: 90,
    );
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap({
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

  Set<Marker> _createMarkers() {
    return {
      // Rider marker
      Marker(
        markerId: const MarkerId('rider'),
        position: state.riderPosition,
        icon: _riderIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        anchor: const Offset(0.5, 0.5),
        zIndex: 3,
        infoWindow: const InfoWindow(title: 'Rider'),
      ),
      // Pickup marker
      Marker(
        markerId: const MarkerId('pickup'),
        position: MockRouteData.pickupLocation,
        icon: _pickupIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(
          title: 'Pickup Point',
          snippet: 'Siam Paragon',
        ),
        zIndex: 2,
      ),
      // Delivery marker
      Marker(
        markerId: const MarkerId('delivery'),
        position: MockRouteData.deliveryLocation,
        icon: _deliveryIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(
          title: 'Delivery Point',
          snippet: 'Central World',
        ),
        zIndex: 2,
      ),
    };
  }

  Set<Polyline> _createPolylines() {
    return {
      // Full route polyline
      Polyline(
        polylineId: const PolylineId('route'),
        points: _routePoints,
        color: Colors.blue.shade600,
        width: 5,
        patterns: [],
      ),
      // Traveled path (will be updated as rider moves)
      Polyline(
        polylineId: const PolylineId('traveled'),
        points: const [],
        color: Colors.grey.shade400,
        width: 5,
      ),
    };
  }

  void _onStartRiderSimulation(
    StartRiderSimulation event,
    Emitter<RiderMapState> emit,
  ) {
    if (state.isSimulationRunning) return;

    emit(state.copyWith(
      isSimulationRunning: true,
      riderStatus: RiderStatus.headingToPickup,
    ));

    _simulationTimer = Timer.periodic(
      const Duration(milliseconds: 800),
      (_) => add(const UpdateRiderPosition()),
    );
  }

  void _onStopRiderSimulation(
    StopRiderSimulation event,
    Emitter<RiderMapState> emit,
  ) {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    emit(state.copyWith(isSimulationRunning: false));
  }

  Future<void> _onUpdateRiderPosition(
    UpdateRiderPosition event,
    Emitter<RiderMapState> emit,
  ) async {
    final nextIndex = state.currentRouteIndex + 1;

    if (nextIndex >= _routePoints.length) {
      // Reached destination
      _simulationTimer?.cancel();
      _simulationTimer = null;
      emit(state.copyWith(
        isSimulationRunning: false,
        riderStatus: RiderStatus.delivered,
      ));
      return;
    }

    final newPosition = _routePoints[nextIndex];

    // Check status updates
    RiderStatus newStatus = state.riderStatus;
    if (newPosition == MockRouteData.pickupLocation) {
      newStatus = RiderStatus.arrivedAtPickup;
    } else if (state.riderStatus == RiderStatus.arrivedAtPickup &&
        nextIndex > _routePoints.indexOf(MockRouteData.pickupLocation)) {
      newStatus = RiderStatus.headingToDelivery;
    }

    // Update markers with new rider position
    final updatedMarkers = state.markers.map((marker) {
      if (marker.markerId.value == 'rider') {
        return marker.copyWith(positionParam: newPosition);
      }
      return marker;
    }).toSet();

    // Update polylines - show traveled path
    final traveledPoints = _routePoints.sublist(0, nextIndex + 1);
    final remainingPoints = _routePoints.sublist(nextIndex);

    final updatedPolylines = {
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

    emit(state.copyWith(
      riderPosition: newPosition,
      markers: updatedMarkers,
      polylines: updatedPolylines,
      currentRouteIndex: nextIndex,
      riderStatus: newStatus,
    ));

    // Animate camera to follow rider if enabled
    if (state.isFollowingRider && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLng(newPosition),
      );
    }
  }

  Future<void> _onCenterOnRider(
    CenterOnRider event,
    Emitter<RiderMapState> emit,
  ) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(state.riderPosition, 16),
      );
    }
  }

  Future<void> _onFitAllMarkers(
    FitAllMarkers event,
    Emitter<RiderMapState> emit,
  ) async {
    if (_mapController == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        [
          state.riderPosition.latitude,
          MockRouteData.pickupLocation.latitude,
          MockRouteData.deliveryLocation.latitude,
        ].reduce((a, b) => a < b ? a : b),
        [
          state.riderPosition.longitude,
          MockRouteData.pickupLocation.longitude,
          MockRouteData.deliveryLocation.longitude,
        ].reduce((a, b) => a < b ? a : b),
      ),
      northeast: LatLng(
        [
          state.riderPosition.latitude,
          MockRouteData.pickupLocation.latitude,
          MockRouteData.deliveryLocation.latitude,
        ].reduce((a, b) => a > b ? a : b),
        [
          state.riderPosition.longitude,
          MockRouteData.pickupLocation.longitude,
          MockRouteData.deliveryLocation.longitude,
        ].reduce((a, b) => a > b ? a : b),
      ),
    );

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  void _onToggleFollowRider(
    ToggleFollowRider event,
    Emitter<RiderMapState> emit,
  ) {
    emit(state.copyWith(isFollowingRider: !state.isFollowingRider));
  }

  @override
  Future<void> close() {
    _simulationTimer?.cancel();
    return super.close();
  }
}
