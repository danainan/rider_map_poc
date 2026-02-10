// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:rider_map_poc/core/di/injectable.dart';
// import 'package:rider_map_poc/modules/longdo_map_navigation/cubit/longdo_map_navigation_cubit.dart';
// import 'package:rider_map_poc/modules/longdo_map_navigation/widgets/longdo_map_navigation_widget.dart';
// import 'package:webview_flutter/webview_flutter.dart';

// class LongdoMapNavigation extends StatefulWidget {
//   const LongdoMapNavigation({super.key});

//   @override
//   State<LongdoMapNavigation> createState() => _LongdoMapNavigationState();
// }

// class _LongdoMapNavigationState extends State<LongdoMapNavigation>
//     with WidgetsBindingObserver {
//   late final WebViewController _controller;
//   late final LongdoMapNavigationCubit _cubit;
//   bool _isCameraFollowing = true;
//   bool _isRouteDrawn = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _controller = WebViewController();
//     _cubit = getIt<LongdoMapNavigationCubit>();
//     _cubit.initialize();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
//     if (state == AppLifecycleState.resumed) {
//       _cubit.onAppResumed();
//     }
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _cubit.stopTracking();
//     _cubit.close();
//     super.dispose();
//   }

//   void _handleMapReady() async {
//     final state = _cubit.state;
//     await _controller.runJavaScript(
//       'addLocationMarkers(${state.shopLocation.latitude}, ${state.shopLocation.longitude}, ${state.customerLocation.latitude}, ${state.customerLocation.longitude});',
//     );
    
//     if (state.currentPosition != null) {
//       await _controller.runJavaScript(
//         'addRiderMarker(${state.currentPosition!.latitude}, ${state.currentPosition!.longitude});',
//       );
//     }
//   }

//   void _handleOffRoute() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('คุณออกนอกเส้นทาง กำลังคำนวณเส้นทางใหม่...'),
//         backgroundColor: Colors.orange,
//         duration: Duration(seconds: 3),
//       ),
//     );
//     _cubit.handleOffRoute();
//   }

//   void _handleCameraFollowChanged(bool isFollowing) {
//     setState(() {
//       _isCameraFollowing = isFollowing;
//     });
//   }

//   void _recenterToRider() {
//     _controller.runJavaScript('recenterToRider();');
//     setState(() {
//       _isCameraFollowing = true;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Rider Navigation'),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//       ),
//       body: BlocProvider.value(
//         value: _cubit,
//         child: BlocConsumer<LongdoMapNavigationCubit, LongdoMapNavigationState>(
//           listener: (context, state) async {
//             // Reset flag เมื่อเริ่ม loading route ใหม่ (กรณี off-route)
//             if (state.status == LongdoMapNavigationStatus.routeLoading) {
//               _isRouteDrawn = false;
//             }

//             // 1. วาดเส้นทาง (ครั้งเดียวต่อ route)
//             //    ต้องวาดก่อน updateRiderPosition เพื่อให้ snap ทำงานบน route ใหม่
//             if (state.status == LongdoMapNavigationStatus.routeReady &&
//                 state.jsonRoute != null && !_isRouteDrawn) {
//               _isRouteDrawn = true;
              
//               final geoJsonString = jsonEncode(state.jsonRoute!.toJson());
//               final escapedJson = geoJsonString
//                   .replaceAll('\\', '\\\\')
//                   .replaceAll("'", "\\'")
//                   .replaceAll('\n', '\\n')
//                   .replaceAll('\r', '\\r');

//               await _controller.runJavaScript(
//                 "drawRoute('$escapedJson');",
//               );
//             }
            
//             // 2. อัปเดตตำแหน่ง Rider (หลังวาด route แล้ว)
//             if (state.currentPosition != null &&
//                 state.status == LongdoMapNavigationStatus.routeReady) {
//               await _controller.runJavaScript(
//                 'updateRiderPosition(${state.currentPosition!.latitude}, ${state.currentPosition!.longitude});',
//               );
//             }
//           },
//           builder: (context, state) {
//             return Stack(
//               children: [
//                 LongdoMapNavigationWidget(
//                   controller: _controller,
//                   onMapReady: _handleMapReady,
//                   onOffRoute: _handleOffRoute,
//                   onCameraFollowChanged: _handleCameraFollowChanged,
//                   onDistanceUpdated: (distance) {
//                     _cubit.updateRemainingDistance(distance);
//                   },
//                 ),

