import 'package:longdo_maps_api3_flutter/longdo.dart';

class LongDoMarker {
  Object currentMarker = Longdo.LongdoObject(
    'Marker',
    args: [
      {

      }
    ]
  );

  Object get marker => currentMarker;

  Object createMarker(double latitude, double longitude) {
    return Longdo.LongdoObject(
      'Marker',
      args: [
        {
          'lat': latitude,
          'lon': longitude,
        }
      ]
    );
  }
}