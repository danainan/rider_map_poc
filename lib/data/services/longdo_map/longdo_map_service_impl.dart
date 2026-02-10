import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:rider_map_poc/core/constants/api_constants.dart';
import 'package:rider_map_poc/data/models/geo_json/longdo_map_geo_json.dart';
import 'package:rider_map_poc/data/services/longdo_map/longdo_map_service.dart';

@Injectable(as: LongdoMapService)
class LongdoMapServiceImpl implements LongdoMapService {
  @override
  Future<Either<void, dynamic>> calculateRouteMatrix({
    required List<double> flon,
    required List<double> flat,
    required List<double> tlon,
    required List<double> tlat,
  }) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://api.longdo.com/RouteService/json/route/matrix',
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Accept': 'application/json',
          }, 
        ),
        queryParameters: {
          'key': ApiConstants.longDoMapApiKey,
          'flon[]': flon,
          'flat[]': flat,
          'tlon[]': tlon,
          'tlat[]': tlat,
          'mode': 't',
          'type': 1,
          'restrict' : 0,
          'locale': 'th',
        },
      );

      return Right(response.data);
    } catch (e) {
      return const Right(null);
    }
  }

  @override
  Future<Either<String, LongDoMapGeoJson>> fetchRouteGeoJson({
    required double flat,
    required double flon,
    required double tlat,
    required double tlon,
    String mode = 't',
    int type = 1,
  }) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://api.longdo.com/RouteService/geojson/route',
        queryParameters: {
          'key': ApiConstants.longDoMapApiKey,
          'flon': flon,
          'flat': flat,
          'tlon': tlon,
          'tlat': tlat,
          // 'mode': mode,
          'type': type,
          // 'restrict' : 0,
          // 'locale': 'th',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final geoJson =
            LongDoMapGeoJson.fromJson(response.data as Map<String, dynamic>);
        return Right(geoJson);
      }

      return const Left('ไม่สามารถดึงข้อมูลเส้นทางได้');
    } catch (e) {
      return Left('Error: $e');
    }
  }
}