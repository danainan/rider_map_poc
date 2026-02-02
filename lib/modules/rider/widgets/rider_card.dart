import 'package:flutter/material.dart';
import 'package:rider_map_poc/modules/rider/cubit/rider_cubit.dart';
import 'package:rider_map_poc/modules/rider/data/rider_mock_data.dart';

/// Card แสดงข้อมูล Rider สำหรับใช้ในหน้า list หรือ overview
class RiderCard extends StatelessWidget {
  const RiderCard({
    super.key,
    required this.status,
    this.onTap,
  });

  final RiderDeliveryStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  _buildStatusIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStatusText(),
                          style: TextStyle(
                            color: _getStatusColor(),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Locations
              _buildLocationRow(
                Icons.store,
                Colors.orange,
                RiderMockData.shopName,
                RiderMockData.shopAddress,
              ),
              const SizedBox(height: 12),
              _buildLocationRow(
                Icons.person_pin_circle,
                Colors.green,
                RiderMockData.customerName,
                RiderMockData.customerAddress,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    final color = _getStatusColor();
    final icon = switch (status) {
      RiderDeliveryStatus.idle => Icons.pending,
      RiderDeliveryStatus.headingToShop => Icons.directions_bike,
      RiderDeliveryStatus.arrivedAtShop => Icons.store,
      RiderDeliveryStatus.headingToCustomer => Icons.delivery_dining,
      RiderDeliveryStatus.delivered => Icons.check_circle,
    };

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _getStatusText() {
    return switch (status) {
      RiderDeliveryStatus.idle => 'รอรับงาน',
      RiderDeliveryStatus.headingToShop => 'กำลังไปรับอาหาร',
      RiderDeliveryStatus.arrivedAtShop => 'ถึงร้านแล้ว',
      RiderDeliveryStatus.headingToCustomer => 'กำลังส่งอาหาร',
      RiderDeliveryStatus.delivered => 'ส่งสำเร็จแล้ว',
    };
  }

  Color _getStatusColor() {
    return switch (status) {
      RiderDeliveryStatus.idle => Colors.grey,
      RiderDeliveryStatus.headingToShop => Colors.orange,
      RiderDeliveryStatus.arrivedAtShop => Colors.blue,
      RiderDeliveryStatus.headingToCustomer => Colors.green,
      RiderDeliveryStatus.delivered => Colors.green,
    };
  }

  Widget _buildLocationRow(
    IconData icon,
    Color color,
    String title,
    String subtitle,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
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
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
