import 'package:geolocator/geolocator.dart';

abstract class GeolocatorService {
  Future<Position> determinePosition();
  Stream<Position> getPositionStream();
}
