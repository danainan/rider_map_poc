import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rider_map_poc/modules/rider_map/bloc/rider_map_bloc.dart';
import 'package:rider_map_poc/modules/rider_map/bloc/rider_map_event.dart';
import 'package:rider_map_poc/modules/rider_map/bloc/rider_map_state.dart';
import 'package:rider_map_poc/modules/rider_map/data/mock_route_data.dart';
import 'package:rider_map_poc/modules/rider_map/widgets/map_control_buttons.dart';
import 'package:rider_map_poc/modules/rider_map/widgets/rider_info_card.dart';

class RiderMapPage extends StatelessWidget {
  const RiderMapPage({super.key, this.orderId});

  final String? orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RiderMapBloc()..add(const InitializeMap()),
      child: const _RiderMapView(),
    );
  }
}

class _RiderMapView extends StatelessWidget {
  const _RiderMapView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Tracking'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 2,
      ),
      body: BlocBuilder<RiderMapBloc, RiderMapState>(
        builder: (context, state) {
          return Stack(
            children: [
              // Google Map
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: MockRouteData.riderStartPosition,
                  zoom: 15,
                ),
                markers: state.markers,
                polylines: state.polylines,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (controller) {
                  context.read<RiderMapBloc>().setMapController(controller);
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
                    context.read<RiderMapBloc>().add(const StartRiderSimulation());
                  },
                  onStopSimulation: () {
                    context.read<RiderMapBloc>().add(const StopRiderSimulation());
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
                    context.read<RiderMapBloc>().add(const CenterOnRider());
                  },
                  onFitAll: () {
                    context.read<RiderMapBloc>().add(const FitAllMarkers());
                  },
                  onToggleFollow: () {
                    context.read<RiderMapBloc>().add(const ToggleFollowRider());
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
