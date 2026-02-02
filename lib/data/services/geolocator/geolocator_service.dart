import 'package:geolocator/geolocator.dart';

abstract class GeolocatorService {
  Future<bool> isLocationServiceEnabled();
  Future<Position> determinePosition();
  Stream<Position> getPositionStream();
}