//                 if (state.status == LongdoMapNavigationStatus.routeLoading)
//                   Container(
//                     color: Colors.black26,
//                     child: const Center(
//                       child: CircularProgressIndicator(),
//                     ),
//                   ),

//                 Positioned(
//                   top: 16,
//                   left: 16,
//                   right: 16,
//                   child: _buildStatusPanel(state),
//                 ),

//                 // ปุ่ม "กลับมาที่ตำแหน่งฉัน"
//                 if (!_isCameraFollowing && state.currentPosition != null)
//                   Positioned(
//                     bottom: 100,
//                     right: 16,
//                     child: FloatingActionButton(
//                       onPressed: _recenterToRider,
//                       backgroundColor: Colors.white,
//                       foregroundColor: Colors.blue,
//                       elevation: 4,
//                       child: const Icon(Icons.my_location, size: 28),
//                     ),
//                   ),

//                 if (state.status == LongdoMapNavigationStatus.positionError)
//                   const Positioned(
//                     bottom: 16,
//                     left: 16,
//                     right: 16,
//                     child: Card(
//                       color: Colors.red,
//                       child: Padding(
//                         padding: EdgeInsets.all(16.0),
//                         child: Text(
//                           'Unable to get your location',
//                           style: TextStyle(color: Colors.white),
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                     ),
//                   ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusPanel(LongdoMapNavigationState state) {
//     String statusText = '';
//     Color statusColor = Colors.blue;

//     switch (state.status) {
//       case LongdoMapNavigationStatus.initial:
//         statusText = 'Initializing...';
//         statusColor = Colors.grey;
//         break;
//       case LongdoMapNavigationStatus.locationDisabled:
//         statusText = 'Location Disabled';
//         statusColor = Colors.orange;
//         break;
//       case LongdoMapNavigationStatus.mapReady:
//         statusText = 'Map Ready';
//         statusColor = Colors.green;
//         break;
//       case LongdoMapNavigationStatus.routeLoading:
//         statusText = 'Loading Route...';
//         statusColor = Colors.blue;
//         break;
//       case LongdoMapNavigationStatus.routeReady:
//         statusText = 'Route Ready - Navigate!';
//         statusColor = Colors.green;
//         break;
//       case LongdoMapNavigationStatus.positionError:
//         statusText = 'Position Error';
//         statusColor = Colors.red;
//         break;
//     }

