import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rider_map_poc/core/di/injectable.dart';
import 'package:rider_map_poc/modules/route_navigation/bloc/route_navigation_bloc.dart';
import 'package:rider_map_poc/modules/route_navigation/data/mock_location_data.dart';
import 'package:rider_map_poc/modules/route_navigation/widgets/route_info_card.dart';
import 'package:rider_map_poc/modules/route_navigation/widgets/route_map_widget.dart';

class RouteNavigationPage extends StatefulWidget {
  const RouteNavigationPage({super.key});

  @override
  State<RouteNavigationPage> createState() => _RouteNavigationPageState();
}

class _RouteNavigationPageState extends State<RouteNavigationPage>
    with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  final RouteNavigationBloc _bloc = getIt<RouteNavigationBloc>();
  bool _isMarkersReady = false;
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeMarkers();
    // Check location service first
    _bloc.add(const CheckLocationServiceEvent());
    // Request location permission
    _bloc.add(const RequestLocationPermissionEvent());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Re-check location service when app resumes
    if (state == AppLifecycleState.resumed) {
      _bloc.add(const CheckLocationServiceEvent());
    }
  }

  Future<void> _initializeMarkers() async {
    await RouteMarkerIcons.initialize();
    if (mounted) {
      setState(() => _isMarkersReady = true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController?.dispose();
    _bloc.close();
    super.dispose();
  }

  void _handleCameraAction(RouteNavigationState state) {
    if (_mapController == null) return;

    switch (state.cameraAction) {
      case CameraAction.centerOnRider:
        if (state.riderPosition != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(state.riderPosition!, 16),
          );
        }
        break;
      case CameraAction.fitAllMarkers:
        _fitAllMarkers(state);
        break;
      case CameraAction.followRider:
        if (state.riderPosition != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(state.riderPosition!),
          );
        }
        break;
      case CameraAction.none:
        break;
    }
  }

  void _fitAllMarkers(RouteNavigationState state) {
    final points = <LatLng>[
      state.restaurantLocation,
      state.customerLocation,
    ];

    if (state.riderPosition != null) {
      points.add(state.riderPosition!);
    }

    if (points.length < 2) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b),
        points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b),
      ),
      northeast: LatLng(
        points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b),
        points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b),
      ),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  void _showLocationServiceDialog(BuildContext context) {
    if (_isDialogShowing) return;
    _isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.location_off, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(child: Text('Location Service ปิดอยู่')),
            ],
          ),
          content: const Text(
            'กรุณาเปิด Location Service เพื่อใช้งานแอพพลิเคชัน\n\n'
            'คุณจะถูกนำไปยังหน้าตั้งค่าเพื่อเปิด Location',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _isDialogShowing = false;
              },
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                _isDialogShowing = false;
                await Geolocator.openLocationSettings();
                if (context.mounted) {
                  _bloc.add(const CheckLocationServiceEvent());
                  _bloc.add(const RequestLocationPermissionEvent());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('เปิดการตั้งค่า'),
            ),
          ],
        );
      },
    ).then((_) => _isDialogShowing = false);
  }

  void _showPermissionDeniedDialog(BuildContext context, {bool isPermanent = false}) {
    if (_isDialogShowing) return;
    _isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.location_disabled, color: Colors.red),
              SizedBox(width: 8),
              Expanded(child: Text('ต้องการสิทธิ์ Location')),
            ],
          ),
          content: Text(
            isPermanent
                ? 'คุณได้ปฏิเสธสิทธิ์การเข้าถึง Location อย่างถาวร\n\n'
                    'กรุณาไปที่ Settings > Apps > Rider Map POC > Permissions > Location เพื่อเปิดสิทธิ์'
                : 'แอพต้องการสิทธิ์การเข้าถึง Location เพื่อแสดงตำแหน่งของคุณและคำนวณเส้นทาง',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _isDialogShowing = false;
              },
              child: const Text('ยกเลิก'),
            ),
            if (isPermanent)
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  _isDialogShowing = false;
                  await Geolocator.openAppSettings();
                  if (context.mounted) {
                    _bloc.add(const RequestLocationPermissionEvent());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('เปิด Settings'),
              )
            else
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _isDialogShowing = false;
                  _bloc.add(const RequestLocationPermissionEvent());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('ขออนุญาตอีกครั้ง'),
              ),
          ],
        );
      },
    ).then((_) => _isDialogShowing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isMarkersReady) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Route Navigation'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Route Navigation'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          actions: [
            IconButton(
              icon: const Icon(Icons.fit_screen),
              onPressed: () => _bloc.add(const FitAllMarkersEvent()),
              tooltip: 'ดูทั้งหมด',
            ),
          ],
        ),
        body: BlocConsumer<RouteNavigationBloc, RouteNavigationState>(
          listenWhen: (previous, current) =>
              current.cameraAction != CameraAction.none ||
              current.locationServiceStatus != previous.locationServiceStatus ||
              current.locationPermissionStatus != previous.locationPermissionStatus,
          listener: (context, state) {
            // Handle camera actions
            if (state.cameraAction != CameraAction.none) {
              _handleCameraAction(state);
              _bloc.add(const ResetCameraActionEvent());
            }

            // Show dialog if location service is disabled
            if (state.locationServiceStatus == LocationServiceStatus.disabled) {
              _showLocationServiceDialog(context);
            }

            // Show dialog if permission is denied
            if (state.locationPermissionStatus == LocationPermissionStatus.denied) {
              _showPermissionDeniedDialog(context);
            } else if (state.locationPermissionStatus == LocationPermissionStatus.deniedForever) {
              _showPermissionDeniedDialog(context, isPermanent: true);
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                // Map Widget
                RouteMapWidget(
                  riderPosition: state.riderPosition,
                  restaurantLocation: state.restaurantLocation,
                  customerLocation: state.customerLocation,
                  riderToRestaurantRoute: state.riderToRestaurantRoute,
                  restaurantToCustomerRoute: state.restaurantToCustomerRoute,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _bloc.add(const MapControllerReadyEvent());
                  },
                ),

                // Route Info Card (Bottom)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: RouteInfoCard(
                    routeStatus: state.routeStatus,
                    estimatedTimeToRestaurant: state.estimatedTimeToRestaurant,
                    estimatedDistanceToRestaurant: state.estimatedDistanceToRestaurant,
                    estimatedTimeToCustomer: state.estimatedTimeToCustomer,
                    estimatedDistanceToCustomer: state.estimatedDistanceToCustomer,
                    onRefreshRoute: () => _bloc.add(const FetchRouteEvent()),
                    onCenterRider: () => _bloc.add(const CenterOnRiderEvent()),
                  ),
                ),

                // Status indicator (Top)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _buildStatusBadge(state),
                  ),
                ),

                // Loading overlay
                if (state.locationPermissionStatus == LocationPermissionStatus.requesting)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('กำลังขอสิทธิ์ Location...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusBadge(RouteNavigationState state) {
    final (text, color, icon) = switch (state.routeStatus) {
      RouteStatus.initial => ('รอข้อมูลตำแหน่ง', Colors.grey, Icons.hourglass_empty),
      RouteStatus.loading => ('กำลังโหลดเส้นทาง...', Colors.orange, Icons.sync),
      RouteStatus.loaded => ('เส้นทางพร้อมแล้ว', Colors.green, Icons.check_circle),
      RouteStatus.error => ('โหลดเส้นทางไม่สำเร็จ', Colors.red, Icons.error),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
