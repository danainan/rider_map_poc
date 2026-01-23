import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rider_map_poc/core/di/injectable.dart';
import 'package:rider_map_poc/modules/rider_map/bloc/rider_map_bloc.dart';
import 'package:rider_map_poc/modules/rider_map/data/mock_route_data.dart';
import 'package:rider_map_poc/modules/rider_map/widgets/map_control_buttons.dart';
import 'package:rider_map_poc/modules/rider_map/widgets/rider_info_card.dart';
import 'package:rider_map_poc/modules/rider_map/widgets/rider_map_widget.dart';

class RiderMapPage extends StatefulWidget {
  const RiderMapPage({super.key});

  @override
  State<RiderMapPage> createState() => _RiderMapPageState();
}

class _RiderMapPageState extends State<RiderMapPage> {
  GoogleMapController? _mapController;
  final RiderMapBloc _riderMapBloc = getIt<RiderMapBloc>();
  bool _isMarkersReady = false;

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
    // Request location permission first, then initialize with current location
    _riderMapBloc.add(const RequestLocationPermission());
  }

  Future<void> _initializeMarkers() async {
    await MapMarkerIcons.initialize();
    if (mounted) {
      setState(() => _isMarkersReady = true);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _riderMapBloc.close();
    super.dispose();
  }

  void _handleCameraAction(RiderMapState state) {
    if (_mapController == null) return;

    switch (state.cameraAction) {
      case CameraAction.centerOnRider:
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(state.riderPosition, 16),
        );
        break;
      case CameraAction.followRider:
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(state.riderPosition),
        );
        break;
      case CameraAction.fitAllMarkers:
        _fitAllMarkers(state);
        break;
      case CameraAction.none:
        break;
    }
  }

  void _fitAllMarkers(RiderMapState state) {
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

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isMarkersReady) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Rider Tracking'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return BlocProvider.value(
      value: _riderMapBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rider Tracking'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          elevation: 2,
        ),
        body: BlocConsumer<RiderMapBloc, RiderMapState>(
          listenWhen: (previous, current) =>
              current.cameraAction != CameraAction.none &&
              previous.cameraAction != current.cameraAction,
          listener: (context, state) {
            _handleCameraAction(state);
            // Reset camera action after handling
            context.read<RiderMapBloc>().add(const ResetCameraAction());
          },
          builder: (context, state) {
            final bloc = context.read<RiderMapBloc>();

            return Stack(
              children: [
                // Google Map Widget
                RiderMapWidget(
                  riderPosition: state.riderPosition,
                  currentRouteIndex: state.currentRouteIndex,
                  routePoints: bloc.routePoints,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    bloc.add(const MapControllerReady());
                  },
                ),

                // Rider Info Card (Bottom)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: RiderInfoCard(
                    riderStatus: state.riderStatus,
                    estimatedTime: state.estimatedTime,
                    estimatedDistance: state.estimatedDistance,
                    isSimulationRunning: state.isSimulationRunning,
                    onStartSimulation: () {
                      bloc.add(const StartRiderSimulation());
                    },
                    onStopSimulation: () {
                      bloc.add(const StopRiderSimulation());
                    },
                    onCenterRider: () {
                      bloc.add(const CenterOnRider());
                    },
                  ),
                ),

                // Map Control Buttons (Right side)
                Positioned(
                  right: 16,
                  top: 16,
                  child: MapControlButtons(
                    isFollowingRider: state.isFollowingRider,
                    onCenterRider: () {
                      bloc.add(const CenterOnRider());
                    },
                    onFitAll: () {
                      bloc.add(const FitAllMarkers());
                    },
                    onToggleFollow: () {
                      bloc.add(const ToggleFollowRider());
                    },
                  ),
                ),

                // Status Badge (Top Center)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _StatusBadge(status: state.riderStatus),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final RiderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (status) {
      RiderStatus.idle => ('Ready to Start', Colors.grey),
      RiderStatus.headingToPickup => ('Heading to Pickup', Colors.orange),
      RiderStatus.arrivedAtPickup => ('Arrived at Pickup', Colors.blue),
      RiderStatus.headingToDelivery => ('On the Way', Colors.green),
      RiderStatus.delivered => ('Delivered! 🎉', Colors.purple),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