//     return Card(
//       color: statusColor,
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               statusText,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             if (state.currentPosition != null) ...[
//               const SizedBox(height: 8),
//               Text(
//                 'Lat: ${state.currentPosition!.latitude.toStringAsFixed(6)}, '
//                 'Lon: ${state.currentPosition!.longitude.toStringAsFixed(6)}',
//                 style: const TextStyle(
//                   color: Colors.white70,
//                   fontSize: 12,
//                 ),
//               ),
//               if (state.remainingDistance > 0) ...[
//                 const SizedBox(height: 4),
//                 Text(
//                   'Remaining: ${_formatDistance(state.remainingDistance)}',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ],
//           ],
//         ),
//       ),
//     );
//   }
  
//   String _formatDistance(double meters) {
//     if (meters >= 1000) {
//       return '${(meters / 1000).toStringAsFixed(1)} km';
//     }
//     return '${meters.toStringAsFixed(0)} m';
//   }
// }


// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:rider_map_poc/core/di/injectable.dart';
// import 'package:rider_map_poc/data/models/permission/permission_request_status.dart';
// import 'package:rider_map_poc/modules/longdo_map_navigation/cubit/longdo_map_navigation_cubit.dart';
// import 'package:rider_map_poc/modules/longdo_map_navigation/widgets/longdo_map_navigation_widget.dart';
// import 'package:rider_map_poc/modules/rider/widgets/location_permission_view.dart';
// import 'package:rider_map_poc/modules/rider/widgets/location_service_dialog.dart';
// import 'package:webview_flutter/webview_flutter.dart';

// class LongdoMapNavigation extends StatefulWidget {
//   const LongdoMapNavigation({super.key});

//   @override
//   State<LongdoMapNavigation> createState() => _LongdoMapNavigationState();
// }

// class _LongdoMapNavigationState extends State<LongdoMapNavigation>
//     with WidgetsBindingObserver {
//   late final WebViewController _controller;
//   late final LongdoMapNavigationCubit _cubit;
//   bool _isCameraFollowing = true;
//   bool _isRouteDrawn = false;
//   bool _isLocationDialogShowing = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _controller = WebViewController();
//     _cubit = getIt<LongdoMapNavigationCubit>();
//     _cubit.initialize();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
//     if (state == AppLifecycleState.resumed) {
//       // กลับมาจาก settings → เช็ค permission + location service ใหม่
//       _cubit.onAppResumed();
//     }
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _cubit.stopTracking();
//     _cubit.close();
//     super.dispose();
//   }

//   void _handleMapReady() async {
//     final state = _cubit.state;
//     await _controller.runJavaScript(
//       'addLocationMarkers(${state.shopLocation.latitude}, ${state.shopLocation.longitude}, ${state.customerLocation.latitude}, ${state.customerLocation.longitude});',
//     );

//     if (state.currentPosition != null) {
//       await _controller.runJavaScript(
//         'addRiderMarker(${state.currentPosition!.latitude}, ${state.currentPosition!.longitude});',
//       );
//     }
//   }

//   // void _handleOffRoute() {
//   //   ScaffoldMessenger.of(context).showSnackBar(
//   //     const SnackBar(
//   //       content: Text('คุณออกนอกเส้นทาง กำลังคำนวณเส้นทางใหม่...'),
//   //       backgroundColor: Colors.orange,
//   //       duration: Duration(seconds: 3),
//   //     ),
//   //   );
//   //   _cubit.handleOffRoute();
//   // }

//   void _handleCameraFollowChanged(bool isFollowing) {
//     setState(() {
//       _isCameraFollowing = isFollowing;
//     });
//   }

//   void _recenterToRider() {
//     _controller.runJavaScript('recenterToRider();');
//     setState(() {
//       _isCameraFollowing = true;
//     });
//   }

//   // แสดง Location Service Dialog
//   void _showLocationServiceDialog() {
//     if (_isLocationDialogShowing) return;
//     _isLocationDialogShowing = true;

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => const LocationServiceDialog(),
//     ).then((_) {
//       _isLocationDialogShowing = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Rider Navigation'),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//       ),
//       body: BlocProvider.value(
//         value: _cubit,
//         child: BlocConsumer<LongdoMapNavigationCubit, LongdoMapNavigationState>(
//           listener: (context, state) async {
//             // ========== แสดง Location Service Dialog ==========
//             if (state.showLocationServiceDialog &&
//                 state.permissionStatus == PermissionRequestStatus.granted) {
//               _showLocationServiceDialog();
//             }

//             // ========== Route + Position Updates ==========

//             // Reset flag เมื่อเริ่ม loading route ใหม่
//             if (state.status == LongdoMapNavigationStatus.routeLoading) {
//               _isRouteDrawn = false;
//             }

//             // 1. วาดเส้นทาง (ครั้งเดียวต่อ route)
//             if (state.status == LongdoMapNavigationStatus.routeReady &&
//                 state.jsonRoute != null &&
//                 !_isRouteDrawn) {
//               _isRouteDrawn = true;

//               final geoJsonString = jsonEncode(state.jsonRoute!.toJson());
//               final escapedJson = geoJsonString
//                   .replaceAll('\\', '\\\\')
//                   .replaceAll("'", "\\'")
//                   .replaceAll('\n', '\\n')
//                   .replaceAll('\r', '\\r');

//               await _controller.runJavaScript(
//                 "drawRoute('$escapedJson');",
//               );
//             }

//             // 2. อัปเดตตำแหน่ง Rider (หลังวาด route แล้ว)
//             if (state.currentPosition != null &&
//                 state.status == LongdoMapNavigationStatus.routeReady) {
//               await _controller.runJavaScript(
//                 'updateRiderPosition(${state.currentPosition!.latitude}, ${state.currentPosition!.longitude});',
//               );
//             }
//           },
//           builder: (context, state) {
//             // ========== Permission ยังไม่ granted ==========
//             if (state.permissionStatus != PermissionRequestStatus.granted) {
//               return LocationPermissionView(
//                 status: state.permissionStatus,
//                 onRequestPermission: () {
//                   _cubit.requestLocationPermission();
//                 },
//                 onOpenSettings: () {
//                   Geolocator.openAppSettings();
//                 },
//               );
//             }

//             // ========== Location Service ปิด ==========
//             if (state.locationServiceStatus ==
//                 LongDoMapNavigationLocationStatus.disabled) {
//               return Center(
//                 child: Padding(
//                   padding: const EdgeInsets.all(24),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(24),
//                         decoration: BoxDecoration(
//                           color: Colors.orange.withOpacity(0.1),
//                           shape: BoxShape.circle,
//                         ),
//                         child: const Icon(
//                           Icons.gps_off,
//                           size: 64,
//                           color: Colors.orange,
//                         ),
//                       ),
//                       const SizedBox(height: 24),
//                       const Text(
//                         'กรุณาเปิด GPS',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       Text(
//                         'แอปต้องการ GPS เพื่อแสดงตำแหน่งของคุณ\nและนำทางไปยังจุดหมาย',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(color: Colors.grey[600]),
//                       ),
//                       const SizedBox(height: 32),
//                       SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton.icon(
//                           onPressed: () {
//                             Geolocator.openLocationSettings();
//                           },
//                           icon: const Icon(Icons.gps_fixed),
//                           label: const Text('เปิด GPS'),
//                           style: ElevatedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                             backgroundColor: Colors.blue,
//                             foregroundColor: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             }

//             // ========== Map + Navigation ==========
//             return Stack(
//               children: [
//                 LongdoMapNavigationWidget(
//                   controller: _controller,
//                   onMapReady: _handleMapReady,
//                   // onOffRoute: _handleOffRoute,
//                   onCameraFollowChanged: _handleCameraFollowChanged,
//                   onDistanceUpdated: (distance) {
//                     _cubit.updateRemainingDistance(distance);
//                   },
//                 ),

//                 if (state.status == LongdoMapNavigationStatus.routeLoading)
//                   Container(
//                     color: Colors.black26,
//                     child: const Center(
//                       child: CircularProgressIndicator(),
//                     ),
//                   ),

//                 Positioned(
//                   top: 16,
//                   left: 16,
//                   right: 16,
//                   child: _buildStatusPanel(state),
//                 ),

//                 // ปุ่ม "กลับมาที่ตำแหน่งฉัน"
//                 if (!_isCameraFollowing && state.currentPosition != null)
//                   Positioned(
//                     bottom: 100,
//                     right: 16,
//                     child: FloatingActionButton(
//                       onPressed: _recenterToRider,
//                       backgroundColor: Colors.white,
//                       foregroundColor: Colors.blue,
//                       elevation: 4,
//                       child: const Icon(Icons.my_location, size: 28),
//                     ),
//                   ),

//                 if (state.status == LongdoMapNavigationStatus.positionError)
//                   const Positioned(
//                     bottom: 16,
//                     left: 16,
//                     right: 16,
//                     child: Card(
//                       color: Colors.red,
//                       child: Padding(
//                         padding: EdgeInsets.all(16.0),
//                         child: Text(
//                           'Unable to get your location',
//                           style: TextStyle(color: Colors.white),
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                     ),
//                   ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusPanel(LongdoMapNavigationState state) {
//     String statusText = '';
//     Color statusColor = Colors.blue;

