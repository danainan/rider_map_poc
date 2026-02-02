import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rider_map_poc/core/di/injectable.dart';
import 'package:rider_map_poc/data/models/permission/permission_request_status.dart';
import 'package:rider_map_poc/modules/rider/cubit/rider_cubit.dart';
import 'package:rider_map_poc/modules/rider/widgets/location_permission_view.dart';
import 'package:rider_map_poc/modules/rider/widgets/location_service_dialog.dart';
import 'package:rider_map_poc/modules/rider/widgets/rider_bottom_sheet.dart';
import 'package:rider_map_poc/modules/rider/widgets/rider_map_view.dart';

class RiderScreen extends StatefulWidget {
  const RiderScreen({super.key});

  @override
  State<RiderScreen> createState() => _RiderScreenState();
}

class _RiderScreenState extends State<RiderScreen> with WidgetsBindingObserver {
  late final RiderCubit _cubit;
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit = getIt<RiderCubit>();
    _initialized();
  }

  Future<void> _initialized() async {
    await _cubit.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cubit.stopLocationTracking();
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        body: BlocConsumer<RiderCubit, RiderState>(
          listener: (context, state) {

            if (state.showLocationServiceDialog && !_isDialogShowing) {
              _isDialogShowing = true;
              _showLocationServiceDialog(context);
            }
          },
          builder: (context, state) {
            if (state.permissionStatus != PermissionRequestStatus.granted) {
              return LocationPermissionView(
                status: state.permissionStatus,
                onRequestPermission: () => _cubit.requestLocationPermission(),
                onOpenSettings: () => openAppSettings(),
              );
            }

            if (state.locationServiceStatus != LocationServiceStatus.enabled) {
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

            return Stack(
              children: [
                const RiderMapView(),
                _buildBackButton(context),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: RiderBottomSheet(),
                ),
                if (state.routeLoadingStatus == RouteLoadingStatus.loading)
                  _buildLoadingOverlay(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      child: CircleAvatar(
        backgroundColor: Colors.white,
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black26,
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('กำลังโหลดเส้นทาง...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLocationServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: _cubit,
          child: BlocListener<RiderCubit, RiderState>(
            listenWhen: (previous, current) =>
                previous.locationServiceStatus != current.locationServiceStatus,
            listener: (context, state) {
              if (state.locationServiceStatus == LocationServiceStatus.enabled) {
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
}