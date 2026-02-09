import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:rider_map_poc/core/constants/api_constants.dart';
import 'package:rider_map_poc/data/models/longdo_route/longdo_route_geojson.dart';
import 'package:rider_map_poc/data/services/longdo_map/longdo_routing_service.dart';

@Injectable(as: LongdoRoutingService)
class LongdoRoutingServiceImpl implements LongdoRoutingService {
  final Dio _dio = Dio();

  @override
  Future<Either<String, LongdoRouteGeoJson>> calculateRoute({
    required double flat,
    required double flon,
    required double tlat,
    required double tlon,
    String mode = 't',
    int type = 25, // road + tollway + ferry
  }) async {
    try {
      final response = await _dio.get(
        'https://api.longdo.com/RouteService/geojson/route',
        queryParameters: {
          'key': ApiConstants.longDoMapApiKey,
          'flon': flon,
          'flat': flat,
          'tlon': tlon,
          'tlat': tlat,
          'mode': mode,
          'type': type,
          'locale': 'th',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final geoJson =
            LongdoRouteGeoJson.fromJson(response.data as Map<String, dynamic>);
        return Right(geoJson);
      }

      return const Left('ไม่สามารถคำนวณเส้นทางได้');
    } on DioException catch (e) {
      return Left('Network error: ${e.message}');
    } catch (e) {
      return Left('Error: $e');
    }
  }
}