//     switch (state.status) {
//       case LongdoMapNavigationStatus.initial:
//         statusText = 'Initializing...';
//         statusColor = Colors.grey;
//         break;
//       case LongdoMapNavigationStatus.locationDisabled:
//         statusText = 'Location Disabled';
//         statusColor = Colors.orange;
//         break;
//       case LongdoMapNavigationStatus.mapReady:
//         statusText = 'Map Ready';
//         statusColor = Colors.green;
//         break;
//       case LongdoMapNavigationStatus.routeLoading:
//         statusText = 'Loading Route...';
//         statusColor = Colors.blue;
//         break;
//       case LongdoMapNavigationStatus.routeReady:
//         statusText = 'Route Ready - Navigate!';
//         statusColor = Colors.green;
//         break;
//       case LongdoMapNavigationStatus.positionError:
//         statusText = 'Position Error';
//         statusColor = Colors.red;
//         break;
//     }

//     return Card(
//       color: statusColor,
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               statusText,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             if (state.currentPosition != null) ...[
//               const SizedBox(height: 8),
//               Text(
//                 'Lat: ${state.currentPosition!.latitude.toStringAsFixed(6)}, '
//                 'Lon: ${state.currentPosition!.longitude.toStringAsFixed(6)}',
//                 style: const TextStyle(
//                   color: Colors.white70,
//                   fontSize: 12,
//                 ),
//               ),
//               if (state.remainingDistance > 0) ...[
//                 const SizedBox(height: 4),
//                 Text(
//                   'Remaining: ${_formatDistance(state.remainingDistance)}',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   String _formatDistance(double meters) {
//     if (meters >= 1000) {
//       return '${(meters / 1000).toStringAsFixed(1)} km';
//     }
//     return '${meters.toStringAsFixed(0)} m';
//   }
// }


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rider_map_poc/core/di/injectable.dart';
import 'package:rider_map_poc/data/models/permission/permission_request_status.dart';
import 'package:rider_map_poc/modules/longdo_map_navigation/cubit/longdo_map_navigation_cubit.dart';
import 'package:rider_map_poc/modules/longdo_map_navigation/widgets/longdo_map_navigation_widget.dart';
import 'package:rider_map_poc/modules/rider/widgets/location_permission_view.dart';
import 'package:rider_map_poc/modules/rider/widgets/location_service_dialog.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LongdoMapNavigation extends StatefulWidget {
  const LongdoMapNavigation({super.key});

  @override
  State<LongdoMapNavigation> createState() => _LongdoMapNavigationState();
}

