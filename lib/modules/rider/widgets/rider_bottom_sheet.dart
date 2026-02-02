import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rider_map_poc/modules/rider/cubit/rider_cubit.dart';


class RiderBottomSheet extends StatelessWidget {
  const RiderBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RiderCubit, RiderState>(
      builder: (context, state) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // Route Info
                _buildRouteInfo(context, state),

                const Divider(height: 1),

                // Action Buttons
                _buildActionButtons(context, state),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildRouteInfo(BuildContext context, RiderState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // To Shop
          Expanded(
            child: _RouteInfoCard(
              icon: Icons.store,
              iconColor: Colors.orange,
              title: 'ถึงร้าน',
              distance: state.riderToShopDistance.isEmpty
                  ? '-'
                  : state.riderToShopDistance,
              duration: state.riderToShopDuration.isEmpty
                  ? '-'
                  : state.riderToShopDuration,
              isActive: state.deliveryStatus == RiderDeliveryStatus.headingToShop,
            ),
          ),
          const SizedBox(width: 12),

          // To Customer
          Expanded(
            child: _RouteInfoCard(
              icon: Icons.person_pin_circle,
              iconColor: Colors.green,
              title: 'ถึงลูกค้า',
              distance: state.shopToCustomerDistance.isEmpty
                  ? '-'
                  : state.shopToCustomerDistance,
              duration: state.shopToCustomerDuration.isEmpty
                  ? '-'
                  : state.shopToCustomerDuration,
              isActive: state.deliveryStatus == RiderDeliveryStatus.headingToCustomer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, RiderState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          // Center Button
          IconButton(
            onPressed: () {
              context.read<RiderCubit>().centerOnRider();
            },
            icon: const Icon(Icons.my_location),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
            ),
          ),
          const SizedBox(width: 8),

          // Fit All Button
          IconButton(
            onPressed: () {
              context.read<RiderCubit>().fitAllMarkers();
            },
            icon: const Icon(Icons.zoom_out_map),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
            ),
          ),
          const SizedBox(width: 8),

          // Follow Toggle
          IconButton(
            onPressed: () {
              context.read<RiderCubit>().toggleFollowRider();
            },
            icon: Icon(
              state.isFollowingRider ? Icons.gps_fixed : Icons.gps_not_fixed,
              color: state.isFollowingRider ? Colors.blue : Colors.grey,
            ),
            style: IconButton.styleFrom(
              backgroundColor: state.isFollowingRider
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.grey[100],
            ),
          ),

          const Spacer(),

          // Main Action Button
          _buildMainActionButton(context, state),
        ],
      ),
    );
  }

  Widget _buildMainActionButton(BuildContext context, RiderState state) {
    switch (state.deliveryStatus) {
      case RiderDeliveryStatus.idle:
      case RiderDeliveryStatus.headingToShop:
        return ElevatedButton(
          onPressed: () {
            context.read<RiderCubit>().arrivedAtShop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('ถึงร้านแล้ว'),
        );

      case RiderDeliveryStatus.arrivedAtShop:
        return ElevatedButton(
          onPressed: () {
            context.read<RiderCubit>().startDeliveryToCustomer();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('รับอาหารแล้ว'),
        );

      case RiderDeliveryStatus.headingToCustomer:
        return ElevatedButton(
          onPressed: () {
            context.read<RiderCubit>().completeDelivery();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('ส่งสำเร็จ'),
        );

      case RiderDeliveryStatus.delivered:
        return ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('จัดส่งสำเร็จ ✓'),
        );
    }
  }
}

/// Status Badge widget
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final RiderDeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon, text) = switch (status) {
      RiderDeliveryStatus.idle => (Colors.grey, Icons.pending, 'รอรับงาน'),
      RiderDeliveryStatus.headingToShop => (Colors.orange, Icons.directions_bike, 'ไปรับอาหาร'),
      RiderDeliveryStatus.arrivedAtShop => (Colors.blue, Icons.store, 'ถึงร้าน'),
      RiderDeliveryStatus.headingToCustomer => (Colors.green, Icons.delivery_dining, 'กำลังส่ง'),
      RiderDeliveryStatus.delivered => (Colors.green, Icons.check_circle, 'สำเร็จ'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Route Info Card widget
class _RouteInfoCard extends StatelessWidget {
  const _RouteInfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.distance,
    required this.duration,
    required this.isActive,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String distance;
  final String duration;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? iconColor.withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(color: iconColor.withOpacity(0.5))
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Column(
                children: [
                  Text(
                    distance,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    duration,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                    ],
              ),
            
            ],
          ),
        ],
      ),
    );
  }
}
