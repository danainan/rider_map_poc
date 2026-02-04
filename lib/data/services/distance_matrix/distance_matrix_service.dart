import 'package:fpdart/fpdart.dart';
import 'package:rider_map_poc/data/models/distance_matrix/distance_matrix_response.dart';

abstract class DistanceMatrixService {
  Future<Either<DistanceMatrixResponse, DistanceMatrixResponse>> fetchDistanceMatrix({
    required String origins,
    required String destinations,
  });
}