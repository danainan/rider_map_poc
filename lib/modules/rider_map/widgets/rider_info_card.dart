import 'package:flutter/material.dart';
import 'package:rider_map_poc/modules/rider_map/bloc/rider_map_bloc.dart';

class RiderInfoCard extends StatelessWidget {
  final RiderStatus riderStatus;
  final String estimatedTime;
  final String estimatedDistance;
  final bool isSimulationRunning;
  final VoidCallback onStartSimulation;
  final VoidCallback onStopSimulation;
  final VoidCallback onCenterRider;

  const RiderInfoCard({
    super.key,
    required this.riderStatus,
    required this.estimatedTime,
    required this.estimatedDistance,
    required this.isSimulationRunning,
    required this.onStartSimulation,
    required this.onStopSimulation,
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
            // Rider info row
            Row(
              children: [
                // Rider avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.two_wheeler,
                    color: Colors.blue.shade700,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                // Rider details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'John Rider',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '4.8',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.motorcycle,
                            color: Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'ABC-1234',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Call button
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Calling rider...')),
                    );
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.phone,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // ETA and distance row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoItem(
                  icon: Icons.access_time,
                  label: 'ETA',
                  value: estimatedTime,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade300,
                ),
                _InfoItem(
                  icon: Icons.route,
                  label: 'Distance',
                  value: estimatedDistance,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Center on Rider button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCenterRider,
                icon: const Icon(Icons.my_location),
                label: const Text('Center on Rider'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Simulation control button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: riderStatus == RiderStatus.delivered
                    ? null
                    : (isSimulationRunning ? onStopSimulation : onStartSimulation),
                icon: Icon(
                  riderStatus == RiderStatus.delivered
                      ? Icons.check_circle
                      : (isSimulationRunning ? Icons.pause : Icons.play_arrow),
                ),
                label: Text(
                  riderStatus == RiderStatus.delivered
                      ? 'Delivered!'
                      : (isSimulationRunning ? 'Pause Simulation' : 'Start Simulation'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: riderStatus == RiderStatus.delivered
                      ? Colors.green
                      : (isSimulationRunning ? Colors.orange : Colors.blue),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
