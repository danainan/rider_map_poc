import 'package:fpdart/fpdart.dart';
import 'package:rider_map_poc/data/models/geo_json/longdo_map_geo_json.dart';

abstract class LongdoMapService {
  Future<Either<void, dynamic>> calculateRouteMatrix({
    required List<double> flon,
    required List<double> flat,
    required List<double> tlon,
    required List<double> tlat,
  });

  Future<Either<String, LongDoMapGeoJson>> fetchRouteGeoJson({
    required double flat,
    required double flon,
    required double tlat,
    required double tlon,
    String mode,
    int type,
  });
}