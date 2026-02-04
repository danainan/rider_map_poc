import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rider_map_poc/core/di/injectable.dart';
import 'package:rider_map_poc/modules/distance_matrix/cubit/distance_metrix_cubit.dart';
import 'package:rider_map_poc/modules/distance_matrix/widgets/location_tile.dart';

class DistanceMatrixScreen extends StatefulWidget {
  const DistanceMatrixScreen({super.key});

  @override
  State<DistanceMatrixScreen> createState() => _DistanceMatrixScreenState();
}

class _DistanceMatrixScreenState extends State<DistanceMatrixScreen> {
  late final DistanceMetrixCubit _distanceMatrixCubit;

  @override
  void initState() {
    super.initState();
    _distanceMatrixCubit = getIt<DistanceMetrixCubit>();
  }

  @override
  void dispose() {
    _distanceMatrixCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Distance Matrix Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _distanceMatrixCubit.reset(),
          ),
        ],
      ),
      body: BlocProvider.value(
        value: _distanceMatrixCubit,
        child: BlocBuilder<DistanceMetrixCubit, DistanceMetrixState>(
          builder: (context, state) {
            return Column(
              children: [
                // แสดงผลรวมระยะทางและเวลา
                _buildSummaryCard(state),
                
                // รายการตำแหน่ง
                Expanded(
                  child: state.locations.isEmpty
                      ? _buildEmptyState()
                      : _buildLocationList(state),
                ),
                
                // ปุ่มเพิ่มตำแหน่งและคำนวณ
                _buildBottomActions(state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(DistanceMetrixState state) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'ผลรวมระยะทางและเวลา',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                icon: Icons.straighten,
                label: 'ระยะทาง',
                value: state.formattedDistance,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildSummaryItem(
                icon: Icons.access_time,
                label: 'เวลา',
                value: state.formattedDuration,
              ),
            ],
          ),
          if (state.status == DistanceMetrixStatus.loading)
            const Padding(
              padding: EdgeInsets.only(top: 12.0),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          if (state.status == DistanceMetrixStatus.failure && state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                state.errorMessage!,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8.0),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14.0,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16.0),
          Text(
            'ยังไม่มีตำแหน่ง',
            style: TextStyle(
              fontSize: 18.0,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'กดปุ่ม "เพิ่มตำแหน่ง" เพื่อเริ่มต้น',
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationList(DistanceMetrixState state) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: state.locations.length,
      itemBuilder: (context, index) {
        final location = state.locations[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: LocationTile(
            index: index + 1,
            lat: location.latitude.toString(),
            lon: location.longitude.toString(),
            onChangedLat: (value) => _distanceMatrixCubit.updateLocationLatitude(index, value),
            onChangedLon: (value) => _distanceMatrixCubit.updateLocationLongitude(index, value),
            onRemove: () => _distanceMatrixCubit.removeLocation(index),
          ),
        );
      },
    );
  }

  Widget _buildBottomActions(DistanceMetrixState state) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _distanceMatrixCubit.addLocation(),
                icon: const Icon(Icons.add_location),
                label: const Text('เพิ่มตำแหน่ง'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  side: BorderSide(color: Colors.blue.shade700, width: 2),
                  foregroundColor: Colors.blue.shade700,
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: state.canCalculate && state.status != DistanceMetrixStatus.loading
                    ? () => _distanceMatrixCubit.calculateDistanceMatrix()
                    : null,
                icon: const Icon(Icons.calculate),
                label: const Text('คำนวณ'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}