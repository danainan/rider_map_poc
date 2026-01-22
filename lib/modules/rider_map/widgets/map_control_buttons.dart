import 'package:flutter/material.dart';

class MapControlButtons extends StatelessWidget {
  final bool isFollowingRider;
  final VoidCallback onCenterRider;
  final VoidCallback onFitAll;
  final VoidCallback onToggleFollow;

  const MapControlButtons({
    super.key,
    required this.isFollowingRider,
    required this.onCenterRider,
    required this.onFitAll,
    required this.onToggleFollow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Center on Rider button
        _ControlButton(
          icon: Icons.my_location,
          tooltip: 'Center on Rider',
          onPressed: onCenterRider,
        ),
        const SizedBox(height: 8),
        // Fit all markers button
        _ControlButton(
          icon: Icons.zoom_out_map,
          tooltip: 'Fit All',
          onPressed: onFitAll,
        ),
        const SizedBox(height: 8),
        // Toggle follow rider button
        _ControlButton(
          icon: isFollowingRider ? Icons.gps_fixed : Icons.gps_not_fixed,
          tooltip: isFollowingRider ? 'Stop Following' : 'Follow Rider',
          onPressed: onToggleFollow,
          isActive: isFollowingRider,
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isActive;

  const _ControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive ? Colors.blue : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey.shade700,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
