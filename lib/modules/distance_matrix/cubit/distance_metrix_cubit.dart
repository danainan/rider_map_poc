import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:rider_map_poc/data/models/distance_matrix/distance_matrix_response.dart';
import 'package:rider_map_poc/data/services/distance_matrix/distance_matrix_service.dart';
import 'package:rider_map_poc/modules/distance_matrix/data/models/location_point.dart';

part 'distance_metrix_state.dart';

@injectable
class DistanceMetrixCubit extends Cubit<DistanceMetrixState> {
  DistanceMetrixCubit(
    this._distanceMatrixService,
  ) : super(const DistanceMetrixState());

  final DistanceMatrixService _distanceMatrixService;

  /// เพิ่มจุดตำแหน่งใหม่
  void addLocation() {
    final updatedLocations = List<LocationPoint>.from(state.locations)
      ..add(const LocationPoint(latitude: 0, longitude: 0));
    
    emit(state.copyWith(locations: updatedLocations));
  }

  /// ลบจุดตำแหน่ง
  void removeLocation(int index) {
    if (index >= 0 && index < state.locations.length) {
      final updatedLocations = List<LocationPoint>.from(state.locations)
        ..removeAt(index);
      
      emit(state.copyWith(
        locations: updatedLocations,
        totalDistance: 0,
        totalDuration: 0,
      ));
    }
  }

  /// อัพเดทพิกัด latitude
  void updateLocationLatitude(int index, String latitude) {
    if (index >= 0 && index < state.locations.length) {
      final lat = double.tryParse(latitude) ?? 0;
      final updatedLocations = List<LocationPoint>.from(state.locations);
      updatedLocations[index] = updatedLocations[index].copyWith(latitude: lat);
      
      emit(state.copyWith(locations: updatedLocations));
    }
  }

  /// อัพเดทพิกัด longitude
  void updateLocationLongitude(int index, String longitude) {
    if (index >= 0 && index < state.locations.length) {
      final lng = double.tryParse(longitude) ?? 0;
      final updatedLocations = List<LocationPoint>.from(state.locations);
      updatedLocations[index] = updatedLocations[index].copyWith(longitude: lng);
      
      emit(state.copyWith(locations: updatedLocations));
    }
  }

  /// คำนวณระยะทางและเวลารวม A -> B -> C
  Future<void> calculateDistanceMatrix() async {
    if (!state.canCalculate) {
      emit(state.copyWith(
        status: DistanceMetrixStatus.failure,
        errorMessage: 'กรุณาใส่พิกัดอย่างน้อย 2 จุด',
      ));
      return;
    }

    emit(state.copyWith(status: DistanceMetrixStatus.loading));

    try {
      double totalDist = 0;
      int totalTime = 0;

      // คำนวณระยะทางแบบ A->B, B->C, C->D
      for (int i = 0; i < state.locations.length - 1; i++) {
        final origin = state.locations[i].latLngString;
        final destination = state.locations[i + 1].latLngString;

        final result = await _distanceMatrixService.fetchDistanceMatrix(
          origins: origin,
          destinations: destination,
        );

        await result.fold(
          (failure) {
            throw Exception('Failed to fetch distance matrix');
          },
          (data) async {
            if (data.rows != null && 
                data.rows!.isNotEmpty && 
                data.rows!.first.elements != null &&
                data.rows!.first.elements!.isNotEmpty) {
              
              final element = data.rows!.first.elements!.first;
              
              if (element.status == 'OK') {
                totalDist += (element.distance?.value ?? 0).toDouble();
                totalTime += (element.duration?.value ?? 0);
              }
            }
          },
        );
      }

      emit(state.copyWith(
        status: DistanceMetrixStatus.success,
        totalDistance: totalDist,
        totalDuration: totalTime,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DistanceMetrixStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  /// รีเซ็ตข้อมูลทั้งหมด
  void reset() {
    emit(const DistanceMetrixState());
  }
}
