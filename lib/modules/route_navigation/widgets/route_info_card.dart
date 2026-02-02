import 'package:flutter/material.dart';
import 'package:rider_map_poc/modules/route_navigation/bloc/route_navigation_bloc.dart';

class RouteInfoCard extends StatelessWidget {
  final RouteStatus routeStatus;
  final String estimatedTimeToRestaurant;
  final String estimatedDistanceToRestaurant;
  final String estimatedTimeToCustomer;
  final String estimatedDistanceToCustomer;
  final VoidCallback onRefreshRoute;
  final VoidCallback onCenterRider;

  const RouteInfoCard({
    super.key,
    required this.routeStatus,
    required this.estimatedTimeToRestaurant,
    required this.estimatedDistanceToRestaurant,
    required this.estimatedTimeToCustomer,
    required this.estimatedDistanceToCustomer,
    required this.onRefreshRoute,
    required this.onCenterRider,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.route, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'เส้นทางการส่ง',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (routeStatus == RouteStatus.loading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefreshRoute,
                    tooltip: 'รีเฟรชเส้นทาง',
                  ),
              ],
            ),
            const Divider(),

            // Route info
            if (routeStatus == RouteStatus.loaded) ...[
              // To Restaurant
              _RouteSegment(
                icon: Icons.restaurant,
                iconColor: Colors.orange,
                title: 'ไปร้านอาหาร',
                time: estimatedTimeToRestaurant,
                distance: estimatedDistanceToRestaurant,
              ),
              const SizedBox(height: 12),
              
              // To Customer
              _RouteSegment(
                icon: Icons.person_pin_circle,
                iconColor: Colors.green,
                title: 'ไปส่งลูกค้า',
                time: estimatedTimeToCustomer,
                distance: estimatedDistanceToCustomer,
              ),
              const SizedBox(height: 16),

              // Total
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'รวม: ${_calculateTotalTime()} | ${_calculateTotalDistance()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (routeStatus == RouteStatus.loading) ...[
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('กำลังโหลดเส้นทาง...'),
              ),
            ] else if (routeStatus == RouteStatus.error) ...[
              const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 32),
                    SizedBox(height: 8),
                    Text(
                      'ไม่สามารถโหลดเส้นทางได้',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('รอข้อมูลตำแหน่ง...'),
              ),
            ],

            // Action buttons
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCenterRider,
                    icon: const Icon(Icons.my_location),
                    label: const Text('ตำแหน่งของฉัน'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _calculateTotalTime() {
    // Simple calculation - in production, parse and add properly
    if (estimatedTimeToRestaurant.isEmpty || estimatedTimeToCustomer.isEmpty) {
      return '-';
    }
    final time1 = _parseMinutes(estimatedTimeToRestaurant);
    final time2 = _parseMinutes(estimatedTimeToCustomer);
    return '${time1 + time2} นาที';
  }

  String _calculateTotalDistance() {
    // Simple calculation - in production, parse and add properly
    if (estimatedDistanceToRestaurant.isEmpty || estimatedDistanceToCustomer.isEmpty) {
      return '-';
    }
    return '~'; // Would need proper parsing
  }

  int _parseMinutes(String timeStr) {
    final match = RegExp(r'(\d+)').firstMatch(timeStr);
    return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
  }
}

class _RouteSegment extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String time;
  final String distance;

  const _RouteSegment({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.time,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                time.isNotEmpty ? time : '-',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Text(
          distance.isNotEmpty ? distance : '-',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
