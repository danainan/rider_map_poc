import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Utility class for map calculations
class MapUtils {
  MapUtils._();

  /// Calculate distance between two points in meters
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth's radius in meters

    final double lat1Rad = point1.latitude * math.pi / 180;
    final double lat2Rad = point2.latitude * math.pi / 180;
    final double deltaLat = (point2.latitude - point1.latitude) * math.pi / 180;
    final double deltaLng =
        (point2.longitude - point1.longitude) * math.pi / 180;

    final double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Calculate bearing between two points in degrees
  static double calculateBearing(LatLng from, LatLng to) {
    final double fromLat = from.latitude * math.pi / 180;
    final double fromLng = from.longitude * math.pi / 180;
    final double toLat = to.latitude * math.pi / 180;
    final double toLng = to.longitude * math.pi / 180;

    final double dLng = toLng - fromLng;

    final double x = math.sin(dLng) * math.cos(toLat);
    final double y = math.cos(fromLat) * math.sin(toLat) -
        math.sin(fromLat) * math.cos(toLat) * math.cos(dLng);

    double bearing = math.atan2(x, y) * 180 / math.pi;
    bearing = (bearing + 360) % 360;

    return bearing;
  }

  /// Get bounds for a list of points
  static LatLngBounds boundsFromLatLngList(List<LatLng> points) {
    if (points.isEmpty) {
      throw ArgumentError('Points list cannot be empty');
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Format distance to human readable string
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Format duration to human readable string
  static String formatDuration(Duration duration) {
    if (duration.inMinutes < 1) {
      return '< 1 min';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes} min';
    } else {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      return '${hours}h ${minutes}m';
    }
  }

  /// Estimate travel time based on distance (assuming average speed)
  static Duration estimateTravelTime(double distanceMeters, {double avgSpeedKmh = 30}) {
    final hours = distanceMeters / 1000 / avgSpeedKmh;
    return Duration(minutes: (hours * 60).round());
  }
}
