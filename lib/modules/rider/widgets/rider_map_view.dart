import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rider_map_poc/core/utils/map_utils.dart';
import 'package:rider_map_poc/modules/rider/cubit/rider_cubit.dart';
import 'package:rider_map_poc/modules/rider/data/rider_mock_data.dart';
import 'package:rider_map_poc/modules/rider/widgets/rider_marker_builder.dart';

class RiderMapView extends StatefulWidget {
  const RiderMapView({super.key});

  @override
  State<RiderMapView> createState() => _RiderMapViewState();
}

class _RiderMapViewState extends State<RiderMapView> {
  GoogleMapController? _mapController;
  final Completer<GoogleMapController> _controllerCompleter = Completer();

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
  }

  Future<void> _initializeMarkers() async {
    await RiderMarkerBuilder.initialize();
    if (mounted) {
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RiderCubit, RiderState>(
      listenWhen: (previous, current) =>
          previous.cameraAction != current.cameraAction,
      listener: (context, state) {
        _handleCameraAction(state);
      },
      builder: (context, state) {
        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: state.riderPosition ?? RiderMockData.mapCenter,
            zoom: RiderMockData.defaultZoom,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
            if (!_controllerCompleter.isCompleted) {
              _controllerCompleter.complete(controller);
            }
            context.read<RiderCubit>().onMapReady();
          },
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          markers: _buildMarkers(state),
          polylines: _buildPolylines(state),
        );
      },
    );
  }

  Set<Marker> _buildMarkers(RiderState state) {
    final markers = <Marker>{};

    if (state.riderPosition != null && RiderMarkerBuilder.riderIcon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('rider'),
          position: state.riderPosition!,
          icon: RiderMarkerBuilder.riderIcon!,
          anchor: const Offset(0.5, 0.5),
         zIndexInt: 3,
        ),
      );
    }

    // Shop Marker
    if (RiderMarkerBuilder.shopIcon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('shop'),
          position: RiderMockData.shopLocation,
          icon: RiderMarkerBuilder.shopIcon!,
          infoWindow: const InfoWindow(
            title: RiderMockData.shopName,
            snippet: RiderMockData.shopAddress,
          ),
          zIndexInt: 2,
        ),
      );
    }

    // Customer Marker
    if (RiderMarkerBuilder.customerIcon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('customer'),
          position: RiderMockData.customerLocation,
          icon: RiderMarkerBuilder.customerIcon!,
          infoWindow: const InfoWindow(
            title: RiderMockData.customerName,
            snippet: RiderMockData.customerAddress,
          ),
          zIndexInt: 1,
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines(RiderState state) {
    final polylines = <Polyline>{};

    if (state.riderToShopPoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('rider_to_shop'),
          points: state.riderToShopPoints,
          color: Colors.blue,
          width: 5,
          patterns: state.deliveryStatus == RiderDeliveryStatus.headingToShop
              ? []
              : [PatternItem.dash(10), PatternItem.gap(10)],
        ),
      );
    }

    if (state.shopToCustomerPoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('shop_to_customer'),
          points: state.shopToCustomerPoints,
          color: Colors.green,
          width: 5,
          patterns: state.deliveryStatus == RiderDeliveryStatus.headingToCustomer
              ? []
              : [PatternItem.dash(10), PatternItem.gap(10)],
        ),
      );
    }

    return polylines;
  }

  void _handleCameraAction(RiderState state) {
    if (_mapController == null) return;

    switch (state.cameraAction) {
      case RiderCameraAction.none:
        break;

      case RiderCameraAction.centerOnRider:
        if (state.riderPosition != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(state.riderPosition!, 17),
          );
        }
        break;

      case RiderCameraAction.followRider:
        if (state.riderPosition != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(state.riderPosition!),
          );
        }
        break;

      case RiderCameraAction.fitAllMarkers:
        _fitAllMarkers(state);
        break;
    }

    if (state.cameraAction != RiderCameraAction.none) {
      context.read<RiderCubit>().resetCameraAction();
    }
  }

  void _fitAllMarkers(RiderState state) {
    final points = <LatLng>[
      if (state.riderPosition != null) state.riderPosition!,
      RiderMockData.shopLocation,
      RiderMockData.customerLocation,
    ];

    if (points.length < 2) return;

    final bounds = MapUtils.boundsFromLatLngList(points);

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }
}
