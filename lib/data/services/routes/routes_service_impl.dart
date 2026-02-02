import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:rider_map_poc/core/constants/api_constants.dart';
import 'package:rider_map_poc/data/services/routes/routes_service.dart';

@Injectable(as: RoutesService)
class RoutesServiceImpl implements RoutesService {
  RoutesServiceImpl();

  @override
  Future<RouteResponse> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    const apiKey = ApiConstants.googleMapsApiKey;

    if (apiKey.isEmpty) {
      throw Exception('Google Maps API Key is not configured');
    }

    final url = Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes');

    final requestBody = {
      'origin': {
        'location': {
          'latLng': {
            'latitude': origin.latitude,
            'longitude': origin.longitude,
          }
        }
      },
      'destination': {
        'location': {
          'latLng': {
            'latitude': destination.latitude,
            'longitude': destination.longitude,
          }
        }
      },
      'travelMode': 'DRIVE',
      'routingPreference': 'TRAFFIC_AWARE',
      'computeAlternativeRoutes': false,
      'languageCode': 'th',
      'units': 'METRIC',
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey,
          'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['routes'] == null || (data['routes'] as List).isEmpty) {
          throw Exception('No routes found');
        }

        final route = data['routes'][0];
        final encodedPolyline = route['polyline']['encodedPolyline'] as String;
        final distanceMeters = route['distanceMeters'] as int;
        final duration = route['duration'] as String; // e.g., "300s"

        // Decode polyline
        final polylinePoints = _decodePolyline(encodedPolyline);

        return RouteResponse(
          polylinePoints: polylinePoints,
          distance: _formatDistance(distanceMeters),
          duration: _formatDuration(duration),
        );
      } else {
        debugPrint('Routes API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch route: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Routes API Exception: $e');
      rethrow;
    }
  }

  /// Decode Google encoded polyline
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;

      // Decode latitude
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      // Decode longitude
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  /// Format distance in meters to human readable
  String _formatDistance(int meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)} กม.';
    } else {
      return '$meters ม.';
    }
  }

  /// Format duration string (e.g., "300s") to human readable
  String _formatDuration(String duration) {
    // Remove 's' suffix and parse
    final seconds = int.tryParse(duration.replaceAll('s', '')) ?? 0;

    if (seconds >= 3600) {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '$hours ชม. $minutes นาที';
    } else if (seconds >= 60) {
      final minutes = seconds ~/ 60;
      return '$minutes นาที';
    } else {
      return '$seconds วินาที';
    }
  }
}