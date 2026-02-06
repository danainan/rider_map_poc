import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rider_map_poc/core/di/injectable.dart';
import 'package:rider_map_poc/data/models/permission/permission_request_status.dart';
import 'package:rider_map_poc/data/services/geolocator/geolocator_service.dart';
import 'package:rider_map_poc/data/services/permission_status/app_permission_status_service.dart';
import 'package:rider_map_poc/modules/longdo_map/cubit/longdo_map_cubit.dart';
import 'package:rider_map_poc/modules/longdo_map/widgets/map_widget.dart';
import 'package:rider_map_poc/modules/rider/widgets/location_permission_view.dart';
import 'package:rider_map_poc/modules/rider/widgets/location_service_dialog.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LongDoMapPage extends StatefulWidget {
  const LongDoMapPage({super.key});

  @override
  State<LongDoMapPage> createState() => _LongDoMapPageState();
}

class _LongDoMapPageState extends State<LongDoMapPage>
    with WidgetsBindingObserver {
  late final LongdoMapCubit _cubit;
  late final WebViewController _controller;
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = WebViewController();
    _cubit = LongdoMapCubit(
      getIt<GeolocatorService>(),
      getIt<AppPermissionStatusService>(),
    );
    _cubit.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cubit.stopTracking();
    _cubit.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _cubit.onAppResumed();
    }
  }

  void _moveRiderOnMap(double lat, double lon) {
    _controller.runJavaScript('moveRider($lat, $lon);');
  }

  void _fitBounds() {
    _controller.runJavaScript('fitBounds();');
  }

  void _showLocationServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: _cubit,
          child: BlocListener<LongdoMapCubit, LongdoMapState>(
            listenWhen: (prev, curr) =>
                prev.locationServiceStatus != curr.locationServiceStatus,
            listener: (context, state) {
              if (state.locationServiceStatus ==
                  LongdoLocationServiceStatus.enabled) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const LocationServiceDialog(),
          ),
        );
      },
    ).then((_) {
      _isDialogShowing = false;
      _cubit.dismissLocationServiceDialog();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        body: BlocConsumer<LongdoMapCubit, LongdoMapState>(
          listener: (context, state) {
            // ขยับ marker ตาม GPS
            if (state.currentLat != 0 && state.currentLon != 0) {
              _moveRiderOnMap(state.currentLat, state.currentLon);
            }

            // แสดง dialog เปิด GPS
            if (state.showLocationServiceDialog && !_isDialogShowing) {
              _isDialogShowing = true;
              _showLocationServiceDialog(context);
            }
          },
          builder: (context, state) {
            // ---- Permission not granted ----
            if (state.permissionStatus != PermissionRequestStatus.granted) {
              return LocationPermissionView(
                status: state.permissionStatus,
                onRequestPermission: () =>
                    _cubit.requestLocationPermission(),
                onOpenSettings: () => openAppSettings(),
              );
            }

            // ---- Location service disabled / checking ----
            if (state.locationServiceStatus !=
                LongdoLocationServiceStatus.enabled) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('กำลังตรวจสอบ GPS...'),
                  ],
                ),
              );
            }

            // ---- Map + Tracking UI ----
            return Stack(
              children: [
                MapWidget(
                  controller: _controller,
                  onMapReady: () {},
                ),

                // Back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon:
                          const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),

                // Fit bounds button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.fit_screen,
                          color: Colors.black87),
                      onPressed: _fitBounds,
                      tooltip: 'Fit all markers',
                    ),
                  ),
                ),

                // Status bar ด้านบน
                Positioned(
                  top: MediaQuery.of(context).padding.top + 56,
                  left: 0,
                  right: 0,
                  child: _StatusBar(state: state),
                ),

                // Control panel ด้านล่าง
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _ControlPanel(
                    state: state,
                    onStartTracking: () => _cubit.startTracking(),
                    onStopTracking: () => _cubit.stopTracking(),
                    onRefresh: () => _cubit.refreshLocation(),
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

// ---------- Status Bar ----------

class _StatusBar extends StatelessWidget {
  final LongdoMapState state;

  const _StatusBar({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.status == LongdoMapStatus.initial) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatusBadge(status: state.status),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _statusTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    state.errorMessage!,
                    style: const TextStyle(fontSize: 11, color: Colors.red),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (state.currentLat != 0)
            Text(
              '${state.currentLat.toStringAsFixed(4)},\n${state.currentLon.toStringAsFixed(4)}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.right,
            ),
        ],
      ),
    );
  }

  String get _statusTitle => switch (state.status) {
        LongdoMapStatus.initial => '',
        LongdoMapStatus.loading => 'กำลังดึงตำแหน่ง...',
        LongdoMapStatus.mapReady => 'พร้อมใช้งาน',
        LongdoMapStatus.tracking => '📡 กำลังติดตามตำแหน่ง GPS',
        LongdoMapStatus.locationError => '⚠️ เกิดข้อผิดพลาด',
      };
}

class _StatusBadge extends StatelessWidget {
  final LongdoMapStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      LongdoMapStatus.loading => (Colors.orange, Icons.hourglass_top),
      LongdoMapStatus.mapReady => (Colors.blue, Icons.location_on),
      LongdoMapStatus.tracking => (Colors.green, Icons.gps_fixed),
      LongdoMapStatus.locationError => (Colors.red, Icons.error_outline),
      _ => (Colors.grey, Icons.map),
    };

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

// ---------- Control Panel ----------

class _ControlPanel extends StatelessWidget {
  final LongdoMapState state;
  final VoidCallback onStartTracking;
  final VoidCallback onStopTracking;
  final VoidCallback onRefresh;

  const _ControlPanel({
    required this.state,
    required this.onStartTracking,
    required this.onStopTracking,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (state.status == LongdoMapStatus.initial ||
        state.status == LongdoMapStatus.loading) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Legend
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     _LegendItem(color: Colors.blue, label: 'Rider → ร้านค้า'),
          //     const SizedBox(width: 16),
          //     _LegendItem(color: Colors.green, label: 'ร้านค้า → ลูกค้า'),
          //   ],
          // ),
          const SizedBox(height: 12),

          // Tracking indicator
          if (state.isTracking)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'GPS Tracking กำลังทำงาน',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      state.isTracking ? onStopTracking : onStartTracking,
                  icon: Icon(
                    state.isTracking ? Icons.gps_off : Icons.gps_fixed,
                  ),
                  label: Text(
                      state.isTracking ? 'หยุด Tracking' : 'เริ่ม GPS Tracking'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        state.isTracking ? Colors.orange : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.my_location),
                label: const Text('ตำแหน่ง'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}