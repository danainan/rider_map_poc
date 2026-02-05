import 'package:fpdart/fpdart.dart';

abstract class LongdoMapService {
  Future<Either<void, dynamic>> calculateRouteMatrix({
    required List<double> flon,
    required List<double> flat,
    required List<double> tlon,
    required List<double> tlat,
  });
}