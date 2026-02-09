import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rider_map_poc/core/di/injectable.dart';
import 'package:rider_map_poc/data/models/permission/permission_request_status.dart';
import 'package:rider_map_poc/data/services/geolocator/geolocator_service.dart';
import 'package:rider_map_poc/data/services/permission_status/app_permission_status_service.dart';
import 'package:rider_map_poc/modules/longdo_map_route/cubit/longdo_map_route_cubit.dart';
import 'package:rider_map_poc/modules/longdo_map_route/widgets/map_route_widget.dart';
import 'package:rider_map_poc/modules/rider/widgets/location_permission_view.dart';
import 'package:rider_map_poc/modules/rider/widgets/location_service_dialog.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LongDoMapRoutePage extends StatefulWidget {
  const LongDoMapRoutePage({super.key});

  @override
  State<LongDoMapRoutePage> createState() => _LongDoMapRoutePageState();
}

class _LongDoMapRoutePageState extends State<LongDoMapRoutePage>
    with WidgetsBindingObserver {
  late final LongdoMapRouteCubit _cubit;
  late final WebViewController _controller;
  bool _isDialogShowing = false;
  bool _routeInitialized = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = WebViewController();
    _cubit = LongdoMapRouteCubit(
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

  void _initRouteOnMap(
    double startLat, double startLon,
    double shopLat, double shopLon,
    double customerLat, double customerLon,
  ) {
    _controller.runJavaScript(
      'initRoute($startLat, $startLon, $shopLat, $shopLon, $customerLat, $customerLon);',
    );
  }

  void _updateStartPointOnMap(double lat, double lon) {
    _controller.runJavaScript('updateStartPoint($lat, $lon);');
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
          child: BlocListener<LongdoMapRouteCubit, LongdoMapRouteState>(
            listenWhen: (prev, curr) =>
                prev.locationServiceStatus != curr.locationServiceStatus,
            listener: (context, state) {
              if (state.locationServiceStatus ==
                  LongdoRouteLocationServiceStatus.enabled) {
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
        body: BlocConsumer<LongdoMapRouteCubit, LongdoMapRouteState>(
          listener: (context, state) {
            // รอให้ map พร้อมก่อน
            if (!_mapReady) return;

            // เมื่อได้ตำแหน่งครั้งแรก + map พร้อม → init route
            if (state.currentLat != 0 &&
                state.currentLon != 0 &&
                !_routeInitialized) {
              _routeInitialized = true;
              _initRouteOnMap(
                state.currentLat,
                state.currentLon,
                state.shopLat,
                state.shopLon,
                state.customerLat,
                state.customerLon,
              );
            }

            // ขยับ rider marker ตาม GPS
            if (state.currentLat != 0 && state.currentLon != 0) {
              _moveRiderOnMap(state.currentLat, state.currentLon);

              // อัพเดท route start point เมื่อ rider ขยับเกิน threshold
              if (_routeInitialized &&
                  _cubit.shouldUpdateRoute(
                      state.currentLat, state.currentLon)) {
                _updateStartPointOnMap(state.currentLat, state.currentLon);
              }
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
                LongdoRouteLocationServiceStatus.enabled) {
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
                MapRouteWidget(
                  controller: _controller,
                  onMapReady: () {
                    _mapReady = true;
                    // map พร้อมแล้ว → ถ้ามีตำแหน่งอยู่แล้ว ให้ init route เลย
                    final s = _cubit.state;
                    if (s.currentLat != 0 &&
                        s.currentLon != 0 &&
                        !_routeInitialized) {
                      _routeInitialized = true;
                      _initRouteOnMap(
                        s.currentLat,
                        s.currentLon,
                        s.shopLat,
                        s.shopLon,
                        s.customerLat,
                        s.customerLon,
                      );
                      _moveRiderOnMap(s.currentLat, s.currentLon);
                    }
                  },
                  onRouteComplete: (distance, interval) {
                    _cubit.onRouteComplete(distance, interval);
                  },
                  onRouteSearching: () {
                    _cubit.onRouteSearching();
                  },
                  onOffRoute: () {
                    // rider ออกนอกเส้นทาง → ยิง route ใหม่ทันที (ไม่รอ threshold)
                    final s = _cubit.state;
                    if (s.currentLat != 0 &&
                        s.currentLon != 0 &&
                        !s.isRouteSearching) {
                      _updateStartPointOnMap(s.currentLat, s.currentLon);
                    }
                  },
                ),

                // Back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.black87),
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

                // Status bar
                Positioned(
                  top: MediaQuery.of(context).padding.top + 56,
                  left: 0,
                  right: 0,
                  child: _StatusBar(state: state),
                ),

                // Route loading indicator
                if (state.isRouteSearching)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(),
                  ),

                // Control panel
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _ControlPanel(
                    state: state,
                    onStartTracking: () => _cubit.startTracking(),
                    onStopTracking: () => _cubit.stopTracking(),
                    onRefresh: () => _cubit.refreshLocation(),
                    onForceReRoute: () {
                      if (state.currentLat != 0 && state.currentLon != 0) {
                        _updateStartPointOnMap(
                            state.currentLat, state.currentLon);
                      }
                    },
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
  final LongdoMapRouteState state;

  const _StatusBar({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.status == LongdoMapRouteStatus.initial) {
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
                if (state.routeDistance != null &&
                    state.routeInterval != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'ระยะทาง: ${state.routeDistance}  •  เวลา: ${state.routeInterval}',
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
        LongdoMapRouteStatus.initial => '',
        LongdoMapRouteStatus.loading => 'กำลังดึงตำแหน่ง...',
        LongdoMapRouteStatus.mapReady => 'พร้อมใช้งาน (Route API)',
        LongdoMapRouteStatus.tracking => '📡 Tracking + Route.search()',
        LongdoMapRouteStatus.locationError => '⚠️ เกิดข้อผิดพลาด',
      };
}

class _StatusBadge extends StatelessWidget {
  final LongdoMapRouteStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      LongdoMapRouteStatus.loading => (Colors.orange, Icons.hourglass_top),
      LongdoMapRouteStatus.mapReady => (Colors.blue, Icons.location_on),
      LongdoMapRouteStatus.tracking => (Colors.green, Icons.gps_fixed),
      LongdoMapRouteStatus.locationError => (Colors.red, Icons.error_outline),
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
  final LongdoMapRouteState state;
  final VoidCallback onStartTracking;
  final VoidCallback onStopTracking;
  final VoidCallback onRefresh;
  final VoidCallback onForceReRoute;

  const _ControlPanel({
    required this.state,
    required this.onStartTracking,
    required this.onStopTracking,
    required this.onRefresh,
    required this.onForceReRoute,
  });

  @override
  Widget build(BuildContext context) {
    if (state.status == LongdoMapRouteStatus.initial ||
        state.status == LongdoMapRouteStatus.loading) {
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
          // Route info legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(
                  color: Colors.blue, label: 'map.Route API'),
              const SizedBox(width: 8),
              Text(
                'removeAt(0) → insert(0) → search()',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 8),

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
                    'GPS Tracking + Auto re-route กำลังทำงาน',
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
                onPressed: onForceReRoute,
                icon: const Icon(Icons.route),
                label: const Text('Re-route'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 12),
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
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 12),
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
