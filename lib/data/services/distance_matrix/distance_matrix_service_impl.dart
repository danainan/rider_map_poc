import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:rider_map_poc/core/constants/api_constants.dart';
import 'package:rider_map_poc/data/models/distance_matrix/distance_matrix_response.dart';
import 'package:rider_map_poc/data/services/distance_matrix/distance_matrix_service.dart';

@Injectable(as: DistanceMatrixService)
class DistanceMatrixServiceImpl implements DistanceMatrixService {
  DistanceMatrixServiceImpl();

  @override
  Future<Either<DistanceMatrixResponse, DistanceMatrixResponse>> fetchDistanceMatrix({
    required String origins,
    required String destinations,
  }) async {
    try {
      final dio = Dio();
      const apiKey = ApiConstants.googleMapsApiKey;
      final response = await dio.post(
        'https://maps.googleapis.com/maps/api/distancematrix/json',
        queryParameters: {
          'origins': origins,
          'destinations': destinations,
          'mode' : 'motorcycle',
          'key': apiKey
        },
      );
      return Right(DistanceMatrixResponse.fromJson(response.data));
    } catch (e) {
      return const Left(DistanceMatrixResponse.empty);
    }
  }
}