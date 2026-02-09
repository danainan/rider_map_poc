import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rider_map_poc/core/di/injectable.dart';
import 'package:rider_map_poc/data/models/permission/permission_request_status.dart';
import 'package:rider_map_poc/data/services/geolocator/geolocator_service.dart';
import 'package:rider_map_poc/data/services/longdo_map/longdo_routing_service.dart';
import 'package:rider_map_poc/data/services/permission_status/app_permission_status_service.dart';
import 'package:rider_map_poc/modules/longdo_map_ws/cubit/longdo_map_ws_cubit.dart';
import 'package:rider_map_poc/modules/longdo_map_ws/widgets/map_ws_widget.dart';
import 'package:rider_map_poc/modules/rider/widgets/location_permission_view.dart';
import 'package:rider_map_poc/modules/rider/widgets/location_service_dialog.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LongDoMapWsPage extends StatefulWidget {
  const LongDoMapWsPage({super.key});

  @override
  State<LongDoMapWsPage> createState() => _LongDoMapWsPageState();
}

class _LongDoMapWsPageState extends State<LongDoMapWsPage>
    with WidgetsBindingObserver {
  late final LongdoMapWsCubit _cubit;
  late final WebViewController _controller;
  bool _isDialogShowing = false;
  bool _routeDrawn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = WebViewController();
    _cubit = LongdoMapWsCubit(
      getIt<GeolocatorService>(),
      getIt<AppPermissionStatusService>(),
      getIt<LongdoRoutingService>(),
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

  void _drawRouteOnMap(String routeJson) {
    // Escape single quotes ใน JSON
    final escaped = routeJson.replaceAll("'", "\\'");
    _controller.runJavaScript("drawRoute('$escaped');");
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
          child: BlocListener<LongdoMapWsCubit, LongdoMapWsState>(
            listenWhen: (prev, curr) =>
                prev.locationServiceStatus != curr.locationServiceStatus,
            listener: (context, state) {
              if (state.locationServiceStatus ==
                  LongdoWsLocationServiceStatus.enabled) {
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
        body: BlocConsumer<LongdoMapWsCubit, LongdoMapWsState>(
          listener: (context, state) {
            // วาด route ลงแผนที่ครั้งเดียวเมื่อได้ข้อมูลจาก API
            // หลังจากนั้น JS จะจัดการ snap + ตัดเส้นที่ผ่านแล้วเอง
            if (state.routeJsonForJs != null && !_routeDrawn) {
              _routeDrawn = true;
              _drawRouteOnMap(state.routeJsonForJs!);
            }

            // ขยับ marker ตาม GPS (+ snap + trim จะทำในฝั่ง JS)
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
                LongdoWsLocationServiceStatus.enabled) {
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
                MapWsWidget(
                  controller: _controller,
                  onMapReady: () {},
                  onOffRoute: () {
                    // rider ออกนอกเส้นทาง → ยิง route ใหม่
                    _routeDrawn = false;
                    _cubit.refreshRoute();
                  },
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

                // Route loading indicator
                if (state.isRouteLoading)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(),
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
                    onRefreshRoute: () => _cubit.refreshRoute(),
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
  final LongdoMapWsState state;

  const _StatusBar({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.status == LongdoMapWsStatus.initial) {
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
                // แสดงข้อมูลเส้นทาง
                if (state.combinedDistanceText != null &&
                    state.combinedIntervalText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'ระยะทาง: ${state.combinedDistanceText}  •  เวลา: ${state.combinedIntervalText}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
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
        LongdoMapWsStatus.initial => '',
        LongdoMapWsStatus.loading => 'กำลังดึงตำแหน่ง...',
        LongdoMapWsStatus.mapReady => 'พร้อมใช้งาน (WS Routing)',
        LongdoMapWsStatus.tracking => '📡 Tracking + Snap-to-Route',
        LongdoMapWsStatus.locationError => '⚠️ เกิดข้อผิดพลาด',
      };
}

class _StatusBadge extends StatelessWidget {
  final LongdoMapWsStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      LongdoMapWsStatus.loading => (Colors.orange, Icons.hourglass_top),
      LongdoMapWsStatus.mapReady => (Colors.blue, Icons.location_on),
      LongdoMapWsStatus.tracking => (Colors.green, Icons.gps_fixed),
      LongdoMapWsStatus.locationError => (Colors.red, Icons.error_outline),
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
  final LongdoMapWsState state;
  final VoidCallback onStartTracking;
  final VoidCallback onStopTracking;
  final VoidCallback onRefresh;
  final VoidCallback onRefreshRoute;

  const _ControlPanel({
    required this.state,
    required this.onStartTracking,
    required this.onStopTracking,
    required this.onRefresh,
    required this.onRefreshRoute,
  });

  @override
  Widget build(BuildContext context) {
    if (state.status == LongdoMapWsStatus.initial ||
        state.status == LongdoMapWsStatus.loading) {
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
          // Route info
          if (state.routeGeoJson != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: Colors.blue, label: 'เส้นทาง WS Routing'),
                const SizedBox(width: 8),
                Text(
                  '${state.combinedFeatureCount} sections',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

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
                    'GPS Tracking + Snap กำลังทำงาน',
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
                      state.isTracking ? 'หยุด Tracking' : 'เริ่ม GPS'),
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
                onPressed: onRefreshRoute,
                icon: const Icon(Icons.route),
                label: const Text('Route'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