class _LongdoMapNavigationState extends State<LongdoMapNavigation>
    with WidgetsBindingObserver {
  late final WebViewController _controller;
  late final LongdoMapNavigationCubit _cubit;
  bool _isCameraFollowing = true;
  bool _isRouteDrawn = false;
  bool _isLocationDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = WebViewController();
    _cubit = getIt<LongdoMapNavigationCubit>();
    _cubit.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _cubit.onAppResumed();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cubit.stopTracking();
    _cubit.close();
    super.dispose();
  }

  void _handleMapReady() async {
    final state = _cubit.state;
    await _controller.runJavaScript(
      'addLocationMarkers(${state.shopLocation.latitude}, ${state.shopLocation.longitude}, ${state.customerLocation.latitude}, ${state.customerLocation.longitude});',
    );

    if (state.currentPosition != null) {
      await _controller.runJavaScript(
        'addRiderMarker(${state.currentPosition!.latitude}, ${state.currentPosition!.longitude});',
      );
    }
  }

  void _drawRouteOnMap(String geoJsonString) {
    final escapedJson = geoJsonString
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');
    _controller.runJavaScript("drawRoute('$escapedJson');");
  }

  void _updateRiderPosition(double lat, double lon) {
    _controller.runJavaScript('updateRiderPosition($lat, $lon);');
  }

  void _handleCameraFollowChanged(bool isFollowing) {
    setState(() {
      _isCameraFollowing = isFollowing;
    });
  }

  void _recenterToRider() {
    _controller.runJavaScript('recenterToRider();');
    setState(() {
      _isCameraFollowing = true;
    });
  }

  void _showLocationServiceDialog() {
    if (_isLocationDialogShowing) return;
    _isLocationDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LocationServiceDialog(),
    ).then((_) {
      _isLocationDialogShowing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Navigation'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: BlocProvider.value(
        value: _cubit,
        child: BlocConsumer<LongdoMapNavigationCubit, LongdoMapNavigationState>(
          listener: (context, state) {
            // ========== แสดง Location Service Dialog ==========
            if (state.showLocationServiceDialog &&
                state.permissionStatus == PermissionRequestStatus.granted) {
              _showLocationServiceDialog();
            }

            // ========== Route + Position Updates (ไม่ใช้ await เพื่อไม่บล็อก UI) ==========

            if (state.status == LongdoMapNavigationStatus.routeLoading) {
              _isRouteDrawn = false;
            }

            // 1. วาดเส้นทาง (ครั้งเดียวต่อ route)
            if (state.status == LongdoMapNavigationStatus.routeReady &&
                state.jsonRoute != null &&
                !_isRouteDrawn) {
              _isRouteDrawn = true;
              _drawRouteOnMap(jsonEncode(state.jsonRoute!.toJson()));
            }

            // 2. อัปเดตตำแหน่ง Rider (ไม่ await เพื่อไม่บล็อก)
            if (state.currentPosition != null &&
                state.status == LongdoMapNavigationStatus.routeReady) {
              _updateRiderPosition(
                state.currentPosition!.latitude,
                state.currentPosition!.longitude,
              );
            }
          },
          builder: (context, state) {
            // ========== Permission ยังไม่ granted ==========
            if (state.permissionStatus != PermissionRequestStatus.granted) {
              return LocationPermissionView(
                status: state.permissionStatus,
                onRequestPermission: () {
                  _cubit.requestLocationPermission();
                },
                onOpenSettings: () {
                  Geolocator.openAppSettings();
                },
              );
            }

            // ========== Location Service ปิด ==========
            if (state.locationServiceStatus ==
                LongDoMapNavigationLocationStatus.disabled) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.gps_off,
                          size: 64,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'กรุณาเปิด GPS',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'แอปต้องการ GPS เพื่อแสดงตำแหน่งของคุณ\nและนำทางไปยังจุดหมาย',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Geolocator.openLocationSettings();
                          },
                          icon: const Icon(Icons.gps_fixed),
                          label: const Text('เปิด GPS'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // ========== Map + Navigation ==========
            return Stack(
              children: [
                LongdoMapNavigationWidget(
                  controller: _controller,
                  onMapReady: _handleMapReady,
                  onCameraFollowChanged: _handleCameraFollowChanged,
                  onDistanceUpdated: (distance) {
                    _cubit.updateRemainingDistance(distance);
                  },
                ),

                if (state.status == LongdoMapNavigationStatus.routeLoading)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),

                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: _buildStatusPanel(state),
                ),

                if (!_isCameraFollowing && state.currentPosition != null)
                  Positioned(
                    bottom: 100,
                    right: 16,
                    child: FloatingActionButton(
                      onPressed: _recenterToRider,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                      elevation: 4,
                      child: const Icon(Icons.my_location, size: 28),
                    ),
                  ),

                if (state.status == LongdoMapNavigationStatus.positionError)
                  const Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      color: Colors.red,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Unable to get your location',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
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

  Widget _buildStatusPanel(LongdoMapNavigationState state) {
    String statusText = '';
    Color statusColor = Colors.blue;

    switch (state.status) {
      case LongdoMapNavigationStatus.initial:
        statusText = 'Initializing...';
        statusColor = Colors.grey;
        break;
      case LongdoMapNavigationStatus.locationDisabled:
        statusText = 'Location Disabled';
        statusColor = Colors.orange;
        break;
      case LongdoMapNavigationStatus.mapReady:
        statusText = 'Map Ready';
        statusColor = Colors.green;
        break;
      case LongdoMapNavigationStatus.routeLoading:
        statusText = 'Loading Route...';
        statusColor = Colors.blue;
        break;
      case LongdoMapNavigationStatus.routeReady:
        statusText = 'Route Ready - Navigate!';
        statusColor = Colors.green;
        break;
      case LongdoMapNavigationStatus.positionError:
        statusText = 'Position Error';
        statusColor = Colors.red;
        break;
    }

    return Card(
      color: statusColor,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              statusText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (state.currentPosition != null) ...[
              const SizedBox(height: 8),
              Text(
                'Lat: ${state.currentPosition!.latitude.toStringAsFixed(6)}, '
                'Lon: ${state.currentPosition!.longitude.toStringAsFixed(6)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              if (state.remainingDistance > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Remaining: ${_formatDistance(state.remainingDistance)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }
}