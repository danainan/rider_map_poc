import 'package:flutter/material.dart';
import 'package:rider_map_poc/modules/rider/cubit/rider_cubit.dart';

/// Widget สำหรับแสดง UI ขอ Location Permission
class LocationPermissionView extends StatelessWidget {
  const LocationPermissionView({
    super.key,
    required this.status,
    required this.onRequestPermission,
    required this.onOpenSettings,
  });

  final LocationPermissionStatus status;
  final VoidCallback onRequestPermission;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            _buildIcon(),
            const SizedBox(height: 24),

            // Title
            Text(
              _getTitle(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              _getDescription(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Button
            _buildButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final IconData iconData;
    final Color iconColor;

    switch (status) {
      case LocationPermissionStatus.initial:
      case LocationPermissionStatus.checking:
        return const CircularProgressIndicator();
      case LocationPermissionStatus.denied:
        iconData = Icons.location_off_outlined;
        iconColor = Colors.orange;
        break;
      case LocationPermissionStatus.deniedForever:
        iconData = Icons.location_disabled;
        iconColor = Colors.red;
        break;
      case LocationPermissionStatus.granted:
        iconData = Icons.location_on;
        iconColor = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        size: 64,
        color: iconColor,
      ),
    );
  }

  String _getTitle() {
    switch (status) {
      case LocationPermissionStatus.initial:
      case LocationPermissionStatus.checking:
        return 'กำลังตรวจสอบสิทธิ์...';
      case LocationPermissionStatus.denied:
        return 'ต้องการสิทธิ์เข้าถึงตำแหน่ง';
      case LocationPermissionStatus.deniedForever:
        return 'สิทธิ์ถูกปฏิเสธถาวร';
      case LocationPermissionStatus.granted:
        return 'สิทธิ์ได้รับอนุญาต';
    }
  }

  String _getDescription() {
    switch (status) {
      case LocationPermissionStatus.initial:
      case LocationPermissionStatus.checking:
        return 'กรุณารอสักครู่...';
      case LocationPermissionStatus.denied:
        return 'แอปต้องการสิทธิ์เข้าถึงตำแหน่งของคุณ\nเพื่อแสดงตำแหน่งบนแผนที่และนำทาง';
      case LocationPermissionStatus.deniedForever:
        return 'คุณได้ปฏิเสธสิทธิ์อย่างถาวร\nกรุณาไปที่ตั้งค่าเพื่อเปิดใช้งานสิทธิ์';
      case LocationPermissionStatus.granted:
        return 'พร้อมใช้งาน';
    }
  }

  Widget _buildButton(BuildContext context) {
    switch (status) {
      case LocationPermissionStatus.initial:
      case LocationPermissionStatus.checking:
        return const SizedBox.shrink();

      case LocationPermissionStatus.denied:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onRequestPermission,
            icon: const Icon(Icons.location_on),
            label: const Text('อนุญาตเข้าถึงตำแหน่ง'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        );

      case LocationPermissionStatus.deniedForever:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onOpenSettings,
            icon: const Icon(Icons.settings),
            label: const Text('ไปที่ตั้งค่า'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        );

      case LocationPermissionStatus.granted:
        return const Icon(Icons.check_circle, color: Colors.green, size: 48);
    }
  }
}
